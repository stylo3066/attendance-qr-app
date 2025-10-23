[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/ZweBXA?referralCode=alphasec)

# 🚀 Deploy Instantáneo

## Opción 1: Railway (1 click)

1. **Click aquí**: https://railway.app/template/new
2. Conecta tu GitHub: `stylo3066/attendance-qr-app`
3. Configura:
   - Root Directory: `vercel-proxy`
   - Start Command: `node server.js`
   - Variable: `HMAC_SECRET=dev_secret`
4. Deploy → Te da una URL: `https://[proyecto].up.railway.app`

## Opción 2: Render (ya configurado)

1. Ve a https://dashboard.render.com
2. New → Web Service
3. Connect: `stylo3066/attendance-qr-app`
4. Render detecta automáticamente el `render.yaml`
5. Deploy → URL: `https://[proyecto].onrender.com`

## Opción 3: Koyeb (más rápido)

1. https://app.koyeb.com
2. Create Service → GitHub
3. Repo: `stylo3066/attendance-qr-app`
4. Build:
   - Directory: `vercel-proxy`
   - Run: `node server.js`
5. Deploy → `https://[proyecto].koyeb.app`

---

## Una vez desplegado:

Tu URL será algo como: `https://attendance-qr.up.railway.app`

### Actualiza estos archivos:

**En `lib/main.dart` línea 505:**
```dart
const defaultBackendUrl = 'https://TU-URL-AQUI.railway.app/api/attendance';
```

**En `web/dashboard.html` línea 872:**
```javascript
return 'https://TU-URL-AQUI.railway.app';
```

**Luego:**
```bash
git add .
git commit -m "Backend online configurado"
git push
```

**GitHub Pages se actualizará en 2 minutos.**
