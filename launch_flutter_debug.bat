@echo off
cd /d "C:\Users\youcef cheriet\Desktop\MARCKETPLACE\marketplace\flutter_app"
echo Current directory: %CD%
echo.
echo Installing dependencies...
flutter pub get
if %ERRORLEVEL% neq 0 (
    echo ERROR: pub get failed with error code %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)
echo.
echo Dependencies installed successfully!
echo.
echo Available devices:
flutter devices
echo.
echo Launching the app on Chrome...
flutter run -d chrome --debug
pause