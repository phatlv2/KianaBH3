@echo off
echo Building KianaBH3 Release...
powershell -ExecutionPolicy Bypass -File "build-release.ps1" %*
pause
