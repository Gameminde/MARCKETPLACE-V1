#!/bin/bash
echo "Building Flutter Android App..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build APK for debug
flutter build apk --debug

# Build APK for release
flutter build apk --release

echo "Build completed!"