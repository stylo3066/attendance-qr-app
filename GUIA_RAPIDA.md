# 🎓 Control de Asistencia QR - GUÍA RÁPIDA

## ✅ **LA APP YA FUNCIONA SIN CONFIGURACIÓN**

Esta aplicación registra asistencia mediante códigos QR. **Funciona inmediatamente** sin necesidad de configurar servidores ni bases de datos.

---

## 🚀 Uso Inmediato (3 pasos)

### 1️⃣ **Genera códigos QR de profesores**
Abre en tu navegador:
```
https://stylo3066.github.io/attendance-qr-app/web/test-qr.html
```
- Selecciona un profesor
- Se genera su código QR
- Imprime o muestra en pantalla

### 2️⃣ **Escanea con la app móvil Flutter**
- Abre la app en tu teléfono
- Presiona "Iniciar Scanner"
- Enfoca el código QR del profesor
- ✅ **¡Listo! Asistencia registrada**

### 3️⃣ **Ver registros**
En la app:
- Toca el ícono de historial (reloj) en la esquina superior derecha
- Verás todos los escaneos guardados localmente

**O** desde el navegador web:
```
https://stylo3066.github.io/attendance-qr-app/web/simple-demo.html
```

---

## 📱 Modos de Funcionamiento

### **Modo Offline/Demo (por defecto)**
✅ Funciona **sin internet**  
✅ Sin configuración necesaria  
✅ Registros guardados en el dispositivo  
✅ Perfecto para presentaciones y demos  

### **Modo con Servidor (opcional)**
Si necesitas sincronizar con un servidor:
1. Toca el ícono de ajustes ⚙️
2. Configura:
   - `FUNCTION_URL`: Tu endpoint de backend
   - `HMAC_SECRET`: Tu clave secreta
3. Toca "Probar conexión"
4. ✅ Los registros se sincronizan automáticamente

---

## 🌐 Herramientas Web (GitHub Pages)

Todas funcionan **sin instalación**, solo abre en tu navegador:

| Herramienta | URL | Descripción |
|-------------|-----|-------------|
| **Generador de QR** | [/web/test-qr.html](https://stylo3066.github.io/attendance-qr-app/web/test-qr.html) | Crea códigos QR de profesores |
| **Demo Web** | [/web/simple-demo.html](https://stylo3066.github.io/attendance-qr-app/web/simple-demo.html) | Escanea y registra desde el navegador |
| **Dashboard** | [/web/dashboard.html](https://stylo3066.github.io/attendance-qr-app/web/dashboard.html) | Ver todos los registros |

---

## 📦 Instalación de la App Flutter

### Android
```bash
cd attendance_qr
flutter build apk
# Instala: build/app/outputs/flutter-apk/app-release.apk
```

### Web
```bash
flutter build web
# Despliega la carpeta build/web/
```

### iOS
```bash
flutter build ios
# Requiere Mac + Xcode
```

---

## 🔧 Configuración Avanzada (Opcional)

### Backend con Vercel (HTTPS + Firestore)
Si necesitas un backend real:

1. **Crea proyecto en Vercel**
   - Importa este repo: `stylo3066/attendance-qr-app`
   - Root Directory: `attendance_qr/vercel-proxy`

2. **Variables de entorno en Vercel**
   ```
   HMAC_SECRET=tu_secreto_fuerte
   FIREBASE_SERVICE_ACCOUNT_JSON={"project_id":"..."}
   ```

3. **Usa la URL en la app**
   ```
   FUNCTION_URL=https://tu-proyecto.vercel.app/api/attendance
   HMAC_SECRET=tu_secreto_fuerte
   ```

### Servidor Local (desarrollo)
```powershell
cd vercel-proxy
node server.js
# Escucha en http://192.168.x.x:3000
```

En la app:
```
FUNCTION_URL=http://192.168.x.x:3000/api/attendance
HMAC_SECRET=dev_secret
```

---

## 🎯 Para tu Presentación de Mañana

### Opción 1: Solo móvil (más simple)
1. Genera QR en https://stylo3066.github.io/attendance-qr-app/web/test-qr.html
2. Abre la app Flutter en el teléfono
3. Escanea el QR
4. Muestra el historial en la app
5. ✅ **Listo**

### Opción 2: Con dashboard web
1. Abre https://stylo3066.github.io/attendance-qr-app/web/simple-demo.html en tu laptop
2. Genera QR desde el mismo sitio (botón en la parte superior)
3. Escanea desde el navegador usando la cámara web
4. Los registros aparecen en tiempo real en la tabla
5. ✅ **Muy visual**

### Opción 3: Combinada (más completa)
1. Genera QR en test-qr.html
2. Escanea con la app móvil Flutter
3. Muestra el dashboard web en tu laptop con todos los registros
4. Explica que todo funciona sin servidor
5. ✅ **Impresiona al profesor**

---

## 💡 Consejos para la Demo

- ✅ **Funciona offline**: No necesitas internet en el momento de la presentación
- ✅ **Sin configuración**: La app funciona inmediatamente tras instalarla
- ✅ **Registros persistentes**: Los escaneos se guardan en el dispositivo
- ✅ **Multiple plataformas**: Móvil (Flutter) + Web (GitHub Pages)

---

## 🆘 Solución de Problemas

### "No registra la asistencia"
✅ **SOLUCIONADO**: La app ahora funciona en modo offline por defecto. Los registros se guardan localmente.

### "No aparece el servidor"
✅ No necesitas servidor. La app funciona offline. Si quieres servidor, configúralo en Ajustes.

### "Error de permisos de cámara"
- Android: Ve a Ajustes > Apps > [Tu App] > Permisos > Cámara
- iOS: Ve a Ajustes > Privacidad > Cámara > [Tu App]

---

## 📊 Arquitectura

```
attendance_qr/
├── lib/main.dart              # App Flutter (Android/iOS/Web)
├── web/
│   ├── test-qr.html          # Generador de QR
│   ├── simple-demo.html      # Demo web completo
│   └── dashboard.html        # Dashboard de registros
├── vercel-proxy/             # Backend opcional (Vercel/Node)
└── functions/                # Backend opcional (Firebase)
```

**Modo por defecto**: Sin backend, todo funciona localmente  
**Modo avanzado**: Sincronización con Vercel o Firebase

---

## 📝 Lista de Profesores Demo

- **PROF_001**: Juan Pérez - Matemáticas
- **PROF_002**: María González - Física
- **PROF_003**: Carlos Rodríguez - Química
- **PROF_004**: Ana Martínez - Biología
- **PROF_005**: Luis López - Historia

Puedes editar en `vercel-proxy/professors.js` o `web/professors.js`

---

## 🎉 ¡Listo para Presentar!

Tu proyecto **YA FUNCIONA** sin necesidad de configuración adicional.

**Para mañana**: Solo abre la app, escanea un QR, y muestra los registros. ✅

---

## 📞 Soporte

- Repositorio: https://github.com/stylo3066/attendance-qr-app
- Demo Web: https://stylo3066.github.io/attendance-qr-app/web/simple-demo.html
- Generador QR: https://stylo3066.github.io/attendance-qr-app/web/test-qr.html
