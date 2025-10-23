# 🚀 DESPLIEGUE INSTANTÁNEO EN GLITCH

## Pasos rápidos (5 minutos):

### 1. Ve a https://glitch.com
- Click "Sign in" (con GitHub)

### 2. Crea nuevo proyecto
- Click "New Project" → "Import from GitHub"
- Pega: `https://github.com/stylo3066/attendance-qr-app`
- En "Advanced Options":
  - Root Directory: `vercel-proxy`
  - Start Command: `node server.js`

### 3. Configura variables de entorno
En el archivo `.env` de Glitch, agrega:
```
HMAC_SECRET=dev_secret
PORT=3000
```

### 4. Tu URL será:
```
https://tu-proyecto.glitch.me
```

### 5. Configura la app:
- En la app Flutter, ve a Ajustes
- FUNCTION_URL: `https://tu-proyecto.glitch.me/api/attendance`
- HMAC_SECRET: `dev_secret`

### 6. Actualiza el dashboard:
Abre el dashboard con:
```
https://stylo3066.github.io/attendance-qr-app/dashboard.html?server=https://tu-proyecto.glitch.me
```

## Alternativa MÁS RÁPIDA: Usar mi servidor de prueba

Puedo desplegar tu backend en un servidor público AHORA MISMO sin que hagas nada.

**¿Quieres que lo despliegue yo en un servidor público gratuito para que funcione YA?**
