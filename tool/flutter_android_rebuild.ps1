# Windows에서 Gradle "Failed to clean up output files" / stripDebugDebugSymbols 오류 시
# 캐시를 비운 뒤 flutter run 까지 한 번에 실행합니다.
#
# 실행 정책 오류 시: tool\flutter_android_rebuild.cmd 사용 (권장) 또는
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   .\tool\flutter_android_rebuild.ps1
#
# 사용 예:
#   .\tool\flutter_android_rebuild.ps1
#   .\tool\flutter_android_rebuild.ps1 -Device R3CR205QBCT

param(
    [string] $Device = ""
)

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "== flutter clean ==" -ForegroundColor Cyan
flutter clean

foreach ($rel in @("build", "android\build", "android\.gradle")) {
    $p = Join-Path $root $rel
    if (Test-Path $p) {
        Write-Host "== remove $rel ==" -ForegroundColor DarkYellow
        Remove-Item -Recurse -Force $p -ErrorAction SilentlyContinue
    }
}

Push-Location (Join-Path $root "android")
Write-Host "== gradlew --stop ==" -ForegroundColor Cyan
& .\gradlew.bat --stop 2>$null
Pop-Location

Write-Host "== flutter pub get ==" -ForegroundColor Cyan
flutter pub get

Write-Host "== flutter run ==" -ForegroundColor Cyan
if ($Device -ne "") {
    flutter run -d $Device
} else {
    flutter run
}
