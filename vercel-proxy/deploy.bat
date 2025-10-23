@echo off
echo Desplegando proxy de asistencia en Vercel...
echo.

:: Verificar si vercel CLI está instalado
where vercel >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Vercel CLI no encontrado. Instalando...
    npm install -g vercel
)

:: Cambiar al directorio del proxy
cd /d "%~dp0"

echo.
echo 1. Asegurate de tener:
echo    - Proyecto Firebase creado con Firestore activado
echo    - Cuenta de servicio JSON descargada
echo    - Secreto HMAC preparado
echo.

echo 2. Desplegando a Vercel...
vercel --prod

echo.
echo 3. Despues del despliegue, configura las variables de entorno:
echo    vercel env add HMAC_SECRET
echo    vercel env add FIREBASE_SERVICE_ACCOUNT_JSON
echo.
echo 4. Redespliega para aplicar las variables:
echo    vercel --prod
echo.

pause