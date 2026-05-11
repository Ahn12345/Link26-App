# Android 빌드 도구(aapt 등)가 한글·특수문자 경로에서 APK를 열지 못할 때 사용합니다.
# 사용:  .\tool\run_with_ascii_path.ps1 run
#       .\tool\run_with_ascii_path.ps1 build apk
#       .\tool\run_with_ascii_path.ps1 doctor
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Test-ContainsNonAscii([string]$s) {
  foreach ($ch in $s.ToCharArray()) {
    if ([int][char]$ch -gt 127) { return $true }
  }
  return $false
}

if (-not (Test-ContainsNonAscii $projectRoot)) {
  Write-Host "[Link26] 경로에 비ASCII 문자가 없습니다. flutter를 그대로 실행합니다."
  Set-Location $projectRoot
  & flutter @FlutterArgs
  exit $LASTEXITCODE
}

$drive = $null
foreach ($c in 76..90) {
  $letter = [string][char]$c
  if (-not (Test-Path "${letter}:\")) {
    $drive = $letter
    break
  }
}
if ($null -eq $drive) {
  Write-Error "SUBST에 쓸 빈 드라이브 문자(L:~Z:)가 없습니다."
  exit 1
}

Write-Host "[Link26] 비ASCII 경로 감지: 프로젝트를 ${drive}: 드라이브에 연결합니다."
Write-Host "       원본: $projectRoot"
cmd /c "subst ${drive}: `"$projectRoot`""
if ($LASTEXITCODE -ne 0) {
  Write-Error "subst 실패. 관리자 권한이 필요한 경우가 있습니다."
  exit 1
}

try {
  Set-Location "${drive}:\"
  & flutter @FlutterArgs
  $code = $LASTEXITCODE
} finally {
  cmd /c "subst ${drive}: /d" 2>$null | Out-Null
}

exit $code
