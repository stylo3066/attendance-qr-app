# Dashboard de Asistencia - Configuración

Dashboard web para visualización en tiempo real de asistencias registradas desde las tablets.

## Configuración

### 1. Configurar Firebase Project
En `index.html`, reemplaza los valores del `firebaseConfig`:

```javascript
const firebaseConfig = {
  apiKey: "tu-api-key-real",
  authDomain: "tu-proyecto.firebaseapp.com",
  projectId: "tu-proyecto-id", 
  storageBucket: "tu-proyecto.appspot.com",
  messagingSenderId: "tu-sender-id",
  appId: "tu-app-id"
};
```

### 2. Configurar Firestore Rules
En Firebase Console > Firestore Database > Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Solo lectura para usuarios autenticados
    match /attendance_events/{document} {
      allow read: if request.auth != null;
      allow write: if false; // Solo el servidor puede escribir
    }
    
    // Información de usuarios (roles)
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 3. Crear usuario director
En Firebase Console > Authentication:
1. Crear usuario con email/password
2. En Firestore, crear documento en `/users/{uid}`:
```json
{
  "email": "director@escuela.com",
  "role": "director",
  "name": "Director"
}
```

### 4. Desplegar dashboard
Opciones:

**A) Firebase Hosting (gratis)**
```bash
# En la carpeta dashboard/
firebase init hosting
firebase deploy --only hosting
```

**B) Vercel (gratis)**
```bash
# En la carpeta dashboard/
vercel
```

**C) Servidor local (testing)**
```bash
# Servidor simple con Python
python -m http.server 8000
# O con Node.js
npx serve .
```

## Uso

1. **Login**: Email/password del director
2. **Visualización**: Tabla en tiempo real de asistencias
3. **Filtros**: Por usuario, código QR, fecha
4. **Exportar**: CSV para reportes

## Features

- ✅ Autenticación con Firebase Auth
- ✅ Lectura en tiempo real de Firestore
- ✅ Filtros dinámicos
- ✅ Exportación CSV
- ✅ Responsive design
- ✅ Control de roles (solo directores)

## Flujo completo

1. **Tablet escanea** → envía a Vercel proxy
2. **Proxy valida HMAC** → guarda en Firestore
3. **Dashboard escucha** → actualiza tabla en tiempo real
4. **Director ve** → asistencias inmediatamente