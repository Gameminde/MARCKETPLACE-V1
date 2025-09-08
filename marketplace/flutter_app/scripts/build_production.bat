@echo off
setlocal enabledelayedexpansion

REM Production build script for marketplace app (Windows)
echo 🚀 Starting production build process...

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter is not installed or not in PATH
    exit /b 1
)

REM Clean previous builds
echo [INFO] Cleaning previous builds...
flutter clean
flutter pub get

REM Verify environment
echo [INFO] Verifying Flutter environment...
flutter doctor

REM Run code analysis
echo [INFO] Running code analysis...
flutter analyze
if errorlevel 1 (
    echo [ERROR] Code analysis failed. Please fix issues before building.
    exit /b 1
)

REM Run tests
echo [INFO] Running unit tests...
flutter test
if errorlevel 1 (
    echo [ERROR] Tests failed. Please fix failing tests before building.
    exit /b 1
)

REM Run widget tests
echo [INFO] Running widget tests...
flutter test test/widgets/
if errorlevel 1 (
    echo [WARNING] Widget tests failed, but continuing with build...
)

REM Run golden tests
echo [INFO] Running golden tests...
flutter test test/golden/
if errorlevel 1 (
    echo [WARNING] Golden tests failed, but continuing with build...
)

REM Generate app icons and splash screens
echo [INFO] Generating app icons and splash screens...
findstr /C:"flutter_launcher_icons" pubspec.yaml >nul 2>&1
if not errorlevel 1 (
    flutter pub run flutter_launcher_icons
)

findstr /C:"flutter_native_splash" pubspec.yaml >nul 2>&1
if not errorlevel 1 (
    flutter pub run flutter_native_splash:create
)

REM Build for Android
echo [INFO] Building Android APK (split by ABI)...
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols

echo [INFO] Building Android App Bundle...
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

REM Calculate APK sizes
echo [INFO] Calculating build sizes...
if exist "build\app\outputs\flutter-apk\" (
    for %%f in (build\app\outputs\flutter-apk\*.apk) do (
        echo [SUCCESS] APK built: %%~nxf
    )
)

if exist "build\app\outputs\bundle\release\app-release.aab" (
    echo [SUCCESS] App Bundle built: app-release.aab
)

REM Generate build report
echo [INFO] Generating build report...
echo # Marketplace App - Production Build Report > build_report.txt
echo Generated on: %date% %time% >> build_report.txt
echo. >> build_report.txt
echo ## Build Information >> build_report.txt
flutter --version | findstr "Flutter" >> build_report.txt
echo Build Type: Production Release >> build_report.txt
echo. >> build_report.txt
echo ## Android Builds >> build_report.txt
if exist "build\app\outputs\flutter-apk\" (
    echo ### APK Files >> build_report.txt
    for %%f in (build\app\outputs\flutter-apk\*.apk) do (
        echo - %%~nxf >> build_report.txt
    )
)
if exist "build\app\outputs\bundle\release\app-release.aab" (
    echo ### App Bundle >> build_report.txt
    echo - app-release.aab >> build_report.txt
)
echo. >> build_report.txt
echo ## Next Steps >> build_report.txt
echo 1. Test the builds on physical devices >> build_report.txt
echo 2. Upload to Google Play Console >> build_report.txt
echo 3. Submit for review >> build_report.txt

echo [SUCCESS] Build report generated: build_report.txt

REM Success message
echo.
echo [SUCCESS] 🎉 Production build completed successfully!
echo.
echo [INFO] 📊 Build artifacts:
echo    📱 Android APK: build\app\outputs\flutter-apk\
echo    📦 Android Bundle: build\app\outputs\bundle\release\
echo    📄 Build Report: build_report.txt
echo.

REM Offer to open build directory
set /p open_dir="Do you want to open the build directory? (y/n): "
if /i "%open_dir%"=="y" (
    start explorer "build\app\outputs\"
)

echo [SUCCESS] Production build process completed!
pause