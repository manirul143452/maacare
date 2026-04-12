@echo off
title MaaCare Hard Restart
echo ==============================================
echo Force Restarting MaaCare App (Fixing Cache)...
echo ==============================================
echo Closing old hang instances so new code runs...
taskkill /F /IM dart.exe >nul 2>&1
taskkill /F /IM flutter.exe >nul 2>&1
taskkill /F /IM chrome.exe >nul 2>&1
echo ----------------------------------------------
echo Old App Memory Cleared!
echo Launching Fresh Database Connected Version...
echo Please wait 10-20 seconds for compilation...
echo ----------------------------------------------
flutter run -d chrome
pause
