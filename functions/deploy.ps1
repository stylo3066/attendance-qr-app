param(
  [string]$projectId = ''
)

Write-Host "Desplegando Cloud Function verifyAttendance..."
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
  Write-Host "firebase-cli no encontrado. Instalando globalmente..."
  npm install -g firebase-tools
}

Write-Host "Inicia sesión en Firebase si es necesario..."
firebase login

if ($projectId -ne '') {
  firebase use $projectId
}

Read-Host -Prompt "Introduce el secreto HMAC para usar en functions.config" -AsSecureString | ConvertFrom-SecureString | Out-Null
$h = Read-Host -Prompt "Introduce el secreto HMAC (visible)"
if ($h -ne '') {
  firebase functions:config:set hmac.secret="$h"
}

cd ..\functions
npm install
firebase deploy --only functions:verifyAttendance
