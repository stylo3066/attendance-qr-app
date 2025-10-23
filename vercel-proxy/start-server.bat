@echo off
echo 🚀 Iniciando servidor local de asistencia QR...
echo.

cd /d "%~dp0"

:: Verificar si Node.js está instalado
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Node.js no encontrado. Descárgalo de: https://nodejs.org
    pause
    exit /b 1
)

:: Instalar dependencias si no existen
if not exist "node_modules" (
    echo 📦 Instalando dependencias...
    npm install
)

:: Configurar firewall automáticamente (requiere permisos admin)
echo 🔥 Configurando Firewall de Windows...
set PORT=%PORT%
if "%PORT%"=="" set PORT=3000

:: Abrir rango de puertos 3000-3005 por si el servidor cambia de puerto
for /L %%P in (3000,1,3005) do (
  netsh advfirewall firewall delete rule name="Attendance QR Server %%P" >nul 2>nul
  netsh advfirewall firewall add rule name="Attendance QR Server %%P" dir=in action=allow protocol=TCP localport=%%P >nul 2>nul
)

if %ERRORLEVEL% EQU 0 (
    echo ✅ Firewall configurado (puertos 3000-3005 permitidos)
) else (
    echo ⚠️  Ejecuta como Administrador para configurar firewall automáticamente
    echo    O permite manualmente los puertos 3000-3005 en el Firewall de Windows
)

echo.
echo 🌐 Iniciando servidor en red WiFi en puerto %PORT% ...
set HMAC_SECRET=dev_secret
set PORT=%PORT%
node server.js

pause