# link26-frontend.vercel.app APK download fix (web expects /link26.apk)
#
# 1) GitHub Pages: docs/link26.apk + push + enable Pages
# 2) link26-frontend repo: merge tool/web_download/vercel.json (redirect to Pages)
#
# Usage:
#   .\tool\enable_web_apk_download.ps1
#   .\tool\enable_web_apk_download.ps1 -FrontendRepo "C:\path\to\link26-frontend"

param(
  [string] $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string] $FrontendRepo = "",
  [switch] $SkipGitPush
)

$ErrorActionPreference = "Stop"
Set-Location $ProjectRoot

$srcApk = Join-Path $ProjectRoot "dist\Link26-1.0.0.apk"
if (-not (Test-Path -LiteralPath $srcApk)) {
  throw "dist\Link26-1.0.0.apk 없음 — .\tool\build_web_distribution_apk.ps1 먼저 실행"
}

$docsApk = Join-Path $ProjectRoot "docs\link26.apk"
Copy-Item -LiteralPath $srcApk -Destination $docsApk -Force

# LFS 사용 금지: Pages/raw 가 포인터 텍스트(~130B)를 .txt 처럼 내려줌
if (Get-Command git-lfs -ErrorAction SilentlyContinue) {
  git lfs untrack "docs/link26.apk" 2>$null | Out-Null
}
$toAdd = @(
  "-f", "docs/link26.apk",
  "docs/link26-bff.json", "docs/.nojekyll", ".gitattributes",
  ".github/workflows/deploy-apk-pages.yml",
  "tool/web_download/vercel.json", "tool/enable_web_apk_download.ps1",
  ".gitignore"
)
if (Test-Path (Join-Path $ProjectRoot ".github/workflows/release-apk.yml")) {
  $toAdd += ".github/workflows/release-apk.yml"
}
git add @toAdd 2>$null

if (-not $SkipGitPush) {
  $status = git status --porcelain
  if ($status) {
    git commit -m "fix(web): APK via GitHub Pages + Vercel redirect for link26.apk"
    git push origin main
    Write-Host "Pushed. GitHub Actions -> Pages deploy -> https://ahn12345.github.io/Link26-App/link26.apk" -ForegroundColor Green
  } else {
    Write-Host "Nothing to commit (already pushed?)" -ForegroundColor Yellow
  }
}

if ($FrontendRepo.Trim().Length -gt 0) {
  $fe = Resolve-Path $FrontendRepo
  Copy-Item (Join-Path $ProjectRoot "tool\web_download\vercel.json") (Join-Path $fe "vercel.json") -Force
  Copy-Item -LiteralPath $docsApk -Destination (Join-Path $fe "public\link26.apk") -Force
  Copy-Item (Join-Path $ProjectRoot "docs\link26-bff.json") (Join-Path $fe "public\link26-bff.json") -Force
  Write-Host "Frontend: $fe — vercel.json + public/link26.apk copied. git push then redeploy Vercel." -ForegroundColor Green
} else {
  Write-Host ""
  Write-Host "link26-frontend (private) repo on this PC:" -ForegroundColor Cyan
  Write-Host "  Copy tool\web_download\vercel.json -> vercel.json"
  Write-Host "  Copy docs\link26.apk -> public\link26.apk"
  Write-Host "  OR Vercel Dashboard -> Redirects:"
  Write-Host "    /link26.apk -> https://ahn12345.github.io/Link26-App/link26.apk"
  Write-Host ""
}

Write-Host "Direct APK (after Pages deploy): https://ahn12345.github.io/Link26-App/link26.apk" -ForegroundColor Green
Write-Host "Vercel (after redirect): https://link26-frontend.vercel.app/link26.apk" -ForegroundColor Green
