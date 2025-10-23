const admin = require('firebase-admin');
const crypto = require('crypto');

// Inicializar Firebase Admin con variables de entorno (si existe credencial)
let db = null;
try {
  if (!admin.apps.length) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '{}');
    if (serviceAccount.project_id) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });
    }
  }
  if (admin.apps.length) {
    db = admin.firestore();
  }
} catch (_) {
  db = null;
}

export default async function handler(req, res) {
  // CORS para permitir requests desde cualquier origen
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  // Manejar preflight OPTIONS
  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }

  // Solo permitir POST
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { signature, data } = req.body || {};
    
    // Validar que vengan los datos requeridos
    if (!signature || !data) {
      return res.status(400).json({ error: 'signature and data required' });
    }

    // Validar campos mínimos en data
    const { qrCode, deviceId, timestamp } = data;
    if (!qrCode || !deviceId || !timestamp) {
      return res.status(400).json({ 
        error: 'missing required fields (qrCode, deviceId, timestamp)' 
      });
    }

    // Verificar HMAC
    const secret = process.env.HMAC_SECRET || 'dev_secret';
    const message = `${qrCode}|${deviceId}|${timestamp}`;
    const expectedSignature = crypto.createHmac('sha256', secret)
      .update(message)
      .digest('hex');
    
    if (expectedSignature !== signature) {
      return res.status(401).json({ error: 'invalid signature' });
    }

    // Guardar en Firestore si está configurado; si no, responder OK sin persistir
    if (db) {
      const event = {
        ...data,
        verified: true,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      };
      const docRef = await db.collection('attendance_events').add(event);
      return res.status(200).json({ 
        ok: true, 
        id: docRef.id,
        message: 'Attendance recorded successfully'
      });
    } else {
      return res.status(200).json({
        ok: true,
        id: null,
        message: 'Attendance received (no DB configured)'
      });
    }

  } catch (error) {
    console.error('Error processing attendance:', error);
    return res.status(500).json({ 
      error: 'Internal server error',
      details: error.message 
    });
  }
}