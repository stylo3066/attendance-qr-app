param(
  [ValidateSet('all','server')]
  [string]$Scope = 'all'
)

Write-Host "=== Inicializar y subir repo a GitHub ===" -ForegroundColor Cyan

# 1) Verificar Git
try { git --version | Out-Null } catch {
  Write-Error "Git no está instalado o no está en PATH. Instala Git for Windows y reintenta."
  exit 1
}

# 2) Seleccionar carpeta raíz a versionar
$repoRoot = Join-Path $PSScriptRoot ".." | Resolve-Path
if ($Scope -eq 'server') {
  $repoRoot = Join-Path $repoRoot "vercel-proxy" | Resolve-Path
}
Write-Host "Usando carpeta: $repoRoot"
Set-Location $repoRoot

# 3) Asegurar .gitignore (si estamos en la raíz del proyecto completo ya existe)
$gitignorePath = Join-Path $repoRoot ".gitignore"
if (-not (Test-Path $gitignorePath)) {
  @(
    ".dart_tool/",
    ".packages",
    "build/",
    "pubspec.lock",
    ".idea/",
    ".vscode/",
    "*.iml",
    "vercel-proxy/node_modules/",
    "vercel-proxy/local_db.json",
    "vercel-proxy/current_port.json",
    "*.log",
    ".DS_Store",
    "Thumbs.db"
  ) | Out-File -Encoding utf8 $gitignorePath
  Write-Host "Creado .gitignore básico" -ForegroundColor Yellow
}

# 4) Init repo
if (-not (Test-Path (Join-Path $repoRoot ".git"))) {
  git init | Out-Null
  Write-Host "Repo inicializado" -ForegroundColor Green
}

# 5) Configurar identidad si no está
$userName = git config user.name
$userEmail = git config user.email
if (-not $userName -or -not $userEmail) {
  if (-not $userName) {
    $userName = Read-Host "Ingresa tu nombre para los commits (user.name)"
    git config user.name "$userName" | Out-Null
  }
  if (-not $userEmail) {
    $userEmail = Read-Host "Ingresa tu email para los commits (user.email)"
    git config user.email "$userEmail" | Out-Null
  }
  Write-Host "Identidad configurada: $userName <$userEmail>" -ForegroundColor Yellow
}

# 6) Primer commit
git add .
$commitMsg = Read-Host "Mensaje del commit inicial" 
if (-not $commitMsg) { $commitMsg = "Inicial: proyecto asistencia QR" }
# Manejar si no hay cambios
$changes = git status --porcelain
if ($changes) {
  git commit -m "$commitMsg"
  Write-Host "Commit creado" -ForegroundColor Green
} else {
  Write-Host "No hay cambios para commitear (posible repo ya commiteado)" -ForegroundColor Yellow
}

# 7) Remoto y push
$branch = "main"
git branch -M $branch | Out-Null
$remoteUrl = Read-Host "Pega la URL del repositorio en GitHub (https://github.com/usuario/repo.git)"
if (-not $remoteUrl) {
  Write-Error "No se proporcionó URL remota. Saliendo."
  exit 1
}
# Quitar 'origin' previo si existe
$existing = git remote
if ($existing -like '*origin*') { git remote remove origin | Out-Null }

git remote add origin $remoteUrl

Write-Host "Empujando a $remoteUrl ..." -ForegroundColor Cyan
try {
  git push -u origin $branch
  Write-Host "Push completado" -ForegroundColor Green
} catch {
  Write-Error "Fallo el push. Revisa credenciales o si el repo ya tiene contenido. Puedes intentar: git pull --rebase origin $branch y luego git push."
}
