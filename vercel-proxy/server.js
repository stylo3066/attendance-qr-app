const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const professors = require('./professors');
const QRCode = require('qrcode');

const app = express();
let PORT = Number(process.env.PORT) || 3000;
let ACTIVE_INFO = { port: PORT, ip: 'localhost' };

// Middleware
app.use(cors());
app.use(express.json());
// Servir librerías estáticas locales (evitar dependencia de CDN)
app.use('/vendor', express.static(path.join(__dirname, 'vendor')));

// Simulación de Firestore (archivo JSON local)
const DB_FILE = path.join(__dirname, 'local_db.json');

// Inicializar base de datos local si no existe
if (!fs.existsSync(DB_FILE)) {
  fs.writeFileSync(DB_FILE, JSON.stringify({ attendance_events: [] }, null, 2));
}

function readDB() {
  try {
    const data = fs.readFileSync(DB_FILE, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    return { attendance_events: [] };
  }
}

function writeDB(data) {
  fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2));
}

// Endpoint principal
app.post('/api/attendance', async (req, res) => {
  try {
    console.log('📥 Received request:', req.body);
    
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

    // Buscar información del profesor por QR Code
    const professor = professors.find(p => p.id === qrCode);
    if (!professor) {
      return res.status(404).json({ 
        error: 'Profesor no encontrado',
        qrCode: qrCode
      });
    }

    // Verificar HMAC
    const secret = process.env.HMAC_SECRET || 'dev_secret';
    const message = `${qrCode}|${deviceId}|${timestamp}`;
    const expectedSignature = crypto.createHmac('sha256', secret)
      .update(message)
      .digest('hex');
    
    console.log('🔐 HMAC verification:');
    console.log('  Message:', message);
    console.log('  Expected:', expectedSignature);
    console.log('  Received:', signature);
    
    if (expectedSignature !== signature) {
      return res.status(401).json({ error: 'invalid signature' });
    }

    // Guardar en "base de datos" local con información del profesor
    const db = readDB();
    const now = new Date();
    const event = {
      id: Date.now().toString(),
      ...data,
      // Información del profesor
      professorId: professor.id,
      professorName: professor.nombre,
      professorLastName: professor.apellido,
      professorFullName: `${professor.nombre} ${professor.apellido}`,
      subject: professor.materia,
      email: professor.email,
      // Timestamps detallados
      verified: true,
      serverTimestamp: now.toISOString(),
      date: now.toISOString().split('T')[0], // YYYY-MM-DD
      time: now.toTimeString().split(' ')[0], // HH:MM:SS
      hour: now.getHours(),
      minute: now.getMinutes(),
      dayOfWeek: now.toLocaleDateString('es-ES', { weekday: 'long' }),
      readableDateTime: now.toLocaleString('es-ES')
    };
    
    db.attendance_events.push(event);
    writeDB(db);
    
    console.log('✅ Event saved:', {
      professor: `${professor.nombre} ${professor.apellido}`,
      subject: professor.materia,
      time: event.readableDateTime
    });
    
    return res.status(200).json({ 
      ok: true, 
      id: event.id,
      professor: `${professor.nombre} ${professor.apellido}`,
      subject: professor.materia,
      time: event.readableDateTime,
      message: `Asistencia registrada: ${professor.nombre} ${professor.apellido} - ${professor.materia}`
    });

  } catch (error) {
    console.error('❌ Error processing attendance:', error);
    return res.status(500).json({ 
      error: 'Internal server error',
      details: error.message 
    });
  }
});

// Endpoint para ver todos los registros (útil para debugging)
app.get('/api/attendance', (req, res) => {
  const db = readDB();
  res.json(db.attendance_events);
});

// Endpoint para limpiar la base de datos local
app.delete('/api/attendance', (req, res) => {
  writeDB({ attendance_events: [] });
  res.json({ message: 'Database cleared' });
});

// Servir solo el dashboard
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'dashboard.html'));
});

app.get('/dashboard', (req, res) => {
  res.sendFile(path.join(__dirname, 'dashboard.html'));
});

// Página de QR de prueba
app.get('/test-qr', (req, res) => {
  res.sendFile(path.join(__dirname, 'test-qr.html'));
});

// Endpoint para obtener lista de profesores
app.get('/api/professors', (req, res) => {
  res.json(professors);
});

// Endpoint para generar QR específico de un profesor
app.get('/api/professor/:id/qr', (req, res) => {
  const professor = professors.find(p => p.id === req.params.id);
  if (!professor) {
    return res.status(404).json({ error: 'Profesor no encontrado' });
  }
  
  res.json({
    qrCode: professor.id,
    professor: professor,
    qrText: professor.id, // Esto es lo que debe contener el QR
    instructions: `QR para: ${professor.nombre} ${professor.apellido} - ${professor.materia}`
  });
});

// Generar imagen PNG de QR desde el servidor para evitar dependencia de librerías en el navegador
app.get('/api/qr', async (req, res) => {
  try {
    const text = String(req.query.text || '').trim();
    if (!text) return res.status(400).json({ error: 'Parámetro "text" requerido' });
    const opts = { width: 260, margin: 2, errorCorrectionLevel: 'M' };
    const buffer = await QRCode.toBuffer(text, { type: 'png', ...opts });
    res.set('Content-Type', 'image/png');
    res.send(buffer);
  } catch (e) {
    console.error('❌ Error generando QR PNG:', e);
    res.status(500).json({ error: 'No se pudo generar el QR', details: e.message });
  }
});

// Endpoint de prueba: insertar un registro directamente (solo para entorno local)
app.get('/api/attendance/test-insert', (req, res) => {
  try {
    const qr = String(req.query.qr || 'PROF_001');
    const professor = professors.find(p => p.id === qr);
    if (!professor) {
      return res.status(404).json({ error: 'Profesor no encontrado', qr });
    }
    const db = readDB();
    const now = new Date();
    const event = {
      id: Date.now().toString(),
      qrCode: qr,
      deviceId: 'test-endpoint',
      timestamp: now.toISOString(),
      // Información del profesor
      professorId: professor.id,
      professorName: professor.nombre,
      professorLastName: professor.apellido,
      professorFullName: `${professor.nombre} ${professor.apellido}`,
      subject: professor.materia,
      email: professor.email,
      // Timestamps detallados
      verified: true,
      serverTimestamp: now.toISOString(),
      date: now.toISOString().split('T')[0],
      time: now.toTimeString().split(' ')[0],
      hour: now.getHours(),
      minute: now.getMinutes(),
      dayOfWeek: now.toLocaleDateString('es-ES', { weekday: 'long' }),
      readableDateTime: now.toLocaleString('es-ES')
    };
    db.attendance_events.push(event);
    writeDB(db);
    res.json({ ok: true, inserted: event });
  } catch (e) {
    res.status(500).json({ error: 'No se pudo insertar registro de prueba', details: e.message });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Exponer el puerto/IP activos para facilitar el diagnóstico
app.get('/port', (req, res) => {
  res.json({ port: ACTIVE_INFO.port, ip: ACTIVE_INFO.ip });
});

// Obtener IP local de la red WiFi
function getLocalIP() {
  const { networkInterfaces } = require('os');
  const nets = networkInterfaces();
  
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      // Buscar IPv4 no interna (192.168.x.x, 10.x.x.x, etc.)
      if (net.family === 'IPv4' && !net.internal) {
        if (net.address.startsWith('192.168.') || 
            net.address.startsWith('10.') || 
            net.address.startsWith('172.')) {
          return net.address;
        }
      }
    }
  }
  return 'localhost';
}

function printBanner(localIP) {
  console.log(`\n🚀 Servidor proxy corriendo en tu red WiFi!`);
  console.log(`\n📱 Usa desde tablets/móviles:`);
  console.log(`   http://${localIP}:${PORT}/api/attendance`);
  console.log(`\n💻 Usa desde esta PC:`);
  console.log(`   http://localhost:${PORT}/api/attendance`);
  console.log(`\n🔍 Ver registros: GET http://${localIP}:${PORT}/api/attendance`);
  console.log(`🧹 Limpiar DB: DELETE http://${localIP}:${PORT}/api/attendance`);
  console.log(`🔐 HMAC Secret: ${process.env.HMAC_SECRET || 'dev_secret'}`);
  console.log(`\n📋 Para Flutter app usa:`);
  console.log(`   FUNCTION_URL=http://${localIP}:${PORT}/api/attendance`);
  console.log(`\n🌐 Asegúrate que el Firewall de Windows permita el puerto ${PORT}`);
}

function tryListen(startPort = PORT, maxAttempts = 5) {
  let attempts = 0;
  function attempt(port) {
    const server = app.listen(port, '0.0.0.0', () => {
      PORT = port;
      const localIP = getLocalIP();
      ACTIVE_INFO = { port: PORT, ip: localIP };
      // Persistir la información del puerto/IP activos para troubleshooting
      try {
        fs.writeFileSync(path.join(__dirname, 'current_port.json'), JSON.stringify(ACTIVE_INFO, null, 2));
      } catch (e) {
        // Ignorar errores de escritura
      }
      printBanner(localIP);
    });
    server.on('error', (err) => {
      if (err.code === 'EADDRINUSE' && attempts < maxAttempts) {
        attempts++;
        const nextPort = port + 1;
        console.warn(`⚠️  Puerto ${port} en uso. Intentando en ${nextPort}...`);
        setTimeout(() => attempt(nextPort), 200);
      } else {
        console.error('❌ Error arrancando servidor:', err);
        process.exit(1);
      }
    });
  }
  attempt(startPort);
}

tryListen(PORT);