@echo off
echo 📱 Instalador de Asistencia QR para Android
echo.

cd /d "%~dp0"

echo 🔍 Verificando dispositivos conectados...
flutter devices

echo.
echo 📦 APK compilada en: build\app\outputs\flutter-apk\app-debug.apk
echo.

echo 🔧 Opciones de instalación:
echo.
echo 1️⃣  OPCIÓN 1 - Instalación automática (si el celular está autorizado):
echo    flutter install
echo.
echo 2️⃣  OPCIÓN 2 - Instalación manual:
echo    - Copia el archivo app-debug.apk a tu celular
echo    - Abre el archivo en el celular
echo    - Permite "Instalar desde fuentes desconocidas" si es necesario
echo    - Instala la aplicación
echo.
echo 3️⃣  OPCIÓN 3 - Usar ADB directamente:
echo    %%ANDROID_HOME%%\platform-tools\adb install build\app\outputs\flutter-apk\app-debug.apk
echo.

set /p choice="¿Qué opción prefieres? (1/2/3): "

if "%choice%"=="1" (
    echo.
    echo 🚀 Intentando instalación automática...
    flutter install
) else if "%choice%"=="2" (
    echo.
    echo 📂 Abriendo carpeta con la APK...
    explorer build\app\outputs\flutter-apk\
    echo.
    echo ℹ️  Copia app-debug.apk a tu celular e instálalo manualmente
) else if "%choice%"=="3" (
    echo.
    echo 🔧 Usando ADB...
    if exist "%ANDROID_HOME%\platform-tools\adb.exe" (
        "%ANDROID_HOME%\platform-tools\adb.exe" install build\app\outputs\flutter-apk\app-debug.apk
    ) else (
        echo ❌ ADB no encontrado. Usa la opción 2 (manual).
    )
) else (
    echo ❌ Opción no válida
)

echo.
echo ⚙️  CONFIGURACIÓN IMPORTANTE:
echo    📡 URL del servidor: http://192.168.100.7:3000/api/attendance
echo    🔐 Secreto HMAC: dev_secret
echo.
echo 📋 INSTRUCCIONES DE USO:
echo    1. Asegúrate de estar conectado a la misma red WiFi
echo    2. Abre la app "Asistencia QR"
echo    3. Presiona "Iniciar Scanner"
echo    4. Escanea el QR de cualquier profesor
echo    5. Los datos se envían automáticamente al dashboard
echo.

pause