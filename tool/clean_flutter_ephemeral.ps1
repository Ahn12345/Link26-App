# Flutter / Windows에서 build·.dart_tool·ephemeral 삭제가 잠금으로 실패할 때 사용합니다.
# (OneDrive·백신·IDE·dart 분석 서버·Gradle 이 폴더를 잡는 경우가 많습니다.)
#
# 사용:
#   .\tool\clean_flutter_ephemeral.ps1
#   .\tool\clean_flutter_ephemeral.ps1 -StopDart    # dart.exe 종료(다른 Dart 작업도 끊김)
#
# 이후:  flutter pub get
#        flutter run   또는   .\tool\run_with_ascii_path.ps1 run
param(
  [switch] $StopDart
)

$ErrorActionPreference = "Continue"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $projectRoot

function Remove-PathRobust {
  param([Parameter(Mandatory)][string] $LiteralPath)
  if (-not (Test-Path -LiteralPath $LiteralPath)) { return $true }
  Write-Host "Removing: $LiteralPath"
  try {
    cmd.exe /c "attrib -r -s -h `"$LiteralPath\*`" /s /d" 2>$null | Out-Null
  } catch {}
  Remove-Item -LiteralPath $LiteralPath -Recurse -Force -ErrorAction SilentlyContinue
  if (-not (Test-Path -LiteralPath $LiteralPath)) { return $true }
  cmd.exe /c "rmdir /s /q `"$LiteralPath`"" 2>$null | Out-Null
  return -not (Test-Path -LiteralPath $LiteralPath)
}

if ($StopDart) {
  Write-Host "[Link26] Stopping dart.exe (analysis server / flutter tools)..." -ForegroundColor Yellow
  Get-Process -Name "dart" -ErrorAction SilentlyContinue | ForEach-Object {
    try { $_.Kill() } catch {}
  }
  Start-Sleep -Milliseconds 600
}

$gradle = Join-Path $projectRoot "android\gradlew.bat"
if (Test-Path -LiteralPath $gradle) {
  Write-Host "[Link26] gradlew --stop (release Java/Gradle file locks)..." -ForegroundColor Cyan
  Push-Location (Join-Path $projectRoot "android")
  try { & .\gradlew.bat --stop 2>$null } catch {}
  Pop-Location
  Start-Sleep -Milliseconds 400
}

# 자식부터 지운 뒤 부모 (Windows 심볼릭 링크·junction 대응)
$paths = @(
  "windows\flutter\ephemeral\.plugin_symlinks",
  "windows\flutter\ephemeral",
  "linux\flutter\ephemeral",
  "macos\Flutter\ephemeral",
  "ios\Flutter\ephemeral",
  "build",
  ".dart_tool"
)

$failed = $false
foreach ($rel in $paths) {
  $full = Join-Path $projectRoot $rel
  if (-not (Remove-PathRobust -LiteralPath $full)) {
    Write-Warning "Still locked or not removed: $full"
    $failed = $true
  }
}

if ($failed) {
  Write-Host ""
  Write-Warning "Some folders could not be removed. Close Cursor/VS Code for this repo, stop Android Studio and any flutter run, then re-run."
  Write-Warning "Try: .\tool\clean_flutter_ephemeral.ps1 -StopDart   If on OneDrive, pause sync or move the project to e.g. C:\dev"
} else {
  Write-Host "Done." -ForegroundColor Green
}

Write-Host "Next (non-ASCII path e.g. OneDrive\...\Documents\...):"
Write-Host "  .\flutterw.ps1 pub get"
Write-Host "  .\flutterw.ps1 run"
Write-Host "Or:  .\tool\run_with_ascii_path.ps1 pub get / run"
Write-Host "Do NOT use plain 'flutter run' on Korean paths - aapt fails (Illegal byte sequence)."
