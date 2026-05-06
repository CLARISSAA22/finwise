@echo off
cd /d "%~dp0"
echo ============================================
echo    FinWise - Fix Gradle Cache and Run
echo ============================================
echo.

echo [Step 1/4] Clearing corrupted Gradle transforms cache...
if exist "C:\Users\Admin\.gradle\caches\8.14\transforms" (
    rd /s /q "C:\Users\Admin\.gradle\caches\8.14\transforms"
    echo  Done! Gradle transforms cleared.
) else (
    echo  Nothing to clear, cache already clean.
)

echo.
echo [Step 2/4] Clearing Flutter build cache...
call flutter clean
echo  Done!

echo.
echo [Step 3/4] Getting dependencies...
call flutter pub get
echo  Done!

echo.
echo [Step 4/4] Building and running the app...
echo  NOTE: First build after cache clear takes 3-5 minutes. Please wait!
echo.
call flutter run

pause
