# Proxy de Asistencia QR - Vercel

Endpoint HTTPS gratuito para validar asistencia con firma HMAC y guardar en Firestore.

## Configuración y Despliegue

### 1. Instalar Vercel CLI
```bash
npm install -g vercel
```

### 2. Crear proyecto Firebase (solo Firestore)
1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Crear nuevo proyecto (sin Analytics)
3. Activar Firestore Database en modo test
4. Ir a Project Settings > Service Accounts
5. Generar nueva clave privada (descargar JSON)

### 3. Configurar variables de entorno en Vercel
```bash
vercel login
vercel
# Seguir wizard de configuración

# Configurar secretos (una sola vez)
vercel env add HMAC_SECRET
# Introducir: un_secreto_fuerte_aleatorio

vercel env add FIREBASE_SERVICE_ACCOUNT_JSON
# Pegar todo el contenido JSON de la cuenta de servicio
```

### 4. Desplegar
```bash
vercel --prod
```

### 5. Configurar Flutter app
Usar la URL que te da Vercel (ej: `https://tu-proyecto.vercel.app/api/attendance`)

```bash
$env:FUNCTION_URL="https://tu-proyecto.vercel.app/api/attendance"
$env:HMAC_SECRET="tu_secreto_fuerte"
flutter run -d chrome --dart-define=FUNCTION_URL=$env:FUNCTION_URL --dart-define=HMAC_SECRET=$env:HMAC_SECRET
```

## Estructura del endpoint

### Request
```json
POST /api/attendance
{
  "signature": "hmac_sha256_hex",
  "data": {
    "qrCode": "PROF_123",
    "deviceId": "flutter_app", 
    "timestamp": "2025-10-17T10:30:00.000Z",
    "user": "Usuario Demo"
  }
}
```

### Response exitosa
```json
{
  "ok": true,
  "id": "firestore_doc_id",
  "message": "Attendance recorded successfully"
}
```

## Firestore Schema

### Colección: `attendance_events`
```json
{
  "qrCode": "PROF_123",
  "deviceId": "flutter_app",
  "timestamp": "2025-10-17T10:30:00.000Z", 
  "user": "Usuario Demo",
  "verified": true,
  "timestamp": [SERVER_TIMESTAMP]
}
```

## Costos
- **Vercel**: 100% gratis hasta 100GB bandwidth/mes
- **Firestore**: Gratis hasta 50K lecturas + 20K escrituras/día
- **Total**: $0 para uso escolar normal

## Testing local
```bash
vercel dev
# Endpoint local: http://localhost:3000/api/attendance
```