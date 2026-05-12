# BFF(link26_bff) + Flutter 앱을 한 번에 실행합니다.
#
# 사용 (프로젝트 루트에서):
#   .\tool\run_bff_and_flutter.ps1
#   .\tool\run_bff_and_flutter.ps1 -Port 8788
#   .\tool\run_bff_and_flutter.ps1 -CleanBuild
#   .\tool\run_bff_and_flutter.ps1 -FlutterArgs @('-d','chrome')
#
# 경로에 한글 등 비ASCII가 있으면 기본으로 SUBST(ASCII 드라이브) 경유 — aapt "Illegal byte sequence" 방지.
# SUBST 없이 돌리려면(ASCII 경로 프로젝트 등):  .\tool\run_bff_and_flutter.ps1 -NoSubst
#
# Android 에뮬레이터에서 BFF(호스트 PC)로 붙이려면 .env 예:
#   NHIS_USE_MOCK=false
#   NHIS_BASE_URL=http://10.0.2.2:8787
#
param(
  [int] $Port = 8787,
  [switch] $CleanBuild,
  [switch] $NoSubst,
  [switch] $Subst,
  [string[]] $FlutterArgs = @()
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Test-ContainsNonAscii([string]$s) {
  foreach ($ch in $s.ToCharArray()) {
    if ([int][char]$ch -gt 127) { return $true }
  }
  return $false
}

$useSubst = $false
if (-not $NoSubst) {
  if ($Subst -or (Test-ContainsNonAscii $projectRoot)) {
    $useSubst = $true
  }
}

Write-Host ""
Write-Host "[Link26] Starting BFF on port $Port (new window)..." -ForegroundColor Cyan
Write-Host "[Link26] App .env: NHIS_BASE_URL=http://10.0.2.2:$Port (emulator) or http://127.0.0.1:$Port (device/Chrome)" -ForegroundColor DarkGray
if ($useSubst) {
  Write-Host "[Link26] Non-ASCII path: Flutter will run via tool/run_with_ascii_path.ps1 (SUBST)." -ForegroundColor DarkYellow
} else {
  Write-Host "[Link26] ASCII path: Flutter runs in this folder (no SUBST)." -ForegroundColor DarkGray
}
Write-Host ""

$bffCmd = @"
Set-Location -LiteralPath '$projectRoot'
`$env:PORT = '$Port'
Write-Host '>>> link26_bff (PORT=' `$env:PORT ') <<<' -ForegroundColor Green
dart run tool/link26_bff.dart
"@

Start-Process -FilePath "powershell.exe" -ArgumentList @(
  "-NoProfile",
  "-ExecutionPolicy", "Bypass",
  "-NoExit",
  "-Command", $bffCmd
) | Out-Null

$healthUrl = "http://127.0.0.1:$Port/health"
$ready = $false
for ($i = 0; $i -lt 60; $i++) {
  try {
    $r = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 2
    if ($r.StatusCode -eq 200) {
      $ready = $true
      break
    }
  } catch {
    Start-Sleep -Milliseconds 400
  }
}

if (-not $ready) {
  Write-Warning "BFF health ($healthUrl) did not respond in time. Close the BFF window and check PORT / dart."
  exit 1
}

Write-Host "[Link26] BFF is up - starting Flutter..." -ForegroundColor Cyan
Write-Host ""

$flutterCmd = @("run") + $FlutterArgs
$runScript = Join-Path $projectRoot "tool\run_with_ascii_path.ps1"

if ($useSubst) {
  if ($CleanBuild) {
    & $runScript -CleanBuild @flutterCmd
  } else {
    & $runScript @flutterCmd
  }
  exit $LASTEXITCODE
}

Set-Location -LiteralPath $projectRoot
if ($CleanBuild) {
  Write-Host "[Link26] flutter clean (CleanBuild)..." -ForegroundColor Cyan
  & flutter clean
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
& flutter @flutterCmd
exit $LASTEXITCODE
