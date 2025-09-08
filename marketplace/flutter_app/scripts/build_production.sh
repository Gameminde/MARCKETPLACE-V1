#!/bin/bash

# Production build script for marketplace app
set -e

echo "🚀 Starting production build process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean
flutter pub get

# Verify environment
print_status "Verifying Flutter environment..."
flutter doctor

# Run code analysis
print_status "Running code analysis..."
flutter analyze
if [ $? -ne 0 ]; then
    print_error "Code analysis failed. Please fix issues before building."
    exit 1
fi

# Run tests
print_status "Running unit tests..."
flutter test
if [ $? -ne 0 ]; then
    print_error "Tests failed. Please fix failing tests before building."
    exit 1
fi

# Run widget tests
print_status "Running widget tests..."
flutter test test/widgets/
if [ $? -ne 0 ]; then
    print_warning "Widget tests failed, but continuing with build..."
fi

# Run golden tests
print_status "Running golden tests..."
flutter test test/golden/
if [ $? -ne 0 ]; then
    print_warning "Golden tests failed, but continuing with build..."
fi

# Generate app icons and splash screens
print_status "Generating app icons and splash screens..."
if grep -q "flutter_launcher_icons" pubspec.yaml; then
    flutter pub run flutter_launcher_icons
fi

if grep -q "flutter_native_splash" pubspec.yaml; then
    flutter pub run flutter_native_splash:create
fi

# Build for Android
print_status "Building Android APK (split by ABI)..."
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols

print_status "Building Android App Bundle..."
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Calculate APK sizes
print_status "Calculating build sizes..."
if [ -d "build/app/outputs/flutter-apk" ]; then
    for apk in build/app/outputs/flutter-apk/*.apk; do
        if [ -f "$apk" ]; then
            size=$(du -h "$apk" | cut -f1)
            print_success "APK size: $(basename "$apk") - $size"
        fi
    done
fi

if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    size=$(du -h "build/app/outputs/bundle/release/app-release.aab" | cut -f1)
    print_success "App Bundle size: $size"
fi

# Build for iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Building iOS..."
    flutter build ios --release --obfuscate --split-debug-info=build/ios/symbols
    
    # Archive for App Store (optional)
    read -p "Do you want to create iOS archive for App Store? (y/n): " create_archive
    if [ "$create_archive" = "y" ] || [ "$create_archive" = "Y" ]; then
        print_status "Creating iOS archive..."
        cd ios
        xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release archive -archivePath build/Runner.xcarchive
        cd ..
        print_success "iOS archive created at ios/build/Runner.xcarchive"
    fi
fi

# Generate build report
print_status "Generating build report..."
cat << EOF > build_report.txt
# Marketplace App - Production Build Report
Generated on: $(date)

## Build Information
- Flutter Version: $(flutter --version | head -n 1)
- Dart Version: $(dart --version | head -n 1)
- Build Type: Production Release

## Android Builds
EOF

if [ -d "build/app/outputs/flutter-apk" ]; then
    echo "### APK Files" >> build_report.txt
    for apk in build/app/outputs/flutter-apk/*.apk; do
        if [ -f "$apk" ]; then
            size=$(du -h "$apk" | cut -f1)
            echo "- $(basename "$apk"): $size" >> build_report.txt
        fi
    done
fi

if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    size=$(du -h "build/app/outputs/bundle/release/app-release.aab" | cut -f1)
    echo "### App Bundle" >> build_report.txt
    echo "- app-release.aab: $size" >> build_report.txt
fi

if [[ "$OSTYPE" == "darwin"* ]] && [ -d "build/ios" ]; then
    echo "## iOS Builds" >> build_report.txt
    echo "- iOS app built successfully" >> build_report.txt
    if [ -d "ios/build/Runner.xcarchive" ]; then
        echo "- iOS archive created" >> build_report.txt
    fi
fi

echo "" >> build_report.txt
echo "## Next Steps" >> build_report.txt
echo "1. Test the builds on physical devices" >> build_report.txt
echo "2. Upload to respective app stores" >> build_report.txt
echo "3. Submit for review" >> build_report.txt

print_success "Build report generated: build_report.txt"

# Success message
echo ""
print_success "🎉 Production build completed successfully!"
echo ""
print_status "📊 Build artifacts:"
echo "   📱 Android APK: build/app/outputs/flutter-apk/"
echo "   📦 Android Bundle: build/app/outputs/bundle/release/"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "   🍎 iOS Build: build/ios/"
    if [ -d "ios/build/Runner.xcarchive" ]; then
        echo "   📦 iOS Archive: ios/build/Runner.xcarchive"
    fi
fi
echo "   📄 Build Report: build_report.txt"
echo ""

# Offer to open build directory
read -p "Do you want to open the build directory? (y/n): " open_dir
if [ "$open_dir" = "y" ] || [ "$open_dir" = "Y" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open build/app/outputs/
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        xdg-open build/app/outputs/
    fi
fi

print_success "Production build process completed!"