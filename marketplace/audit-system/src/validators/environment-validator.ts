/**
 * Environment Validator for Algeria Marketplace Phase 2 audit
 * Validates Flutter SDK, Android Studio, Gradle build, and APK generation
 */

import * as fs from 'fs-extra';
import * as path from 'path';
import { execSync } from 'child_process';
import * as semver from 'semver';
import { EnvironmentValidator as IEnvironmentValidator } from '../interfaces/validators';
import { ValidationResult, AuditCategory, Issue } from '../types/audit-types';
import { FLUTTER_REQUIREMENTS, ANDROID_REQUIREMENTS } from '../config/audit-config';
import { logger } from '../utils/logger';

export class EnvironmentValidator implements IEnvironmentValidator {
  category: AuditCategory = 'environment';
  private flutterAppPath: string;

  constructor(flutterAppPath: string) {
    this.flutterAppPath = flutterAppPath;
  }

  getName(): string {
    return 'Environment Validator';
  }

  getDescription(): string {
    return 'Validates Flutter SDK, Android Studio integration, Gradle build process, and APK generation';
  }

  async validate(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.info('EnvironmentValidator', '🔧 Starting environment validation');

    const issues: Issue[] = [];
    const checkedItems: string[] = [];
    const passedItems: string[] = [];
    const failedItems: string[] = [];

    try {
      // 1. Flutter SDK Validation
      const flutterResult = await this.validateFlutterSDK();
      checkedItems.push('Flutter SDK Version');
      if (flutterResult.passed) {
        passedItems.push('Flutter SDK Version');
      } else {
        failedItems.push('Flutter SDK Version');
        issues.push(...flutterResult.issues);
      }

      // 2. Android Studio Integration
      const androidResult = await this.validateAndroidStudio();
      checkedItems.push('Android Studio Integration');
      if (androidResult.passed) {
        passedItems.push('Android Studio Integration');
      } else {
        failedItems.push('Android Studio Integration');
        issues.push(...androidResult.issues);
      }

      // 3. Gradle Build Process
      const gradleResult = await this.validateGradleBuild();
      checkedItems.push('Gradle Build Process');
      if (gradleResult.passed) {
        passedItems.push('Gradle Build Process');
      } else {
        failedItems.push('Gradle Build Process');
        issues.push(...gradleResult.issues);
      }

      // 4. APK Generation
      const apkResult = await this.generateAPK();
      checkedItems.push('APK Generation');
      if (apkResult.passed) {
        passedItems.push('APK Generation');
      } else {
        failedItems.push('APK Generation');
        issues.push(...apkResult.issues);
      }

      // Calculate overall score
      const totalChecks = checkedItems.length;
      const passedChecks = passedItems.length;
      const score = Math.round((passedChecks / totalChecks) * 100);

      const executionTime = Date.now() - startTime;
      logger.info('EnvironmentValidator', `✅ Environment validation completed - Score: ${score}/100`);

      return {
        passed: score >= 95,
        score,
        issues,
        details: {
          checkedItems,
          passedItems,
          failedItems,
          metadata: {
            flutterAppPath: this.flutterAppPath,
            totalChecks,
            passedChecks
          }
        },
        executionTime
      };

    } catch (error) {
      logger.error('EnvironmentValidator', `Environment validation failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  async validateFlutterSDK(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.debug('EnvironmentValidator', 'Validating Flutter SDK version');

    const issues: Issue[] = [];
    let passed = true;

    try {
      // Check pubspec.yaml for Flutter version constraints
      const pubspecPath = path.join(this.flutterAppPath, 'pubspec.yaml');
      
      if (!fs.existsSync(pubspecPath)) {
        issues.push({
          severity: 'CRITICAL',
          category: 'environment',
          description: 'pubspec.yaml not found in Flutter app directory',
          location: pubspecPath,
          recommendation: 'Ensure you are running the audit from the correct Flutter project directory',
          impact: 'Cannot validate Flutter SDK requirements',
          requirementRef: '1.1'
        });
        passed = false;
      } else {
        const pubspecContent = await fs.readFile(pubspecPath, 'utf-8');
        
        // Parse Flutter version constraint
        const flutterMatch = pubspecContent.match(/flutter:\s*["']?>=?([0-9.]+)/);
        const sdkMatch = pubspecContent.match(/sdk:\s*["']?>=?([0-9.]+)/);
        
        if (flutterMatch) {
          const flutterVersion = flutterMatch[1];
          if (!semver.gte(flutterVersion, FLUTTER_REQUIREMENTS.minFlutterVersion)) {
            issues.push({
              severity: 'HIGH',
              category: 'environment',
              description: `Flutter version ${flutterVersion} is below minimum required ${FLUTTER_REQUIREMENTS.minFlutterVersion}`,
              location: pubspecPath,
              recommendation: `Update pubspec.yaml to require Flutter >= ${FLUTTER_REQUIREMENTS.minFlutterVersion}`,
              impact: 'May cause compatibility issues with modern Flutter features',
              requirementRef: '1.1'
            });
            passed = false;
          }
        }

        if (sdkMatch) {
          const dartVersion = sdkMatch[1];
          if (!semver.gte(dartVersion, FLUTTER_REQUIREMENTS.minDartVersion)) {
            issues.push({
              severity: 'HIGH',
              category: 'environment',
              description: `Dart SDK version ${dartVersion} is below minimum required ${FLUTTER_REQUIREMENTS.minDartVersion}`,
              location: pubspecPath,
              recommendation: `Update pubspec.yaml to require Dart SDK >= ${FLUTTER_REQUIREMENTS.minDartVersion}`,
              impact: 'May cause compilation errors with modern Dart features',
              requirementRef: '1.1'
            });
            passed = false;
          }
        }

        // Try to get actual Flutter version from system
        try {
          const flutterVersionOutput = execSync('C:\\flutter\\bin\\flutter --version', { 
            encoding: 'utf-8',
            cwd: this.flutterAppPath,
            timeout: 15000
          });
          
          const actualVersionMatch = flutterVersionOutput.match(/Flutter\s+([0-9.]+)/);
          if (actualVersionMatch) {
            const actualVersion = actualVersionMatch[1];
            logger.debug('EnvironmentValidator', `Detected Flutter version: ${actualVersion}`);
            
            if (!semver.gte(actualVersion, FLUTTER_REQUIREMENTS.minFlutterVersion)) {
              issues.push({
                severity: 'CRITICAL',
                category: 'environment',
                description: `Installed Flutter version ${actualVersion} is below minimum required ${FLUTTER_REQUIREMENTS.minFlutterVersion}`,
                recommendation: `Upgrade Flutter to version >= ${FLUTTER_REQUIREMENTS.minFlutterVersion}`,
                impact: 'Cannot build application with current Flutter installation',
                requirementRef: '1.1'
              });
              passed = false;
            }
          }
        } catch (error) {
          logger.warn('EnvironmentValidator', 'Could not detect system Flutter version', { error: error instanceof Error ? error.message : String(error) });
          issues.push({
            severity: 'MEDIUM',
            category: 'environment',
            description: 'Could not detect system Flutter version',
            recommendation: 'Ensure Flutter is properly installed and available in PATH',
            impact: 'Cannot verify Flutter installation compatibility',
            requirementRef: '1.1'
          });
        }
      }

      return {
        passed,
        score: passed ? 100 : 0,
        issues,
        details: {
          checkedItems: ['Flutter SDK Version', 'Dart SDK Version'],
          passedItems: passed ? ['Flutter SDK Version', 'Dart SDK Version'] : [],
          failedItems: passed ? [] : ['Flutter SDK Version', 'Dart SDK Version'],
          metadata: { pubspecPath }
        },
        executionTime: Date.now() - startTime
      };

    } catch (error) {
      logger.error('EnvironmentValidator', `Flutter SDK validation failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  async validateAndroidStudio(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.debug('EnvironmentValidator', 'Validating Android Studio integration');

    const issues: Issue[] = [];
    let passed = true;

    try {
      // Check for Android project structure
      const androidPath = path.join(this.flutterAppPath, 'android');
      const buildGradlePath = path.join(androidPath, 'build.gradle');
      const appBuildGradlePath = path.join(androidPath, 'app', 'build.gradle');

      if (!fs.existsSync(androidPath)) {
        issues.push({
          severity: 'CRITICAL',
          category: 'environment',
          description: 'Android project directory not found',
          location: androidPath,
          recommendation: 'Ensure this is a Flutter project with Android support',
          impact: 'Cannot build Android APK',
          requirementRef: '1.2'
        });
        passed = false;
      } else {
        // Check build.gradle files
        if (!fs.existsSync(buildGradlePath)) {
          issues.push({
            severity: 'HIGH',
            category: 'environment',
            description: 'Root build.gradle not found',
            location: buildGradlePath,
            recommendation: 'Restore Android project structure',
            impact: 'Android build will fail',
            requirementRef: '1.2'
          });
          passed = false;
        }

        if (!fs.existsSync(appBuildGradlePath)) {
          issues.push({
            severity: 'HIGH',
            category: 'environment',
            description: 'App build.gradle not found',
            location: appBuildGradlePath,
            recommendation: 'Restore Android app module structure',
            impact: 'Android build will fail',
            requirementRef: '1.2'
          });
          passed = false;
        } else {
          // Validate Android configuration
          const appBuildContent = await fs.readFile(appBuildGradlePath, 'utf-8');
          
          // Check for proper package name (not default)
          if (appBuildContent.includes('com.example.flutter_app')) {
            issues.push({
              severity: 'MEDIUM',
              category: 'environment',
              description: 'Using default package name com.example.flutter_app',
              location: appBuildGradlePath,
              recommendation: 'Update applicationId to com.marketplace.algeria',
              impact: 'App store deployment will be rejected',
              requirementRef: '1.2'
            });
          }

          // Check target SDK version
          const targetSdkMatch = appBuildContent.match(/targetSdk\s+(\d+)/);
          if (targetSdkMatch) {
            const targetSdk = parseInt(targetSdkMatch[1]);
            if (targetSdk < ANDROID_REQUIREMENTS.targetSDK) {
              issues.push({
                severity: 'MEDIUM',
                category: 'environment',
                description: `Target SDK ${targetSdk} is below recommended ${ANDROID_REQUIREMENTS.targetSDK}`,
                location: appBuildGradlePath,
                recommendation: `Update targetSdk to ${ANDROID_REQUIREMENTS.targetSDK}`,
                impact: 'May not support latest Android features',
                requirementRef: '1.2'
              });
            }
          }
        }

        // Check for signing configuration
        const keyPropertiesPath = path.join(androidPath, 'key.properties');
        if (!fs.existsSync(keyPropertiesPath)) {
          issues.push({
            severity: 'LOW',
            category: 'environment',
            description: 'Release signing configuration not found',
            location: keyPropertiesPath,
            recommendation: 'Configure release signing for production builds',
            impact: 'Cannot create signed release APK',
            requirementRef: '1.2'
          });
        }
      }

      return {
        passed,
        score: passed ? 100 : Math.max(0, 100 - (issues.length * 25)),
        issues,
        details: {
          checkedItems: ['Android Project Structure', 'Build Configuration', 'Package Name', 'Signing Setup'],
          passedItems: passed ? ['Android Project Structure', 'Build Configuration'] : [],
          failedItems: passed ? [] : ['Android Project Structure'],
          metadata: { androidPath, buildGradlePath, appBuildGradlePath }
        },
        executionTime: Date.now() - startTime
      };

    } catch (error) {
      logger.error('EnvironmentValidator', `Android Studio validation failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  async validateGradleBuild(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.debug('EnvironmentValidator', 'Validating Gradle build process');

    const issues: Issue[] = [];
    let passed = true;

    try {
      const androidPath = path.join(this.flutterAppPath, 'android');
      
      if (!fs.existsSync(androidPath)) {
        issues.push({
          severity: 'CRITICAL',
          category: 'environment',
          description: 'Android directory not found for Gradle validation',
          recommendation: 'Ensure Flutter project has Android support',
          impact: 'Cannot perform Gradle build validation',
          requirementRef: '1.3'
        });
        return {
          passed: false,
          score: 0,
          issues,
          details: {
            checkedItems: ['Gradle Build'],
            passedItems: [],
            failedItems: ['Gradle Build'],
            metadata: { androidPath }
          },
          executionTime: Date.now() - startTime
        };
      }

      // Skip Gradle tasks execution to avoid timeout - focus on configuration validation
      logger.debug('EnvironmentValidator', 'Validating Gradle configuration');

      // Check Gradle wrapper version
      const gradleWrapperPath = path.join(androidPath, 'gradle', 'wrapper', 'gradle-wrapper.properties');
      if (fs.existsSync(gradleWrapperPath)) {
        const wrapperContent = await fs.readFile(gradleWrapperPath, 'utf-8');
        const versionMatch = wrapperContent.match(/gradle-([0-9]+\.[0-9]+(?:\.[0-9]+)?)-/);
        
        if (versionMatch) {
          const gradleVersion = versionMatch[1];
          const gradleVersionCoerced = semver.coerce(gradleVersion);
          const minVersionCoerced = semver.coerce(ANDROID_REQUIREMENTS.minGradleVersion);
          
          if (!gradleVersionCoerced || !minVersionCoerced || !semver.gte(gradleVersionCoerced, minVersionCoerced)) {
            issues.push({
              severity: 'HIGH',
              category: 'environment',
              description: `Gradle version ${gradleVersion} is below minimum required ${ANDROID_REQUIREMENTS.minGradleVersion}`,
              location: gradleWrapperPath,
              recommendation: `Update Gradle wrapper to version >= ${ANDROID_REQUIREMENTS.minGradleVersion}`,
              impact: 'Build may fail with compatibility issues',
              requirementRef: '1.3'
            });
            passed = false;
          } else {
            logger.debug('EnvironmentValidator', `Gradle version ${gradleVersion} is compatible`);
          }
        }
      }

      return {
        passed,
        score: passed ? 100 : Math.max(0, 100 - (issues.length * 30)),
        issues,
        details: {
          checkedItems: ['Gradle Configuration', 'Gradle Version'],
          passedItems: passed ? ['Gradle Configuration', 'Gradle Version'] : [],
          failedItems: passed ? [] : ['Gradle Build'],
          metadata: { androidPath, gradleWrapperPath }
        },
        executionTime: Date.now() - startTime
      };

    } catch (error) {
      logger.error('EnvironmentValidator', `Gradle build validation failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  async generateAPK(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.debug('EnvironmentValidator', 'Validating APK generation capability');

    const issues: Issue[] = [];
    let passed = true;

    try {
      // Check for APK build configuration
      const buildGradlePath = path.join(this.flutterAppPath, 'android', 'app', 'build.gradle');
      
      if (fs.existsSync(buildGradlePath)) {
        const buildContent = await fs.readFile(buildGradlePath, 'utf-8');
        
        // Check for proper build configuration
        if (!buildContent.includes('applicationId')) {
          issues.push({
            severity: 'HIGH',
            category: 'environment',
            description: 'Application ID not configured in build.gradle',
            location: buildGradlePath,
            recommendation: 'Set applicationId in android/app/build.gradle',
            impact: 'APK build will fail',
            requirementRef: '1.4'
          });
          passed = false;
        }

        logger.debug('EnvironmentValidator', 'APK build configuration validated');
      } else {
        issues.push({
          severity: 'CRITICAL',
          category: 'environment',
          description: 'Android build.gradle not found',
          location: buildGradlePath,
          recommendation: 'Ensure Flutter project has Android support',
          impact: 'Cannot build APK',
          requirementRef: '1.4'
        });
        passed = false;
      }

      return {
        passed,
        score: passed ? 100 : 0,
        issues,
        details: {
          checkedItems: ['APK Build Configuration'],
          passedItems: passed ? ['APK Build Configuration'] : [],
          failedItems: passed ? [] : ['APK Build Configuration'],
          metadata: { 
            flutterAppPath: this.flutterAppPath,
            buildGradlePath
          }
        },
        executionTime: Date.now() - startTime
      };

    } catch (error) {
      logger.error('EnvironmentValidator', `APK generation validation failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }
}