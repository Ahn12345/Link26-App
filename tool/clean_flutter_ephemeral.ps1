# Flutter가 ephemeral / build 폴더를 지우지 못할 때(파일 잠금·OneDrive 등) 수동 정리용.
# VS·Android Studio·flutter run 을 모두 종료한 뒤 실행하세요.
$ErrorActionPreference = "Continue"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $projectRoot

$paths = @(
  "build",
  ".dart_tool",
  "windows\flutter\ephemeral",
  "ios\Flutter\ephemeral",
  "macos\Flutter\ephemeral",
  "linux\flutter\ephemeral"
)

foreach ($rel in $paths) {
  $full = Join-Path $projectRoot $rel
  if (Test-Path -LiteralPath $full) {
    Write-Host "Removing: $full"
    Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction SilentlyContinue
  }
}

Write-Host "Done. If removal failed, reboot or close programs locking the folder, then run again."
Write-Host "Then use:  .\tool\run_with_ascii_path.ps1 pub get"
Write-Host "           .\tool\run_with_ascii_path.ps1 run"
