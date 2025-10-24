# 🔍 Monitor del Sistema de Asistencia QR
# Ejecuta este script mientras pruebas la app para ver todo lo que pasa

Write-Host "🔍 MONITOR DEL SISTEMA DE ASISTENCIA QR" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green
Write-Host ""

# Función para mostrar el estado del servidor
function Test-Server {
    try {
        $response = Invoke-WebRequest -Uri "http://192.168.100.7:3000/api/attendance" -TimeoutSec 3
        if ($response.StatusCode -eq 200) {
            $data = $response.Content | ConvertFrom-Json
            Write-Host "✅ Servidor activo - Registros: $($data.Count)" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "❌ Servidor no responde" -ForegroundColor Red
        return $false
    }
}

# Función para mostrar registros recientes
function Show-RecentRecords {
    try {
        $response = Invoke-WebRequest -Uri "http://192.168.100.7:3000/api/attendance" -TimeoutSec 3
        $data = $response.Content | ConvertFrom-Json
        
        if ($data.Count -gt 0) {
            Write-Host "📊 ÚLTIMOS 3 REGISTROS:" -ForegroundColor Cyan
            $data | Sort-Object timestamp -Descending | Select-Object -First 3 | ForEach-Object {
                $time = [DateTime]::Parse($_.timestamp).ToString("HH:mm:ss")
                Write-Host "  🕐 $time - $($_.professorFullName) - $($_.qrCode)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "📊 No hay registros en el servidor" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "❌ Error obteniendo registros" -ForegroundColor Red
    }
}

# Función para mostrar estado del archivo JSON
function Show-JsonStatus {
    $jsonFile = "c:\Users\alons\OneDrive\Documentos\GitHub\app movil\attendance_qr\web\live-attendance.json"
    if (Test-Path $jsonFile) {
        $content = Get-Content $jsonFile | ConvertFrom-Json
        Write-Host "📁 Archivo JSON: $($content.Count) registros" -ForegroundColor Magenta
        if ($content.Count -gt 0) {
            $latest = $content | Sort-Object timestamp -Descending | Select-Object -First 1
            $time = [DateTime]::Parse($latest.timestamp).ToString("HH:mm:ss")
            Write-Host "   Último: $time - $($latest.professorFullName)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "📁 Archivo JSON no existe" -ForegroundColor Red
    }
}

# Monitoreo continuo
Write-Host "🚀 Iniciando monitoreo continuo..."
Write-Host "   Presiona Ctrl+C para detener"
Write-Host ""

$lastRecordCount = 0
$iteration = 0

while ($true) {
    $iteration++
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    Write-Host "🔄 [$timestamp] Iteración $iteration" -ForegroundColor White
    
    # Estado del servidor
    $serverActive = Test-Server
    
    if ($serverActive) {
        # Obtener conteo actual
        try {
            $response = Invoke-WebRequest -Uri "http://192.168.100.7:3000/api/attendance" -TimeoutSec 3
            $data = $response.Content | ConvertFrom-Json
            $currentCount = $data.Count
            
            if ($currentCount -ne $lastRecordCount) {
                Write-Host "🆕 ¡NUEVO REGISTRO DETECTADO!" -ForegroundColor Green -BackgroundColor Black
                Show-RecentRecords
                Show-JsonStatus
                $lastRecordCount = $currentCount
            } else {
                Write-Host "📊 Sin cambios - $currentCount registros" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "❌ Error verificando registros" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Start-Sleep -Seconds 5
}