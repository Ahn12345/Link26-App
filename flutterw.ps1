# Link26: project path contains Korean (e.g. ...\문서\...) — plain `flutter run` fails with:
#   aapt Illegal byte sequence / Failed to extract manifest from APK
# This script runs Flutter via SUBST (see tool\run_with_ascii_path.ps1).
#
# Examples:
#   .\flutterw.ps1 run
#   .\flutterw.ps1 run -d <deviceId>
#   .\flutterw.ps1 pub get
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

$ErrorActionPreference = "Stop"
$wrapper = Join-Path $PSScriptRoot "tool\run_with_ascii_path.ps1"
if ($FlutterArgs.Count -eq 0) {
  Write-Host @"
Usage: .\flutterw.ps1 <flutter arguments...>

Examples:
  .\flutterw.ps1 run
  .\flutterw.ps1 run -d <deviceId>
  .\flutterw.ps1 pub get

Do not use plain `flutter run` when the path has non-ASCII characters.
"@
  exit 2
}

& $wrapper @FlutterArgs
exit $LASTEXITCODE
