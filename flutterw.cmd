@echo off
REM Wrapper for non-ASCII project paths (see flutterw.ps1).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0flutterw.ps1" %*
