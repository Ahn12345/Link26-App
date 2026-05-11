@echo off
setlocal EnableExtensions
cd /d "%~dp0\.."

rem Remove locked folders before flutter clean (Windows plugin_symlinks, etc.)
if exist "windows\flutter\ephemeral\.plugin_symlinks" rmdir /s /q "windows\flutter\ephemeral\.plugin_symlinks"
if exist "windows\flutter\ephemeral" rmdir /s /q "windows\flutter\ephemeral"
if exist ".dart_tool" rmdir /s /q ".dart_tool"
if exist "build" rmdir /s /q "build"

echo == flutter clean ==
call flutter clean
if errorlevel 1 exit /b 1

if exist "build" rmdir /s /q "build"
if exist "android\build" rmdir /s /q "android\build"
if exist "android\.gradle" rmdir /s /q "android\.gradle"

pushd android
call gradlew.bat --stop 2>nul
popd

echo == flutter pub get ==
call flutter pub get
if errorlevel 1 exit /b 1

echo == flutter run ==
if "%~1"=="" (
  call flutter run
) else (
  call flutter run -d %~1
)
