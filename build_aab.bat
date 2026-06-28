@echo off
echo Building Android App Bundle (AAB) for Google Play Store...
call flutter build appbundle --release

echo.
echo ========================================================
echo Done! Aapki AAB file is location par aa gayi hai:
echo C:\Users\user\Desktop\maacare\build\app\outputs\bundle\release\app-release.aab
echo ========================================================
pause
