# 루트 `.env` 내용을 Flutter asset `assets/env/dotenv` 로 복사합니다.
# (OneDrive 등으로 `.env`가 리파싱 포인트일 때 Gradle copyFlutterAssetsDebug 스냅샷 오류 방지)
#
# 사용:  tool/run_with_ascii_path.ps1 / run_bff_and_flutter.ps1 에서 자동 호출
# 단독:  .\tool\sync_dotenv_asset.ps1
param(
  [string] $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
$dir = Join-Path $ProjectRoot "assets\env"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$dest = Join-Path $dir "dotenv"
$src = Join-Path $ProjectRoot ".env"

if (Test-Path -LiteralPath $src) {
  $bytes = [System.IO.File]::ReadAllBytes($src)
  $utf8 = [System.Text.UTF8Encoding]::new($false)
  try {
    $text = $utf8.GetString($bytes)
  } catch {
    $text = [System.Text.Encoding]::GetEncoding(949).GetString($bytes)
  }
  [System.IO.File]::WriteAllText($dest, $text, $utf8)
} else {
  if (-not (Test-Path -LiteralPath $dest)) {
    [System.IO.File]::WriteAllText(
      $dest,
      "# 프로젝트 루트에 .env 가 없습니다. .env.example 을 참고하세요.`n",
      [System.Text.UTF8Encoding]::new($false)
    )
  }
}
