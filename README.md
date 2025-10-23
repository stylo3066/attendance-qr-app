# attendance-qr-app

## Deploy en GitHub Pages (Flutter Web)

Este repo incluye un workflow para publicar la app Flutter Web en GitHub Pages.

Pasos:

1) Habilita GitHub Actions en tu repo (si no lo está).
2) Haz push con el archivo del workflow `.github/workflows/deploy-gh-pages.yml` (ya agregado en este commit).
3) En Settings > Pages, selecciona:
	- Source: Deploy from a branch
	- Branch: `gh-pages` / `/ (root)`
4) Haz un commit/push a `master` (o `main`) para disparar el workflow.
5) La web quedará publicada en:
	https://<tu_usuario>.github.io/attendance-qr-app/

Notas:
- El build usa `--base-href=/attendance-qr-app/` para que los assets se sirvan correctamente en Pages.
- La app necesita un endpoint público (FUNCTION_URL) para registrar asistencia. GitHub Pages es estático, así que usa un backend HTTPS (por ejemplo Vercel) y configura la URL desde la pantalla de Ajustes dentro de la app.

### Backend sugerido (Vercel)
Puedes usar la carpeta `vercel-proxy/` como backend sin Firestore real:
1) Despliega en Vercel y define la variable `HMAC_SECRET`.
2) Obtén la URL pública (https://...vercel.app/api/attendance).
3) En la app (GitHub Pages), abre Ajustes y pega esa URL en FUNCTION_URL.

# Control de Asistencia de Profesores mediante QR

Esta es una app móvil creada con Flutter para registrar la asistencia de profesores escaneando códigos QR.

## Funcionalidades principales
- Escaneo de códigos QR
- Registro de asistencia

## Requisitos
- Flutter SDK instalado
- Un emulador o dispositivo físico Android/iOS

## Instalación
1. Abre una terminal en la carpeta del proyecto.
2. Ejecuta `flutter pub get` para instalar las dependencias.
3. Ejecuta `flutter run` para iniciar la app.

## Estructura inicial
- `lib/main.dart`: Pantalla principal y lógica de escaneo QR.

## Dependencias
- `qr_code_scanner`: Para escanear códigos QR.

---
Reemplaza este archivo con instrucciones específicas según evolucione el proyecto.

## Guía rápida: configurar Firebase y dashboard (MVP gratuito)

1) Crea un proyecto en https://console.firebase.google.com (plan Spark es gratuito).

2) Añade una app Android (o iOS) en Firebase y descarga `google-services.json` (Android) o `GoogleService-Info.plist` (iOS).
	- Coloca `google-services.json` en `android/app/`.
	- Coloca `GoogleService-Info.plist` en `ios/Runner/`.

3) Añade tu configuración de Firebase en `dashboard/index.html` (reemplaza los valores de `firebaseConfig`).

4) Para desplegar el dashboard con Firebase Hosting (opcional):
	- Instala firebase-tools: `npm install -g firebase-tools`.
	- Inicia sesión: `firebase login`.
	- Inicializa hosting dentro de la carpeta `dashboard`: `firebase init hosting` y selecciona tu proyecto.
	- Despliega: `firebase deploy --only hosting`.

5) Prueba:
	- Ejecuta la app Flutter en un dispositivo y escanea un QR. Deberías ver los eventos en el dashboard en tiempo real.

Notas:
- Este repo contiene la lógica mínima para enviar eventos a Firestore. Debes completar la autenticación, seguridad (validación de QR), y reglas de Firestore antes de usar en producción.
- Si te quedas sin créditos o llegas a límites, considera limpiar datos de `attendance_events` o pasar a un servidor propio.

## Desplegar Cloud Function (verifyAttendance)

1) Abre PowerShell y asegúrate de estar autenticado con Firebase: `firebase login`.
2) Ve a la carpeta `functions` y ejecuta:

```powershell
cd 'C:\app movil\attendance_qr\functions'
npm install
```

3) Configura la clave HMAC (reemplaza SECRET por tu secreto):

```powershell
firebase functions:config:set hmac.secret="SECRET"
```

4) Despliega la función:

```powershell
firebase deploy --only functions:verifyAttendance
```

5) Firebase devolverá la URL HTTPS de la función. Copia esa URL.

6) En `lib/main.dart` reemplaza las constantes `CLOUD_FUNCTION_URL` y `HMAC_SECRET` con la URL y el secreto que usaste.

7) Ejecuta la app y prueba el flujo: al escanear un QR la app llamará a la función; si la firma HMAC es correcta, el evento se guardará como `verified: true` en Firestore.

---

Si quieres, ejecuto el script `functions/deploy.ps1` desde aquí — pero necesitas autenticar `firebase` en tu máquina y aceptar prompts interactivos, por lo que es más seguro que lo ejecutes tú y pegues aquí la URL que te devuelva.