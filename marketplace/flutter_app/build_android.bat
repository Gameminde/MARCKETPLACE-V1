@echo off
echo Building Flutter Android App...

REM Clean previous builds
flutter clean

REM Get dependencies
flutter pub get

REM Build APK for debug
flutter build apk --debug

REM Build APK for release
flutter build apk --release

echo Build completed!
pause