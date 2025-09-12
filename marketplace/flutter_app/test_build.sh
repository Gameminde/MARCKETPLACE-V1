#!/bin/bash

echo "🚀 Testing Flutter App Build - Marketplace Algeria"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed${NC}"
    echo "Please install Flutter first: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo -e "${GREEN}✅ Flutter found${NC}"
flutter --version
echo ""

# Navigate to Flutter app directory
cd /workspace/marketplace/flutter_app

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
flutter clean
echo ""

# Get dependencies
echo -e "${YELLOW}📦 Getting dependencies...${NC}"
flutter pub get
echo ""

# Run Flutter analyze
echo -e "${YELLOW}🔍 Running Flutter analyze...${NC}"
flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1 | tee analyze_output.txt

# Count errors
ERROR_COUNT=$(grep -c "error •" analyze_output.txt 2>/dev/null || echo "0")
WARNING_COUNT=$(grep -c "warning •" analyze_output.txt 2>/dev/null || echo "0")
INFO_COUNT=$(grep -c "info •" analyze_output.txt 2>/dev/null || echo "0")

echo ""
echo "📊 Analysis Results:"
echo "===================="
echo -e "Errors:   ${RED}$ERROR_COUNT${NC}"
echo -e "Warnings: ${YELLOW}$WARNING_COUNT${NC}"
echo -e "Info:     $INFO_COUNT"
echo ""

# Try to build APK
echo -e "${YELLOW}🏗️ Attempting to build debug APK...${NC}"
flutter build apk --debug 2>&1 | tee build_output.txt

# Check if build was successful
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    echo ""
    echo -e "${GREEN}✅ BUILD SUCCESSFUL!${NC}"
    echo ""
    
    # Get APK size
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-debug.apk | cut -f1)
    echo "📱 APK Details:"
    echo "=============="
    echo "Location: build/app/outputs/flutter-apk/app-debug.apk"
    echo "Size: $APK_SIZE"
    echo ""
    
    # Generate success report
    cat > BUILD_SUCCESS_REPORT.md << EOF
# ✅ BUILD SUCCESS REPORT
## Marketplace Algeria Flutter App

### Build Information
- **Date**: $(date)
- **Type**: Debug APK
- **Size**: $APK_SIZE
- **Location**: build/app/outputs/flutter-apk/app-debug.apk

### Analysis Results
- **Errors**: $ERROR_COUNT
- **Warnings**: $WARNING_COUNT
- **Info**: $INFO_COUNT

### Next Steps
1. Install APK on Android device/emulator
2. Test core functionality
3. Fix remaining errors/warnings
4. Build release APK

### Installation Command
\`\`\`bash
adb install build/app/outputs/flutter-apk/app-debug.apk
\`\`\`
EOF
    
    echo -e "${GREEN}📄 Success report saved to BUILD_SUCCESS_REPORT.md${NC}"
    
else
    echo ""
    echo -e "${RED}❌ BUILD FAILED${NC}"
    echo ""
    echo "Please check build_output.txt for errors"
    
    # Extract key errors
    echo "🔍 Key Build Errors:"
    echo "==================="
    grep -A 2 "FAILURE:" build_output.txt 2>/dev/null || echo "No specific failure message found"
    grep -A 2 "error:" build_output.txt 2>/dev/null | head -20
fi

echo ""
echo "📋 Full logs saved to:"
echo "  - analyze_output.txt (Flutter analyze results)"
echo "  - build_output.txt (Build process log)"
echo ""
echo "Done!"
