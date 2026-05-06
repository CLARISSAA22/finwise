@echo off
echo Extracting base64 image from logo.svg...
python extract_logo.py
if %errorlevel% neq 0 (
    echo Extraction failed.
    pause
    exit /b %errorlevel%
)
echo Running flutter pub get...
call flutter pub get
echo Generating app icons...
call flutter pub run flutter_launcher_icons
echo Done! Please restart your Android emulator / rebuild the app to see the new logo.
pause
