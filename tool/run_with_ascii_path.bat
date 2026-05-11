@echo off
REM 한글 경로에서 flutter run / build 시 APK 도구 오류가 날 때 사용합니다.
setlocal
set "HERE=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%run_with_ascii_path.ps1" %*
