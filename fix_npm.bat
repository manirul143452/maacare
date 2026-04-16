@echo off
echo ==========================================
echo Fix npm ECOMPROMISED (Lock compromised)
echo ==========================================
echo.
echo 1. Cleaning npm cache...
call npm cache clean --force
echo.
echo 2. Deleting npx execution cache...
if exist "C:\Users\user\AppData\Local\npm-cache\_npx" (
    rd /s /q "C:\Users\user\AppData\Local\npm-cache\_npx"
    echo _npx cache deleted.
) else (
    echo _npx cache not found, skipping.
)
echo.
echo 3. Verifying npm state...
call npm cache verify
echo.
echo ==========================================
echo Cleanup complete. 
echo Please RESTART your AI IDE (Antigravity) now.
echo ==========================================
pause
