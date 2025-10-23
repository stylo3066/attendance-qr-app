attendance-qr-server

Servidor Node.js mínimo para registrar eventos de asistencia verificando HMAC y guardando en Firestore.

Requisitos
- Node.js 18+ y npm
- Una cuenta de servicio de Firebase (archivo JSON) con permisos para Firestore

Configuración
1. Copia tu archivo de cuenta de servicio (JSON) dentro de `server/` o en una ruta accesible.
2. Crea un archivo `.env` en `server/` con estas variables:

```
GOOGLE_APPLICATION_CREDENTIALS=./path/to/serviceAccount.json
HMAC_SECRET=tu_secreto_hmac
PORT=3000
```

3. Instala dependencias e inicia:

```
cd server
npm install
npm start
```

Uso
- Endpoint: `POST /attendance`
- Body JSON:

```
{
  "signature": "<hmac-hex-of-payload>",
  "data": { "userId": "prof1", "userName": "Profesor X", "qrPayload": "..." }
}
```

El servidor validará la firma y, si es correcta, escribirá en la colección `attendance_events` de Firestore.

Para exponer localmente el servidor para pruebas desde el dispositivo móvil puedes usar `ngrok`:

```
npx ngrok http 3000
```
