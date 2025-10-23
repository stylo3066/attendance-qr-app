require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const crypto = require('crypto');
const admin = require('firebase-admin');
const fs = require('fs');

const app = express();
app.use(bodyParser.json());

// Inicializar Firebase Admin (espera variable GOOGLE_APPLICATION_CREDENTIALS o path en .env)
if (process.env.GOOGLE_APPLICATION_CREDENTIALS && fs.existsSync(process.env.GOOGLE_APPLICATION_CREDENTIALS)) {
  admin.initializeApp({
    credential: admin.credential.cert(require(process.env.GOOGLE_APPLICATION_CREDENTIALS))
  });
} else {
  console.error('Falta la variable GOOGLE_APPLICATION_CREDENTIALS o el archivo no existe.');
  process.exit(1);
}

const db = admin.firestore();

function verifyHmac(payload, signature, secret) {
  const hmac = crypto.createHmac('sha256', secret).update(payload).digest('hex');
  return hmac === signature;
}

app.post('/attendance', async (req, res) => {
  try {
    const secret = process.env.HMAC_SECRET || 'dev_secret';
    const { signature, data } = req.body; // data debe ser JSON
    if (!signature || !data) return res.status(400).json({ error: 'signature and data required' });

    const payload = JSON.stringify(data);
    if (!verifyHmac(payload, signature, secret)) {
      return res.status(401).json({ error: 'invalid signature' });
    }

    // Guardar en Firestore
    const event = {
      ...data,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      verified: true,
    };

    const docRef = await db.collection('attendance_events').add(event);
    return res.json({ ok: true, id: docRef.id });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: e.message });
  }
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log('Server listening on port', port));
