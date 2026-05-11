# Android 빌드 도구(aapt 등)가 한글·특수문자 경로에서 APK를 열지 못할 때 사용합니다.
# 사용:  .\tool\run_with_ascii_path.ps1 run
#       .\tool\run_with_ascii_path.ps1 -CleanBuild run   # cleanMergeDebugAssets 잠금 시 build\ 비우기
#       .\tool\run_with_ascii_path.ps1 build apk
param(
  [switch] $CleanBuild,
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
  Write-Host "[Link26] Path is ASCII-only; running flutter as usual."
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

# 콘솔 인코딩 문제로 한글이 깨질 수 있어 SUBST 안내는 ASCII 문구로 출력합니다.
Write-Host "[Link26] Non-ASCII path: project mapped to ${drive}: (original folder unchanged)."
Write-Host "       $projectRoot"
cmd /c "subst ${drive}: `"$projectRoot`""
if ($LASTEXITCODE -ne 0) {
  Write-Error "subst failed (try running PowerShell as Administrator)."
  exit 1
}

# Gradle daemon / Java가 mergeDebugAssets 등을 잡고 있으면 cleanMergeDebugAssets에서 삭제 실패할 수 있음.
$gradleBat = Join-Path $projectRoot "android\gradlew.bat"
if (Test-Path -LiteralPath $gradleBat) {
  Write-Host "[Link26] Stopping Gradle daemons (releases locks under build\)..."
  Push-Location (Join-Path $projectRoot "android")
  try {
    & .\gradlew.bat --stop
  } catch {
    # gradlew 없거나 JDK 문제 시 무시하고 flutter 진행
  } finally {
    Pop-Location
  }
}

# 데몬 종료 직후에도 핸들이 남는 경우가 있어 잠시 대기한 뒤, 문제가 잦은 mergeDebugAssets만 실제 경로에서 비움(SUBST M:\ 와 동일 물리 폴더).
Start-Sleep -Milliseconds 900
function Remove-DirIfExists([string]$LiteralPath) {
  if (-not (Test-Path -LiteralPath $LiteralPath)) { return }
  Write-Host "[Link26] Removing locked-prone dir: $LiteralPath" -ForegroundColor DarkGray
  try { cmd.exe /c "attrib -r -s -h `"$LiteralPath\*`" /s /d" 2>$null | Out-Null } catch {}
  Remove-Item -LiteralPath $LiteralPath -Recurse -Force -ErrorAction SilentlyContinue
  if (Test-Path -LiteralPath $LiteralPath) {
    cmd.exe /c "rmdir /s /q `"$LiteralPath`"" 2>$null | Out-Null
  }
}
$mergeDebugAssets = Join-Path $projectRoot "build\app\intermediates\assets\debug\mergeDebugAssets"
Remove-DirIfExists $mergeDebugAssets
$mergeReleaseAssets = Join-Path $projectRoot "build\app\intermediates\assets\release\mergeReleaseAssets"
Remove-DirIfExists $mergeReleaseAssets

if ($CleanBuild) {
  Write-Host "[Link26] -CleanBuild: removing build\ (Gradle asset merge lock workaround)..." -ForegroundColor Cyan
  $buildDir = Join-Path $projectRoot "build"
  if (Test-Path -LiteralPath $buildDir) {
    $oldEa = $ErrorActionPreference
    try {
      $ErrorActionPreference = "SilentlyContinue"
      try {
        cmd.exe /c "attrib -r -s -h `"$buildDir\*`" /s /d" | Out-Null
      } catch {}
      Remove-Item -LiteralPath $buildDir -Recurse -Force -ErrorAction SilentlyContinue
      if (Test-Path -LiteralPath $buildDir) {
        try {
          cmd.exe /c "rmdir /s /q `"$buildDir`"" | Out-Null
        } catch {}
      }
    } finally {
      $ErrorActionPreference = $oldEa
    }
  }
  Start-Sleep -Milliseconds 400
}

$code = 1
try {
  Set-Location "${drive}:\"
  & flutter @FlutterArgs
  $code = $LASTEXITCODE
} finally {
  # SUBST 해제 전에 실제 프로젝트 폴더로 돌아가야, 다음에 PS L:\> 에서 tool 경로를 못 찾는 문제가 나지 않습니다.
  try {
    Set-Location -LiteralPath $projectRoot
  } catch {
    # ignore
  }
  cmd /c "subst ${drive}: /d" 2>$null | Out-Null
}

exit $code
