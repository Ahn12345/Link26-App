# SUBST(L:)·`run_with_ascii_path.ps1` 빌드 후 남은 TMP/GRADLE 등으로 `flutter test` 가
# `PathNotFoundException: L:\` 에서 크래시하는 경우를 막고 테스트를 실행합니다.
#
# 사용:  .\tool\flutter_test_safe.ps1
#       .\tool\flutter_test_safe.ps1 test/widget_test.dart
#       .\tool\flutter_test_safe.ps1 test/bff_dotenv_line_scan_test.dart
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterTestArgs
)

$ErrorActionPreference = "Stop"
try {
  $utf8 = [System.Text.UTF8Encoding]::new($false)
  [Console]::OutputEncoding = $utf8
  $OutputEncoding = $utf8
  if ($PSVersionTable.PSVersion.Major -lt 7) {
    chcp 65001 | Out-Null
  }
} catch { }

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Clear-BrokenSubstEnvPaths {
  foreach ($name in @('GRADLE_USER_HOME', 'TMP', 'TEMP')) {
    $gh = [Environment]::GetEnvironmentVariable($name, 'Process')
    if ([string]::IsNullOrWhiteSpace($gh)) { continue }
    try {
      $root = [System.IO.Path]::GetPathRoot($gh.Trim())
      if ([string]::IsNullOrWhiteSpace($root)) { continue }
      $drive = $root.TrimEnd('\', '/')
      if ($drive.Length -eq 2 -and $drive[1] -eq ':') {
        if (-not (Test-Path "${drive}\")) {
          Remove-Item "Env:$name" -ErrorAction SilentlyContinue
        }
      }
    } catch {}
  }
}
Clear-BrokenSubstEnvPaths

# Flutter/Gradle 훅이 항상 존재하는 경로만 쓰도록 고정 (잔여 L:\ 방지)
$env:GRADLE_USER_HOME = Join-Path $env:USERPROFILE ".gradle"
$tmp = Join-Path $env:USERPROFILE "AppData\Local\Temp"
$env:TMP = $tmp
$env:TEMP = $tmp

# 이전 SUBST 빌드가 `.dart_tool/flutter_build` 안에 `L:\...` 경로를 남기면
# native_assets 훅이 그 경로를 만들려다 실패합니다 — 캐시만 비웁니다.
$flutterBuild = Join-Path $projectRoot ".dart_tool\flutter_build"
if (Test-Path -LiteralPath $flutterBuild) {
  Write-Host "[Link26] Removing .dart_tool/flutter_build (stale drive-letter cache)..." -ForegroundColor DarkGray
  Remove-Item -LiteralPath $flutterBuild -Recurse -Force -ErrorAction SilentlyContinue
}

Set-Location -LiteralPath $projectRoot
& flutter pub get
if ($null -eq $FlutterTestArgs -or $FlutterTestArgs.Count -eq 0) {
  & flutter test
} else {
  & flutter test @FlutterTestArgs
}
exit $LASTEXITCODE
