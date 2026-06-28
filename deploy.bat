@echo on
echo Starting MaaCare Deployment Diagnostic...
timeout /t 2

:: Step 1: Check tools
where flutter
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter not found!
    pause
    exit /b 1
)

where npm
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] NPM not found!
    pause
    exit /b 1
)

:: Step 2: Clean and Fetch
echo Running flutter clean...
call flutter clean

echo Running flutter pub get...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] pub get failed. This might be the symlink issue.
    echo Trying Web-Only workaround by clearing windows symlinks...
    if exist "windows\flutter\ephemeral\.plugin_symlinks" rmdir /s /q "windows\flutter\ephemeral\.plugin_symlinks"
    call flutter config --no-enable-windows-desktop
    call flutter clean
    call flutter pub get
    set WINDOWS_HIDDEN=true
    if %ERRORLEVEL% NEQ 0 (
        echo [FATAL] pub get failed even after workaround.
        call flutter config --enable-windows-desktop
        pause
        exit /b 1
    )
)

:: Step 3: Build
echo Building Flutter Web...
call flutter build web --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed!
    if defined WINDOWS_HIDDEN rename "windows_temp" "windows"
    pause
    exit /b 1
)

:: Restore
if defined WINDOWS_HIDDEN (
    call flutter config --enable-windows-desktop
    echo Restored windows config.
)

:: Step 4: Verify
if not exist "build\web\index.html" (
    echo [ERROR] build\web\index.html missing!
    pause
    exit /b 1
)

:: Step 5: Deploy
echo [5/5] Deploying build\web to Netlify...
set NETLIFY_SITE_URL=https://rainbow-granita-b4981d.netlify.app

call npx netlify deploy --dir=build/web --prod

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Deployment to Netlify failed.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo SUCCESS! Your app is now live at:
echo %NETLIFY_SITE_URL%
echo ==========================================
echo.
echo Press any key to exit.
pause >nul
endlocal





