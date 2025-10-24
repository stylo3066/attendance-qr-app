Write-Host "MONITOR SIMPLE DEL SISTEMA" -ForegroundColor Green
Write-Host "===========================" -ForegroundColor Green

$lastCount = 0

while ($true) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    try {
        $response = Invoke-WebRequest -Uri "http://192.168.100.7:3000/api/attendance" -TimeoutSec 3
        $data = $response.Content | ConvertFrom-Json
        $currentCount = $data.Count
        
        if ($currentCount -ne $lastCount) {
            Write-Host ""
            Write-Host "NUEVO REGISTRO! [$timestamp]" -ForegroundColor Green -BackgroundColor Black
            
            $latest = $data | Sort-Object timestamp -Descending | Select-Object -First 1
            $time = [DateTime]::Parse($latest.timestamp).ToString("HH:mm:ss")
            Write-Host "   Profesor: $($latest.professorFullName)" -ForegroundColor Yellow
            Write-Host "   Materia: $($latest.subject)" -ForegroundColor Cyan  
            Write-Host "   Hora: $time" -ForegroundColor White
            Write-Host "   Codigo: $($latest.qrCode)" -ForegroundColor Gray
            
            $lastCount = $currentCount
        } else {
            Write-Host "[$timestamp] Esperando... ($currentCount registros)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "[$timestamp] Error de conexion" -ForegroundColor Red
    }
    
    Start-Sleep -Seconds 3
}