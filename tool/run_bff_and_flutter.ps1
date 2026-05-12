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
# 한글 안내가 � 로 깨지지 않게 (Windows PowerShell 5 / 콘솔 코드 페이지)
try {
  $utf8 = [System.Text.UTF8Encoding]::new($false)
  [Console]::OutputEncoding = $utf8
  $OutputEncoding = $utf8
  if ($PSVersionTable.PSVersion.Major -lt 7) {
    chcp 65001 | Out-Null
  }
} catch { }
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
Write-Host "[Link26] Preparing BFF on port $Port..." -ForegroundColor Cyan
Write-Host "[Link26] App .env: NHIS_BASE_URL=http://10.0.2.2:$Port (emulator) or http://127.0.0.1:$Port (device/Chrome)" -ForegroundColor DarkGray
if ($useSubst) {
  Write-Host "[Link26] Non-ASCII path: Flutter will run via tool/run_with_ascii_path.ps1 (SUBST)." -ForegroundColor DarkYellow
} else {
  Write-Host "[Link26] ASCII path: Flutter runs in this folder (no SUBST)." -ForegroundColor DarkGray
}
Write-Host ""

$healthUrl = "http://127.0.0.1:$Port/health"
function Get-BffHealthJson([string]$Url) {
  try {
    $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 2
    if ($r.StatusCode -ne 200) { return $null }
    return $r.Content | ConvertFrom-Json
  } catch {
    return $null
  }
}

$existing = Get-BffHealthJson $healthUrl
$needStart = $true
if ($existing -ne $null -and $existing.ok -eq $true) {
  # 구버전 BFF(과거 스크립트)인지 구분: 최신은 publicData.serviceKeyFrom 를 내립니다.
  $isModern = $false
  try {
    $isModern = ($null -ne $existing.publicData.serviceKeyFrom)
  } catch { }
  if ($isModern) {
    Write-Host "[Link26] Existing BFF is already healthy on $Port - reusing it." -ForegroundColor DarkGray
    $needStart = $false
  } else {
    Write-Host "[Link26] Existing BFF on $Port looks legacy - restarting for latest routes..." -ForegroundColor Yellow
    $owners = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty OwningProcess -Unique
    foreach ($ownerPid in $owners) {
      try { Stop-Process -Id $ownerPid -Force -ErrorAction Stop } catch {}
    }
    Start-Sleep -Milliseconds 500
  }
}

$bffCmd = @"
Set-Location -LiteralPath '$projectRoot'
`$env:PORT = '$Port'
Write-Host '>>> link26_bff (PORT=' `$env:PORT ') <<<' -ForegroundColor Green
dart run tool/link26_bff.dart
"@

if ($needStart) {
  Write-Host "[Link26] Starting BFF on port $Port (new window)..." -ForegroundColor Cyan
  Start-Process -FilePath "powershell.exe" -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-NoExit",
    "-Command", $bffCmd
  ) | Out-Null
}

$ready = $false
for ($i = 0; $i -lt 60; $i++) {
  $h = Get-BffHealthJson $healthUrl
  if ($h -ne $null -and $h.ok -eq $true) {
    $ready = $true
    break
  } else {
    Start-Sleep -Milliseconds 400
  }
}

if (-not $ready) {
  Write-Warning "BFF health ($healthUrl) did not respond in time. Close the BFF window and check PORT / dart."
  exit 1
}

Write-Host "[Link26] BFF is up - starting Flutter..." -ForegroundColor Cyan
Write-Host ""

& (Join-Path $PSScriptRoot "sync_dotenv_asset.ps1") -ProjectRoot $projectRoot

Write-Host "[Link26] 연결 확인 — 앱은 .env 의 NHIS_BASE_URL 로만 BFF에 붙습니다." -ForegroundColor DarkGray
Write-Host "       에뮬레이터: NHIS_BASE_URL=http://10.0.2.2:$Port" -ForegroundColor DarkGray
Write-Host "       Chrome/같은 PC: http://127.0.0.1:$Port" -ForegroundColor DarkGray
try {
  $lan = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -notmatch '^(127\.|169\.254\.)' } |
    Sort-Object InterfaceMetric |
    ForEach-Object { $_.IPAddress }) | Select-Object -Unique
  if ($lan.Count -gt 0) {
    $one = $lan[0]
    Write-Host "       실제 폰(USB/Wi-Fi): 보통 NHIS_BASE_URL=http://${one}:$Port (PC IP가 다르면 ipconfig 로 맞추세요)" -ForegroundColor Yellow
    Write-Host "       폰 브라우저에서 http://${one}:$Port/health 가 열리면 네트워크·방화벽 OK." -ForegroundColor DarkGray
  }
} catch { }
Write-Host "       NHIS_USE_MOCK=true 이면 BFF로 안 붙고 목 동작합니다. 실연동은 false." -ForegroundColor DarkGray
Write-Host "       BFF 창에 나온 '실제 포트'가 $Port 가 아니면 .env 포트를 그에 맞게 수정 후 다시 이 스크립트." -ForegroundColor DarkGray
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
