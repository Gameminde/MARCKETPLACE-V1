# Production Build Configuration and Optimization Guide

This document outlines the production build configuration, optimization settings, and deployment preparation for the marketplace Flutter application.

## 📋 Production Build Checklist

### ✅ Pre-Build Optimization
- [ ] Code obfuscation enabled
- [ ] Tree shaking configured
- [ ] Image assets optimized
- [ ] Bundle size analysis completed
- [ ] Performance profiling done
- [ ] Memory leak testing passed
- [ ] Security audit completed

### ✅ Build Configuration
- [ ] Production environment variables set
- [ ] API endpoints configured for production
- [ ] Analytics keys configured
- [ ] Crash reporting enabled
- [ ] App signing configured
- [ ] Flavor-specific builds set up

## 🔧 Build Settings Configuration

### Android Production Settings

#### build.gradle (app level)
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.marketplace.app"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
        multiDexEnabled true
        
        // Production optimization
        ndk.abiFilters 'arm64-v8a', 'armeabi-v7a'
        
        // Proguard configuration
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }

    buildTypes {
        release {
            // Enable code obfuscation
            minifyEnabled true
            shrinkResources true
            useProguard true
            
            // Signing configuration
            signingConfig signingConfigs.release
            
            // Build optimizations
            debuggable false
            jniDebuggable false
            renderscriptDebuggable false
            pseudoLocalesEnabled false
            zipAlignEnabled true
            
            // Performance optimizations
            crunchPngs true
            
            buildConfigField "String", "BASE_URL", '"https://api.marketplace.com/"'
            buildConfigField "boolean", "DEBUG_MODE", "false"
        }
        
        debug {
            minifyEnabled false
            debuggable true
            buildConfigField "String", "BASE_URL", '"https://dev-api.marketplace.com/"'
            buildConfigField "boolean", "DEBUG_MODE", "true"
        }
    }
    
    // Dependency size optimization
    packagingOptions {
        exclude 'META-INF/DEPENDENCIES'
        exclude 'META-INF/LICENSE'
        exclude 'META-INF/LICENSE.txt'
        exclude 'META-INF/NOTICE'
        exclude 'META-INF/NOTICE.txt'
    }
    
    // Split APKs by ABI
    splits {
        abi {
            enable true
            reset()
            include 'arm64-v8a', 'armeabi-v7a'
            universalApk true
        }
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
    
    // Production-only dependencies
    releaseImplementation 'com.facebook.flipper:flipper-noop:0.182.0'
    
    // Performance monitoring
    implementation 'com.google.firebase:firebase-perf:20.4.1'
    implementation 'com.google.firebase:firebase-crashlytics:18.4.3'
}
```

#### proguard-rules.pro
```proguard
# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Marketplace app specific
-keep class com.marketplace.** { *; }

# JSON serialization
-keepattributes *Annotation*
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Remove logging in production
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Optimize enums
-optimizations !code/simplification/enum

# Performance optimizations
-allowaccessmodification
-repackageclasses ''
```

### iOS Production Settings

#### ios/Flutter/Release.xcconfig
```xcconfig
#include "Generated.xcconfig"

// Flutter build mode
FLUTTER_BUILD_MODE=release

// iOS deployment target
IPHONEOS_DEPLOYMENT_TARGET=12.0

// Bitcode (optional, Apple deprecated but some services need it)
ENABLE_BITCODE=NO

// App Transport Security
ENABLE_ATS=YES

// Strip symbols for smaller binary
STRIP_INSTALLED_PRODUCT=YES
SYMBOLS_HIDDEN_BY_DEFAULT=YES

// Optimization level
GCC_OPTIMIZATION_LEVEL=s
SWIFT_OPTIMIZATION_LEVEL=-O

// Enable whole module optimization
SWIFT_WHOLE_MODULE_OPTIMIZATION=YES

// Dead code stripping
DEAD_CODE_STRIPPING=YES

// Link Time Optimization
LLVM_LTO=YES_THIN

// Remove debug symbols
GCC_GENERATE_DEBUGGING_SYMBOLS=NO
```

#### ios/Runner/Info.plist (Production additions)
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>marketplace.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
        </dict>
    </dict>
</dict>

<key>ITSAppUsesNonExemptEncryption</key>
<false/>

<key>NSCameraUsageDescription</key>
<string>This app uses camera for barcode scanning and product photos</string>

<key>NSMicrophoneUsageDescription</key>
<string>This app uses microphone for voice search functionality</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>This app uses location for delivery address suggestions</string>
```

## 🚀 Flutter Build Optimization

### pubspec.yaml Production Configuration
```yaml
name: marketplace
description: A comprehensive marketplace Flutter application
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.13.0"

# Production dependencies only
dependencies:
  flutter:
    sdk: flutter
  
  # Essential production packages
  cupertino_icons: ^1.0.6
  provider: ^6.1.1
  http: ^1.1.0
  shared_preferences: ^2.2.2
  cached_network_image: ^3.3.0
  
  # Performance monitoring (production only)
  firebase_crashlytics: ^3.4.8
  firebase_performance: ^0.9.3+6
  firebase_analytics: ^10.7.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  
  # Build optimization tools
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.3.6

flutter:
  uses-material-design: true
  
  # Optimized asset configuration
  assets:
    - assets/images/
    - assets/icons/
    - assets/fonts/
    - assets/animations/
  
  fonts:
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto-Regular.ttf
        - asset: assets/fonts/Roboto-Bold.ttf
          weight: 700

# App icon configuration
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 21
  
  # Adaptive icon for Android
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/adaptive_icon.png"

# Splash screen configuration
flutter_native_splash:
  color: "#FFFFFF"
  image: assets/images/splash_logo.png
  color_dark: "#000000"
  image_dark: assets/images/splash_logo_dark.png
  
  android_12:
    image: assets/images/splash_logo_android12.png
    icon_background_color: "#FFFFFF"
    image_dark: assets/images/splash_logo_android12_dark.png
    icon_background_color_dark: "#000000"
```

## 📱 Build Commands and Scripts

### Production Build Scripts

#### build_production.sh
```bash
#!/bin/bash

# Production build script for marketplace app
set -e

echo "🚀 Starting production build process..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Run code analysis
echo "🔍 Running code analysis..."
flutter analyze
if [ $? -ne 0 ]; then
    echo "❌ Code analysis failed. Please fix issues before building."
    exit 1
fi

# Run tests
echo "🧪 Running tests..."
flutter test
if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Please fix failing tests before building."
    exit 1
fi

# Generate app icons and splash screens
echo "🎨 Generating app icons and splash screens..."
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create

# Build for Android
echo "📱 Building Android APK..."
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols

echo "📱 Building Android App Bundle..."
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Build for iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Building iOS..."
    flutter build ios --release --obfuscate --split-debug-info=build/ios/symbols
    
    # Archive for App Store
    echo "📦 Creating iOS archive..."
    cd ios
    xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release archive -archivePath build/Runner.xcarchive
    cd ..
fi

echo "✅ Production build completed successfully!"
echo "📊 Build artifacts:"
echo "   - Android APK: build/app/outputs/flutter-apk/"
echo "   - Android Bundle: build/app/outputs/bundle/release/"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "   - iOS Archive: ios/build/Runner.xcarchive"
fi
```

#### build_production.bat (Windows)
```batch
@echo off
echo 🚀 Starting production build process...

REM Clean previous builds
echo 🧹 Cleaning previous builds...
flutter clean
flutter pub get

REM Run code analysis
echo 🔍 Running code analysis...
flutter analyze
if errorlevel 1 (
    echo ❌ Code analysis failed. Please fix issues before building.
    exit /b 1
)

REM Run tests
echo 🧪 Running tests...
flutter test
if errorlevel 1 (
    echo ❌ Tests failed. Please fix failing tests before building.
    exit /b 1
)

REM Generate app icons and splash screens
echo 🎨 Generating app icons and splash screens...
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create

REM Build for Android
echo 📱 Building Android APK...
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols

echo 📱 Building Android App Bundle...
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

echo ✅ Production build completed successfully!
echo 📊 Build artifacts:
echo    - Android APK: build/app/outputs/flutter-apk/
echo    - Android Bundle: build/app/outputs/bundle/release/
```

## 🔧 Performance Optimization Configuration

### Image Optimization
```yaml
# Asset optimization in pubspec.yaml
flutter:
  assets:
    - path: assets/images/
      # Automatically generates 1x, 2x, 3x variants
    - path: assets/images/2.0x/
    - path: assets/images/3.0x/
```

### Network Optimization
```dart
// lib/config/network_config.dart
class NetworkConfig {
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const bool enableCompression = true;
  
  // Production API endpoints
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.marketplace.com',
  );
  
  static const String cdnUrl = String.fromEnvironment(
    'CDN_URL',
    defaultValue: 'https://cdn.marketplace.com',
  );
}
```

### Memory Optimization
```dart
// lib/config/memory_config.dart
class MemoryConfig {
  // Image cache configuration
  static const int maxImageCacheSize = 100 * 1024 * 1024; // 100MB
  static const int maxImageCacheEntries = 1000;
  
  // List view optimization
  static const double itemExtent = 120.0;
  static const int cacheExtent = 10;
  
  // Dispose controllers and subscriptions
  static void optimizeMemoryUsage() {
    // Clear image cache periodically
    PaintingBinding.instance.imageCache.clear();
    
    // Force garbage collection
    // Note: Only use in development, not production
    if (kDebugMode) {
      // GC hint for debugging
    }
  }
}
```

## 📊 Bundle Size Analysis

### Analysis Commands
```bash
# Analyze Android bundle size
flutter build appbundle --analyze-size --target-platform android-arm64

# Analyze iOS bundle size
flutter build ios --analyze-size

# Detailed analysis with DevTools
dart devtools
```

### Size Optimization Strategies
1. **Tree Shaking**: Remove unused code
2. **Image Optimization**: Compress and optimize images
3. **Font Subsetting**: Include only required font glyphs
4. **Dependency Audit**: Remove unused dependencies
5. **Code Splitting**: Load features on demand

## 🔐 Security Configuration

### Network Security
```dart
// lib/config/security_config.dart
class SecurityConfig {
  // Certificate pinning
  static const List<String> pinnedCertificates = [
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
  ];
  
  // API security headers
  static const Map<String, String> securityHeaders = {
    'X-API-Key': String.fromEnvironment('API_KEY'),
    'User-Agent': 'MarketplaceApp/1.0.0',
  };
  
  // Encryption keys (stored securely)
  static const String encryptionKeyAlias = 'marketplace_key';
}
```

### Data Protection
```dart
// lib/config/data_protection.dart
class DataProtection {
  // Sensitive data encryption
  static Future<String> encryptSensitiveData(String data) async {
    // Implementation with flutter_secure_storage
    return data; // Placeholder
  }
  
  // Biometric authentication
  static Future<bool> authenticateUser() async {
    // Implementation with local_auth
    return true; // Placeholder
  }
}
```

## 📋 Environment Variables

### Production Environment (.env.production)
```env
# API Configuration
API_BASE_URL=https://api.marketplace.com
API_KEY=prod_api_key_here
CDN_URL=https://cdn.marketplace.com

# Analytics
FIREBASE_APP_ID=1:123456789:android:abcdef
GOOGLE_ANALYTICS_ID=G-XXXXXXXXXX
MIXPANEL_TOKEN=production_token

# Payment Gateways
STRIPE_PUBLISHABLE_KEY=pk_live_xxxxx
PAYPAL_CLIENT_ID=live_client_id

# Third-party Services
SENTRY_DSN=https://xxxxx@sentry.io/xxxxx
CRASHLYTICS_ENABLED=true
PERFORMANCE_MONITORING=true

# Feature Flags
ENABLE_SOCIAL_LOGIN=true
ENABLE_BIOMETRIC_AUTH=true
ENABLE_PUSH_NOTIFICATIONS=true
```

## 🚀 Deployment Readiness Checklist

### Pre-Deployment Verification
- [ ] All tests passing (unit, widget, integration, golden)
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] Accessibility testing passed
- [ ] Cross-platform compatibility verified
- [ ] App store guidelines compliance checked
- [ ] Privacy policy and terms updated
- [ ] Crash reporting configured and tested
- [ ] Analytics tracking verified
- [ ] Push notifications configured
- [ ] Deep linking tested
- [ ] Offline functionality verified
- [ ] Data backup and recovery tested

### Build Verification
- [ ] APK/IPA size within acceptable limits
- [ ] Installation and launch successful
- [ ] Core functionality working
- [ ] Performance metrics acceptable
- [ ] No debug code or logs in production
- [ ] Proper error handling for all scenarios
- [ ] Network failure handling tested
- [ ] Memory leaks checked
- [ ] Battery usage optimized

This comprehensive production configuration ensures optimal performance, security, and reliability for the marketplace Flutter application in production environments.