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
    echo Trying Web-Only workaround...
    if exist "windows" (
        rename "windows" "windows_temp"
        call flutter pub get
        set WINDOWS_HIDDEN=true
    )
    if %ERRORLEVEL% NEQ 0 (
        echo [FATAL] pub get failed even after workaround.
        if defined WINDOWS_HIDDEN rename "windows_temp" "windows"
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
    rename "windows_temp" "windows"
    echo Restored windows folder.
)

:: Step 4: Verify
if not exist "build\web\index.html" (
    echo [ERROR] build\web\index.html missing!
    pause
    exit /b 1
)

:: Step 5: Deploy
echo [5/5] Deploying build\web to InsForge...
set INSFORGE_PROJECT_ID=fd1bcdc3-5e9a-4b0a-9ddf-f36db358ed9d
set INSFORGE_API_KEY=ik_681e0acea5c4f9a7d6f8a524c4fc8fec
set INSFORGE_API_BASE_URL=https://96if48kf.ap-southeast.insforge.app

:: Linking (using environment variables)
echo Linking project...
call npx -y @insforge/cli@latest link --project-id %INSFORGE_PROJECT_ID%

:: Deploying (using environment variables)
echo Uploading build\web...
call npx -y @insforge/cli@latest deployments deploy build/web

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Deployment failed. 
    echo Checking if CLI needs login...
    echo Trying fallback with explicit directory only...
    call npx -y @insforge/cli@latest deployments deploy ./build/web
)

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Final deployment attempt failed.
    echo Please verify your Project ID and API Key.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo SUCCESS! Your app is now live at:
echo %INSFORGE_API_BASE_URL%
echo ==========================================
echo.
echo Press any key to exit.
pause >nul
endlocal





