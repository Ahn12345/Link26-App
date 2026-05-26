# AI Studio 「키 복사」 후 클립보드 내용을 .env GEMINI_API_KEY 에 넣고 Google API 로 검증합니다.
# 사용:  AI Studio 에서 키 복사 →  .\tool\set_gemini_api_key.ps1
param(
  [string] $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $ProjectRoot

$key = (Get-Clipboard -Raw).Trim().Trim('"').Trim("'")
if ($key -match '\s') {
  $key = ($key -replace '\s+', '')
}

if ($key -notmatch '^AIza[0-9A-Za-z_-]{30,}$') {
  Write-Error @"
클립보드에 유효한 Gemini API 키가 없습니다.
1) https://aistudio.google.com/apikey
2) 「키 복사」 클릭 (스크린샷·수동 입력 금지)
3) 이 스크립트 다시 실행
현재 길이: $($key.Length)자 (보통 39자 전후)
"@
}

Write-Host "[Link26] Google API 키 검증 중..."
try {
  $uri = "https://generativelanguage.googleapis.com/v1beta/models?key=$([uri]::EscapeDataString($key))"
  $res = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 20
  if ($res.StatusCode -lt 200 -or $res.StatusCode -ge 300) {
    throw "HTTP $($res.StatusCode)"
  }
} catch {
  $body = ""
  if ($_.Exception.Response) {
    $sr = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
    $body = $sr.ReadToEnd()
  }
  if ($body -match 'leaked') {
    Write-Error "이 키는 유출로 차단되었습니다. AI Studio 에서 새 키를 발급하세요."
  }
  if ($body -match 'not valid') {
    Write-Error "Google 이 키를 거부했습니다(API key not valid). 「키 복사」로 다시 복사하세요."
  }
  Write-Error "키 검증 실패: $($_.Exception.Message)"
}

$envPath = Join-Path $ProjectRoot ".env"
if (-not (Test-Path -LiteralPath $envPath)) {
  Write-Error ".env 파일이 없습니다. .env.example 을 복사하세요."
}

$lines = [System.IO.File]::ReadAllLines($envPath)
$found = $false
for ($i = 0; $i -lt $lines.Length; $i++) {
  if ($lines[$i] -match '^\s*GEMINI_API_KEY\s*=') {
    $lines[$i] = "GEMINI_API_KEY=$key"
    $found = $true
    break
  }
}
if (-not $found) {
  $lines += "GEMINI_API_KEY=$key"
}

$utf8 = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllLines($envPath, $lines, $utf8)
Write-Host "[Link26] .env GEMINI_API_KEY 갱신 완료 (길이 $($key.Length)자, Google OK)"

& (Join-Path $PSScriptRoot "sync_dotenv_asset.ps1")
Write-Host "[Link26] 다음: .\tool\run_with_ascii_path.ps1 -CleanBuild build apk"
Write-Host "        .\tool\run_with_ascii_path.ps1 install -d <기기ID>"
