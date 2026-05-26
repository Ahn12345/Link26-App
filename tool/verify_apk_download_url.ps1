# APK URL이 진짜 바이너리인지 확인 (HTML/LFS 포인터면 실패)
param([string[]] $Urls = @(
  "https://link26-frontend.vercel.app/link26.apk",
  "https://ahn12345.github.io/Link26-App/link26.apk"
))

foreach ($u in $Urls) {
  Write-Host "`n=== $u ===" -ForegroundColor Cyan
  try {
    $r = Invoke-WebRequest -Uri $u -Method Head -UseBasicParsing -MaximumRedirection 5 -ErrorAction Stop
    $ct = $r.Headers["Content-Type"]
    $len = $r.Headers["Content-Length"]
    Write-Host "Status: $($r.StatusCode)  Type: $ct  Length: $len"
    if ($ct -match "text/html") {
      Write-Host "FAIL: HTML(웹페이지) — APK 아님. 휴대폰에서 .txt 로 보일 수 있음." -ForegroundColor Red
    } elseif ($len -and [int64]$len -lt 1MB) {
      Write-Host "FAIL: 용량 너무 작음 (LFS 포인터 또는 오류 페이지)" -ForegroundColor Red
    } elseif ($ct -match "octet-stream|package-archive|zip") {
      Write-Host "OK: APK로 보임" -ForegroundColor Green
    } else {
      Write-Host "WARN: Content-Type 확인 필요" -ForegroundColor Yellow
    }
  } catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
  }
}
