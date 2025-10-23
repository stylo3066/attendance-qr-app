const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

admin.initializeApp();
const db = admin.firestore();

exports.verifyAttendance = functions.https.onRequest(async (req, res) => {
  try {
    // CORS preflight
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
      return res.status(204).send('');
    }

    if (req.method !== 'POST') return res.status(405).send('Method not allowed');
    const { signature, data } = req.body || {};
    if (!signature || !data) return res.status(400).json({ error: 'signature and data required' });

    // Validar campos mínimos y construir mensaje determinístico
    const { qrCode, deviceId, timestamp } = data;
    if (!qrCode || !deviceId || !timestamp) {
      return res.status(400).json({ error: 'missing required fields (qrCode, deviceId, timestamp)' });
    }

    const secret = functions.config().hmac?.secret || 'dev_secret';
    const message = `${qrCode}|${deviceId}|${timestamp}`;
    const hmac = crypto.createHmac('sha256', secret).update(message).digest('hex');
    if (hmac !== signature) return res.status(401).json({ error: 'invalid signature' });

    // Guardar evento verificado en Firestore
    const event = { ...data, verified: true, timestamp: admin.firestore.FieldValue.serverTimestamp() };
    const docRef = await db.collection('attendance_events').add(event);
    return res.json({ ok: true, id: docRef.id });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: e.message });
  }
});
