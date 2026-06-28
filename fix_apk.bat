@echo off
echo ============================================================
echo  MaaCare APK Builder - Debug Mode
echo ============================================================

echo [1/6] Stopping background Gradle processes...
cd android
call gradlew --stop
cd ..

echo [2/6] Force deleting corrupted native build caches...
if exist "windows" rmdir /s /q "windows"
if exist "android\app\.cxx" (
    move /Y "android\app\.cxx" "android\app\.cxx_corrupt_%random%" >nul 2>&1
    rmdir /s /q "android\app\.cxx" >nul 2>&1
)
if exist "android\.gradle" rmdir /s /q "android\.gradle" >nul 2>&1
if exist "build" rmdir /s /q "build" >nul 2>&1

echo [3/6] Cleaning Flutter build cache...
call flutter clean

echo [4/6] Fetching updated dependencies...
call flutter pub get

echo [5/6] Building release APK... (This will take a few minutes)
echo We are saving the exact error logs so Antigravity can read them.
call flutter build apk --release > build_log.txt 2>&1

echo [6/6] Done! Check build_log.txt for results.
echo.
pause
