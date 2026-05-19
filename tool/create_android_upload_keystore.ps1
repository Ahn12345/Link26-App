# Play Console 업로드용 release keystore + android/key.properties 생성
# 사용: .\tool\create_android_upload_keystore.ps1
# 비밀번호는 android\upload-keystore.credentials.txt 에 저장됩니다(git 제외).

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$androidDir = Join-Path $projectRoot "android"
$keystorePath = Join-Path $androidDir "upload-keystore.jks"
$keyPropsPath = Join-Path $androidDir "key.properties"
$credsPath = Join-Path $androidDir "upload-keystore.credentials.txt"

if (Test-Path -LiteralPath $keystorePath) {
  Write-Host "Removing existing keystore (Play 미업로드 시에만 재생성)."
  Remove-Item -LiteralPath $keystorePath -Force
}
if (Test-Path -LiteralPath $keyPropsPath) { Remove-Item -LiteralPath $keyPropsPath -Force }
if (Test-Path -LiteralPath $credsPath) { Remove-Item -LiteralPath $credsPath -Force }

$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
  Write-Error "keytool not found. Install JDK (Android Studio bundles one) and ensure keytool is on PATH."
}

function New-RandomPassword([int]$Length = 24) {
  # Java .properties 에서 # ! 등은 주석/이스케이프 — 영숫자만 사용
  $chars = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'
  $bytes = New-Object byte[] $Length
  [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
}

$storePass = New-RandomPassword
$keyPass = New-RandomPassword
$alias = "upload"
$dname = "CN=Link26, OU=Mobile, O=Link26, L=Seoul, ST=Seoul, C=KR"

Write-Host "Creating upload keystore at $keystorePath ..."
& keytool -genkeypair -v `
  -keystore $keystorePath `
  -storetype JKS `
  -storepass $storePass `
  -alias $alias `
  -keypass $keyPass `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -dname $dname

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

@"
storePassword=$storePass
keyPassword=$keyPass
keyAlias=$alias
storeFile=upload-keystore.jks
"@ | Out-File -FilePath $keyPropsPath -Encoding ascii -NoNewline
Add-Content -Path $keyPropsPath -Value "" -Encoding ascii

@"
Link26 Android upload keystore — BACK UP THIS FILE OFFLINE
Generated: $(Get-Date -Format o)
Keystore: android\upload-keystore.jks
Alias: $alias
storePassword=$storePass
keyPassword=$keyPass

Play Console requires the SAME key for all future app updates.
"@ | Out-File -FilePath $credsPath -Encoding utf8

Write-Host ""
Write-Host "Done."
Write-Host "  Keystore: $keystorePath"
Write-Host "  key.properties: $keyPropsPath"
Write-Host "  Credentials (backup!): $credsPath"
Write-Host ""
Write-Host "Build AAB:  .\flutterw.ps1 build appbundle --release"
