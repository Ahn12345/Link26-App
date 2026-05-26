# link26-frontend.vercel.app APK 다운로드 수정 — 업로드 번들 생성 + (선택) Vercel 배포
#
# 1) 프론트 repo 가 이 PC 에 있으면:
#      .\tool\publish_apk_vercel_frontend.ps1 -FrontendRepo "C:\path\to\link26-frontend"
# 2) 프론트 repo 없으면 — 생성된 zip 을 프론트 public/ 에 넣고 push:
#      .\tool\publish_apk_vercel_frontend.ps1
#      → tool\web_download\apk-vercel-upload.zip 압축 해제 후 public/ + vercel.json 반영

param(
  [string] $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string] $FrontendRepo = "",
  [string] $ApkPath = "",
  [switch] $DeployStaticOnly
)

$ErrorActionPreference = "Stop"
Set-Location $ProjectRoot

$distApk = Join-Path $ProjectRoot "dist\Link26-1.0.0.apk"
if ($ApkPath.Trim().Length -gt 0) {
  $distApk = Join-Path $ProjectRoot $ApkPath
}
if (-not (Test-Path -LiteralPath $distApk)) {
  throw "APK 없음: $distApk — 먼저 .\tool\build_web_distribution_apk.ps1 실행"
}

$bundleDir = Join-Path $ProjectRoot "tool\web_download\apk-vercel-bundle"
$zipPath = Join-Path $ProjectRoot "tool\web_download\apk-vercel-upload.zip"
$hostingDir = Join-Path $ProjectRoot "deploy\apk-hosting"

if (Test-Path -LiteralPath $bundleDir) {
  Remove-Item -LiteralPath $bundleDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $bundleDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $bundleDir "public") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $bundleDir "public\download") | Out-Null

Copy-Item -LiteralPath $distApk -Destination (Join-Path $bundleDir "public\Link26-1.0.0.apk") -Force
Copy-Item -LiteralPath (Join-Path $ProjectRoot "deploy\apk-hosting\link26-bff.json") `
  -Destination (Join-Path $bundleDir "public\link26-bff.json") -Force
Copy-Item -LiteralPath (Join-Path $ProjectRoot "tool\web_download\index.html") `
  -Destination (Join-Path $bundleDir "public\download\index.html") -Force
Copy-Item -LiteralPath (Join-Path $ProjectRoot "tool\web_download\vercel.json") `
  -Destination (Join-Path $bundleDir "vercel.json") -Force
Copy-Item -LiteralPath (Join-Path $ProjectRoot "tool\web_download\README-VERCEL-APK.txt") `
  -Destination (Join-Path $bundleDir "README-VERCEL-APK.txt") -Force

if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
Compress-Archive -Path (Join-Path $bundleDir "*") -DestinationPath $zipPath -Force

Copy-Item -LiteralPath $distApk -Destination (Join-Path $hostingDir "Link26-1.0.0.apk") -Force

Write-Host ""
Write-Host ">>> APK Vercel 업로드 번들 <<<" -ForegroundColor Green
Write-Host "    $zipPath"
Write-Host "    (압축 해제 → link26-frontend repo 루트에 public/ + vercel.json 반영 후 push)"
Write-Host ""

if ($FrontendRepo.Trim().Length -gt 0) {
  $fe = Resolve-Path $FrontendRepo
  $pub = Join-Path $fe "public"
  if (-not (Test-Path -LiteralPath $pub)) {
    New-Item -ItemType Directory -Force -Path $pub | Out-Null
  }
  Copy-Item -LiteralPath $distApk -Destination (Join-Path $pub "Link26-1.0.0.apk") -Force
  Copy-Item -LiteralPath (Join-Path $bundleDir "public\link26-bff.json") `
    -Destination (Join-Path $pub "link26-bff.json") -Force
  $feVercel = Join-Path $fe "vercel.json"
  Copy-Item -LiteralPath (Join-Path $bundleDir "vercel.json") -Destination $feVercel -Force
  Write-Host ">>> 프론트 repo 에 복사함 <<<" -ForegroundColor Green
  Write-Host "    $pub\Link26-1.0.0.apk"
  Write-Host "    $feVercel"
  Write-Host "    git add public vercel.json; commit; push; redeploy Vercel"
  Write-Host ""
}

if ($DeployStaticOnly) {
  Write-Host "Vercel static deploy..." -ForegroundColor Cyan
  Push-Location $hostingDir
  try {
    npx --yes vercel deploy --prod --yes 2>&1
  } finally {
    Pop-Location
  }
}
