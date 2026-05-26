# 웹 공개 배포용 release APK — dist/ + tool/web_download/ 복사
#
#   .\tool\build_web_distribution_apk.ps1 `
#     -PublicDotenvPath "assets\env\dotenv.public" `
#     -RemoteConfigUrl "https://your-site.com/link26-bff.json"
#
# dotenv.public 은 dotenv.public.example 을 복사해 LINK26_REMOTE_CONFIG_URL 만 채우면 됩니다.
# TILKO_API_KEY·GEMINI_API_KEY·집 IP(192.168.*) 는 APK 에 넣지 마세요.

param(
  [string] $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string] $PublicDotenvPath = "",
  [string] $RemoteConfigUrl = "",
  [string] $ProductionBffUrl = "",
  [switch] $SkipBuild
)

$ErrorActionPreference = "Stop"
Set-Location $ProjectRoot

$pubspec = Get-Content (Join-Path $ProjectRoot "pubspec.yaml") -Raw
if ($pubspec -match 'version:\s*([^\s+#]+)') {
  $version = $Matches[1].Trim()
} else {
  $version = "1.0.0+1"
}
$apkName = "Link26-$version.apk"

$assetDotenv = Join-Path $ProjectRoot "assets\env\dotenv"
$backupDotenv = Join-Path $ProjectRoot "assets\env\dotenv.local.backup"
$distDir = Join-Path $ProjectRoot "dist"
$webDir = Join-Path $ProjectRoot "tool\web_download"

function Test-DotenvLooksUnsafe([string] $text) {
  if ($text -match '192\.168\.|10\.0\.2\.2|127\.0\.0\.1') { return "NHIS_BASE_URL 에 사설 IP 가 있습니다." }
  # 값은 같은 줄에만 검사(빈 TILKO_API_KEY_* 다음 줄 PASS 등 오탐 방지).
  if ($text -match '(?m)^TILKO_API_KEY(?:_PROD|_DEMO)?=[^\r\n#]{8,}') {
    return "TILKO API 키가 APK dotenv 에 들어 있습니다."
  }
  if ($text -match '(?m)^GEMINI_API_KEY=[^\r\n#]{8,}') {
    return "GEMINI_API_KEY 가 APK dotenv 에 들어 있습니다."
  }
  if ($text -match '(?m)^PUBLIC_DATA_SERVICE_KEY=[^\r\n#]{16,}') {
    return "PUBLIC_DATA_SERVICE_KEY 가 APK dotenv 에 들어 있습니다."
  }
  return $null
}

# --- dotenv for this build ---
if (Test-Path -LiteralPath $assetDotenv) {
  Copy-Item -LiteralPath $assetDotenv -Destination $backupDotenv -Force
}

try {
  if ($PublicDotenvPath.Trim().Length -gt 0) {
    $src = Join-Path $ProjectRoot $PublicDotenvPath
    if (-not (Test-Path -LiteralPath $src)) {
      throw "PublicDotenvPath 없음: $src (dotenv.public.example 을 복사해 만드세요)"
    }
    Copy-Item -LiteralPath $src -Destination $assetDotenv -Force
  }

  if ($RemoteConfigUrl.Trim().Length -gt 0) {
    $raw = if (Test-Path -LiteralPath $assetDotenv) {
      [System.IO.File]::ReadAllText($assetDotenv, [System.Text.UTF8Encoding]::new($false))
    } else { "" }
    if ($raw -match '(?m)^LINK26_REMOTE_CONFIG_URL=.*$') {
      $raw = $raw -replace '(?m)^LINK26_REMOTE_CONFIG_URL=.*$', "LINK26_REMOTE_CONFIG_URL=$RemoteConfigUrl"
    } else {
      $raw = "$raw`nLINK26_REMOTE_CONFIG_URL=$RemoteConfigUrl`n"
    }
    [System.IO.File]::WriteAllText($assetDotenv, $raw.TrimEnd() + "`n", [System.Text.UTF8Encoding]::new($false))
  }

  if (-not (Test-Path -LiteralPath $assetDotenv)) {
    throw "assets/env/dotenv 없음. -PublicDotenvPath 또는 dotenv.public.example 복사 필요."
  }

  $dotenvText = [System.IO.File]::ReadAllText($assetDotenv, [System.Text.UTF8Encoding]::new($false))
  $unsafe = Test-DotenvLooksUnsafe $dotenvText
  if ($unsafe) {
    throw "공개 배포용 dotenv 검사 실패: $unsafe`n→ assets/env/dotenv.public.example 참고."
  }
  if ($RemoteConfigUrl.Trim().Length -eq 0 -and $ProductionBffUrl.Trim().Length -eq 0) {
    if ($dotenvText -notmatch 'LINK26_REMOTE_CONFIG_URL=https://') {
      Write-Warning "LINK26_REMOTE_CONFIG_URL(HTTPS) 또는 -ProductionBffUrl 이 없습니다. 다른 사용자는 BFF 에 연결되지 않을 수 있습니다."
    }
  }

  if (-not $SkipBuild) {
    $defines = @()
    if ($ProductionBffUrl.Trim().Length -gt 0) {
      $defines += "--dart-define=NHIS_PRODUCTION_BASE_URL=$ProductionBffUrl"
    }
    if ($RemoteConfigUrl.Trim().Length -gt 0) {
      $defines += "--dart-define=LINK26_REMOTE_CONFIG_URL=$RemoteConfigUrl"
    }
    $flutterw = Join-Path $ProjectRoot "flutterw.ps1"
    if ($defines.Count -gt 0) {
      & $flutterw build apk --release @defines
    } else {
      & $flutterw build apk --release
    }
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  }

  $releaseApk = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-release.apk"
  if (-not (Test-Path -LiteralPath $releaseApk)) {
    throw "APK 없음: $releaseApk (빌드 실패 또는 --SkipBuild)"
  }

  New-Item -ItemType Directory -Force -Path $distDir | Out-Null
  $distApk = Join-Path $distDir $apkName
  Copy-Item -LiteralPath $releaseApk -Destination $distApk -Force
  Copy-Item -LiteralPath $distApk -Destination (Join-Path $webDir $apkName) -Force

  Write-Host ""
  Write-Host ">>> 웹 업로드용 APK <<<" -ForegroundColor Green
  Write-Host "    $distApk"
  Write-Host "    (복사본) $webDir\$apkName"
  Write-Host ""
  Write-Host "웹 서버에 올릴 것:" -ForegroundColor Cyan
  Write-Host "  1) $webDir\index.html"
  Write-Host "  2) $webDir\$apkName"
  Write-Host "  3) link26-bff.json (예: tool/web_download/link26-bff.manifest.example.json)"
  Write-Host ""
}
finally {
  if (Test-Path -LiteralPath $backupDotenv) {
    Move-Item -LiteralPath $backupDotenv -Destination $assetDotenv -Force
    Write-Host "[build_web_distribution] assets/env/dotenv 로컬 백업 복구함." -ForegroundColor DarkGray
  }
}
