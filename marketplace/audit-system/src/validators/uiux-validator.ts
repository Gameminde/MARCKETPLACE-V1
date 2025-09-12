/**
 * UI/UX Validator for Algeria Marketplace Phase 2 audit
 * Validates Algeria design standards and accessibility compliance
 */

import * as fs from 'fs-extra';
import * as path from 'path';
import { UIUXValidator as IUIUXValidator } from '../interfaces/validators';
import { ValidationResult, AuditCategory, Issue } from '../types/audit-types';
import { AUDIT_CONFIG } from '../config/audit-config';
import { logger } from '../utils/logger';

export class UIUXValidator implements IUIUXValidator {
  category: AuditCategory = 'uiux';
  private flutterAppPath: string;

  constructor(flutterAppPath: string) {
    this.flutterAppPath = flutterAppPath;
  }

  getName(): string {
    return 'UI/UX Validator';
  }

  getDescription(): string {
    return 'Algeria design standards and accessibility compliance validation';
  }

  async validate(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.info('UIUXValidator', '🇩🇿 Starting Algeria UI/UX compliance validation');

    const issues: Issue[] = [];
    const checkedItems: string[] = [];
    const passedItems: string[] = [];
    const failedItems: string[] = [];

    try {
      // 1. Color Palette Validation
      const colorResult = await this.validateColorPalette();
      checkedItems.push('Algeria Color Palette');
      if (colorResult.passed) {
        passedItems.push('Algeria Color Palette');
      } else {
        failedItems.push('Algeria Color Palette');
        issues.push(...colorResult.issues);
      }

      // 2. RTL Support Check
      const rtlResult = await this.checkRTLSupport();
      checkedItems.push('Arabic RTL Support');
      if (rtlResult.passed) {
        passedItems.push('Arabic RTL Support');
      } else {
        failedItems.push('Arabic RTL Support');
        issues.push(...rtlResult.issues);
      }

      // 3. Accessibility Testing
      const accessibilityResult = await this.testAccessibility();
      checkedItems.push('WCAG Accessibility');
      if (accessibilityResult.passed) {
        passedItems.push('WCAG Accessibility');
      } else {
        failedItems.push('WCAG Accessibility');
        issues.push(...accessibilityResult.issues);
      }

      // 4. Responsive Design Validation
      const responsiveResult = await this.validateResponsiveDesign();
      checkedItems.push('Responsive Design');
      if (responsiveResult.passed) {
        passedItems.push('Responsive Design');
      } else {
        failedItems.push('Responsive Design');
        issues.push(...responsiveResult.issues);
      }

      // Calculate UI/UX score
      const totalChecks = checkedItems.length;
      const passedChecks = passedItems.length;
      const score = Math.round((passedChecks / totalChecks) * 100);

      const executionTime = Date.now() - startTime;
      logger.info('UIUXValidator', `🇩🇿 UI/UX validation completed - Score: ${score}/100`);

      return {
        passed: score >= AUDIT_CONFIG.thresholds.uiux,
        score,
        issues,
        details: {
          checkedItems,
          passedItems,
          failedItems,
          metadata: {
            algeriaCompliance: score >= 95,
            rtlReady: passedItems.includes('Arabic RTL Support'),
            accessibilityCompliant: passedItems.includes('WCAG Accessibility')
          }
        },
        executionTime
      };

    } catch (error) {
      logger.error('UIUXValidator', `UI/UX validation failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  async validateColorPalette(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.debug('UIUXValidator', 'Validating Algeria green color palette');

    const issues: Issue[] = [];
    let passed = true;

    try {
      // Check for Algeria color palette usage
      const libPath = path.join(this.flutterAppPath, 'lib');
      if (fs.existsSync(libPath)) {
        const files = await this.findDartFiles(libPath);
        let algeriaColorsFound = false;
        let defaultColorsFound = false;
        
        for (const file of files) {
          const content = await fs.readFile(file, 'utf-8');
          
          // Check for Algeria green palette
          for (const color of AUDIT_CONFIG.algeriaStandards.colorPalette) {
            if (content.includes(color.toLowerCase()) || content.includes(color.toUpperCase())) {
              algeriaColorsFound = true;
              break;
            }
          }
          
          // Check for default Flutter colors
          if (content.includes('Colors.blue') || content.includes('Colors.red') || content.includes('primarySwatch: Colors.blue')) {
            defaultColorsFound = true;
          }
        }

        if (!algeriaColorsFound) {
          issues.push({
            severity: 'HIGH',
            category: 'uiux',
            description: 'Algeria green color palette not found in application',
            recommendation: 'Implement Algeria green palette (#051F20, #0A3D40, #1A5D60, #DAFDE2)',
            impact: 'Does not meet Algeria design standards',
            requirementRef: '5.1'
          });
          passed = false;
        }

        if (defaultColorsFound) {
          issues.push({
            severity: 'MEDIUM',
            category: 'uiux',
            description: 'Default Flutter colors still in use',
            recommendation: 'Replace all default colors with Algeria brand colors',
            impact: 'Inconsistent with Algeria marketplace branding',
            requirementRef: '5.1'
          });
        }
      }

      // Check theme configuration
      const themeFiles = ['theme.dart', 'app_theme.dart', 'colors.dart'];
      let themeConfigFound = false;
      
      for (const themeFile of themeFiles) {
        const themePath = path.join(this.flutterAppPath, 'lib', 'core', 'theme', themeFile);
        if (fs.existsSync(themePath)) {
          themeConfigFound = true;
          const themeContent = await fs.readFile(themePath, 'utf-8');
          
          if (!themeContent.includes('#051F20') && !themeContent.includes('0xFF051F20')) {
            issues.push({
              severity: 'MEDIUM',
              category: 'uiux',
              description: 'Algeria primary color not found in theme configuration',
              location: themePath,
              recommendation: 'Set primary color to Algeria green #051F20',
              impact: 'Theme does not reflect Algeria branding',
              requirementRef: '5.1'
            });
          }
          break;
        }
      }

      if (!themeConfigFound) {
        issues.push({
          severity: 'HIGH',
          category: 'uiux',
          description: 'No theme configuration file found',
          recommendation: 'Create theme configuration with Algeria color palette',
          impact: 'No centralized color management',
          requirementRef: '5.1'
        });
        passed = false;
      }

      return {
        passed,
        score: passed ? 100 : Math.max(0, 100 - (issues.length * 25)),
        issues,
        details: {
          checkedItems: ['Algeria Colors', 'Default Colors', 'Theme Configuration'],
          passedItems: passed ? ['Algeria Colors'] : [],
          failedItems: passed ? [] : ['Color Palette'],
          metadata: { algeriaColorsFound: false, defaultColorsFound: true, themeConfigFound: false }
        },
        executionTime: Date.now() - startTime
      };

    } catch (error) {
      logger.error('UIUXValidator', `Color palette validation failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  async checkRTLSupport(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.debug('UIUXValidator', 'Checking Arabic RTL support implementation');

    const issues: Issue[] = [];
    let passed = true;

    try {
      // Check for localization setup
      const pubspecPath = path.join(this.flutterAppPath, 'pubspec.yaml');
      if (fs.existsSync(pubspecPath)) {
        const pubspecContent = await fs.readFile(pubspecPath, 'utf-8');
        
        if (!pubspecContent.includes('flutter_localizations')) {
          issues.push({
            severity: 'CRITICAL',
            category: 'uiux',
            description: 'flutter_localizations dependency missing',
            location: pubspecPath,
            recommendation: 'Add flutter_localizations to dependencies for RTL support',
            impact: 'Cannot support Arabic RTL layout',
            requirementRef: '5.2'
          });
          passed = false;
        }

        if (!pubspecContent.includes('intl:')) {
          issues.push({
            severity: 'HIGH',
            category: 'uiux',
            description: 'intl dependency missing for internationalization',
            location: pubspecPath,
            recommendation: 'Add intl dependency for proper localization',
            impact: 'Limited internationalization support',
            requirementRef: '5.2'
          });
        }
      }

      // Check for Arabic localization files
      const l10nPath = path.join(this.flutterAppPath, 'assets', 'l10n');
      if (fs.existsSync(l10nPath)) {
        const arabicFile = path.join(l10nPath, 'ar.json');
        if (!fs.existsSync(arabicFile)) {
          issues.push({
            severity: 'HIGH',
            category: 'uiux',
            description: 'Arabic localization file (ar.json) not found',
            location: l10nPath,
            recommendation: 'Create ar.json with Arabic translations',
            impact: 'No Arabic language support',
            requirementRef: '5.2'
          });
          passed = false;
        } else {
          const arabicContent = await fs.readFile(arabicFile, 'utf-8');
          try {
            const arabicData = JSON.parse(arabicContent);
            if (Object.keys(arabicData).length < 10) {
              issues.push({
                severity: 'MEDIUM',
                category: 'uiux',
                description: 'Arabic localization file has insufficient translations',
                location: arabicFile,
                recommendation: 'Complete Arabic translations for all UI elements',
                impact: 'Incomplete Arabic language support',
                requirementRef: '5.2'
              });
            }
          } catch (error) {
            issues.push({
              severity: 'HIGH',
              category: 'uiux',
              description: 'Arabic localization file has invalid JSON format',
              location: arabicFile,
              recommendation: 'Fix JSON syntax in Arabic localization file',
              impact: 'Arabic translations will not load',
              requirementRef: '5.2'
            });
          }
        }
      } else {
        issues.push({
          severity: 'CRITICAL',
          category: 'uiux',
          description: 'Localization directory not found',
          location: l10nPath,
          recommendation: 'Create assets/l10n directory with Arabic translations',
          impact: 'No localization support',
          requirementRef: '5.2'
        });
        passed = false;
      }

      // Check for RTL layout support in main.dart
      const mainDartPath = path.join(this.flutterAppPath, 'lib', 'main.dart');
      if (fs.existsSync(mainDartPath)) {
        const mainContent = await fs.readFile(mainDartPath, 'utf-8');
        
        if (!mainContent.includes('localizationsDelegates') || !mainContent.includes('supportedLocales')) {
          issues.push({
            severity: 'HIGH',
            category: 'uiux',
            description: 'MaterialApp not configured for localization',
            location: mainDartPath,
            recommendation: 'Configure localizationsDelegates and supportedLocales in MaterialApp',
            impact: 'RTL and localization will not work',
            requirementRef: '5.2'
          });
          passed = false;
        }

        if (!mainContent.includes('ar') && !mainContent.includes('Arabic')) {
          issues.push({
            severity: 'MEDIUM',
            category: 'uiux',
            description: 'Arabic locale not found in supported locales',
            location: mainDartPath,
            recommendation: 'Add Arabic (ar) to supportedLocales',
            impact: 'Arabic language not available to users',
            requirementRef: '5.2'
          });
        }
      }

      return {
        passed,
        score: passed ? 100 : Math.max(0, 100 - (issues.length * 20)),
        issues,
        details: {
          checkedItems: ['Localization Dependencies', 'Arabic Translations', 'RTL Configuration'],
          passedItems: passed ? ['Localization Dependencies'] : [],
          failedItems: passed ? [] : ['RTL Support'],
          metadata: { l10nPath, mainDartPath }
        },
        executionTime: Date.now() - startTime
      };

    } catch (error) {
      logger.error('UIUXValidator', `RTL support check failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  async testAccessibility(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.debug('UIUXValidator', 'Testing WCAG accessibility compliance');

    const issues: Issue[] = [];
    let passed = true;

    try {
      // Check for semantic widgets usage
      const libPath = path.join(this.flutterAppPath, 'lib');
      if (fs.existsSync(libPath)) {
        const files = await this.findDartFiles(libPath);
        let semanticsFound = false;
        let accessibilityFound = false;
        
        for (const file of files) {
          const content = await fs.readFile(file, 'utf-8');
          
          // Check for Semantics widgets
          if (content.includes('Semantics(') || content.includes('semanticsLabel')) {
            semanticsFound = true;
          }
          
          // Check for accessibility properties
          if (content.includes('tooltip:') || content.includes('accessibilityLabel') || content.includes('excludeFromSemantics')) {
            accessibilityFound = true;
          }
        }

        if (!semanticsFound) {
          issues.push({
            severity: 'HIGH',
            category: 'uiux',
            description: 'No Semantics widgets found for accessibility',
            recommendation: 'Add Semantics widgets with proper labels for screen readers',
            impact: 'App not accessible to visually impaired users',
            requirementRef: '5.3'
          });
          passed = false;
        }

        if (!accessibilityFound) {
          issues.push({
            severity: 'MEDIUM',
            category: 'uiux',
            description: 'Limited accessibility properties found',
            recommendation: 'Add tooltips and accessibility labels to interactive elements',
            impact: 'Poor accessibility experience',
            requirementRef: '5.3'
          });
        }
      }

      // Check for contrast and color accessibility
      const themeFiles = await this.findDartFiles(path.join(this.flutterAppPath, 'lib'));
      let contrastIssues = false;
      
      for (const file of themeFiles) {
        const content = await fs.readFile(file, 'utf-8');
        
        // Check for potential contrast issues (light colors on light backgrounds)
        if (content.includes('Colors.white') && content.includes('Colors.grey[100]')) {
          contrastIssues = true;
          break;
        }
      }

      if (contrastIssues) {
        issues.push({
          severity: 'MEDIUM',
          category: 'uiux',
          description: 'Potential color contrast issues detected',
          recommendation: 'Ensure minimum 4.5:1 contrast ratio for text elements',
          impact: 'Text may be difficult to read for users with visual impairments',
          requirementRef: '5.3'
        });
      }

      // Check for focus management
      let focusManagementFound = false;
      for (const file of themeFiles) {
        const content = await fs.readFile(file, 'utf-8');
        
        if (content.includes('FocusNode') || content.includes('autofocus') || content.includes('focusColor')) {
          focusManagementFound = true;
          break;
        }
      }

      if (!focusManagementFound) {
        issues.push({
          severity: 'MEDIUM',
          category: 'uiux',
          description: 'No focus management implementation found',
          recommendation: 'Implement proper focus management for keyboard navigation',
          impact: 'Poor keyboard accessibility',
          requirementRef: '5.3'
        });
      }

      return {
        passed,
        score: passed ? 100 : Math.max(0, 100 - (issues.length * 20)),
        issues,
        details: {
          checkedItems: ['Semantics Widgets', 'Accessibility Properties', 'Color Contrast', 'Focus Management'],
          passedItems: passed ? ['Semantics Widgets'] : [],
          failedItems: passed ? [] : ['Accessibility'],
          metadata: { semanticsFound: false, accessibilityFound: false, contrastIssues: false, focusManagementFound: false }
        },
        executionTime: Date.now() - startTime
      };

    } catch (error) {
      logger.error('UIUXValidator', `Accessibility testing failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  async validateResponsiveDesign(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.debug('UIUXValidator', 'Validating responsive design implementation');

    const issues: Issue[] = [];
    let passed = true;

    try {
      // Check for responsive layout widgets
      const libPath = path.join(this.flutterAppPath, 'lib');
      if (fs.existsSync(libPath)) {
        const files = await this.findDartFiles(libPath);
        let responsiveWidgetsFound = false;
        let mediaQueryFound = false;
        let layoutBuilderFound = false;
        
        for (const file of files) {
          const content = await fs.readFile(file, 'utf-8');
          
          // Check for responsive widgets
          if (content.includes('Flexible') || content.includes('Expanded') || content.includes('Wrap')) {
            responsiveWidgetsFound = true;
          }
          
          // Check for MediaQuery usage
          if (content.includes('MediaQuery.of(context)') || content.includes('MediaQuery.sizeOf')) {
            mediaQueryFound = true;
          }
          
          // Check for LayoutBuilder
          if (content.includes('LayoutBuilder') || content.includes('OrientationBuilder')) {
            layoutBuilderFound = true;
          }
        }

        if (!responsiveWidgetsFound) {
          issues.push({
            severity: 'HIGH',
            category: 'uiux',
            description: 'No responsive layout widgets found',
            recommendation: 'Use Flexible, Expanded, and Wrap widgets for responsive layouts',
            impact: 'Layout may not adapt to different screen sizes',
            requirementRef: '5.4'
          });
          passed = false;
        }

        if (!mediaQueryFound) {
          issues.push({
            severity: 'MEDIUM',
            category: 'uiux',
            description: 'MediaQuery not used for screen size adaptation',
            recommendation: 'Use MediaQuery to adapt layout based on screen dimensions',
            impact: 'Fixed layouts may not work well on all devices',
            requirementRef: '5.4'
          });
        }

        if (!layoutBuilderFound) {
          issues.push({
            severity: 'LOW',
            category: 'uiux',
            description: 'LayoutBuilder not found for advanced responsive design',
            recommendation: 'Consider using LayoutBuilder for complex responsive layouts',
            impact: 'Limited responsive design capabilities',
            requirementRef: '5.4'
          });
        }
      }

      // Check for breakpoint definitions
      let breakpointsFound = false;
      const files = await this.findDartFiles(libPath);
      
      for (const file of files) {
        const content = await fs.readFile(file, 'utf-8');
        
        if (content.includes('breakpoint') || content.includes('tablet') || content.includes('desktop')) {
          breakpointsFound = true;
          break;
        }
      }

      if (!breakpointsFound) {
        issues.push({
          severity: 'MEDIUM',
          category: 'uiux',
          description: 'No responsive breakpoints defined',
          recommendation: 'Define breakpoints for mobile, tablet, and desktop layouts',
          impact: 'No systematic approach to responsive design',
          requirementRef: '5.4'
        });
      }

      return {
        passed,
        score: passed ? 100 : Math.max(0, 100 - (issues.length * 20)),
        issues,
        details: {
          checkedItems: ['Responsive Widgets', 'MediaQuery Usage', 'LayoutBuilder', 'Breakpoints'],
          passedItems: passed ? ['Responsive Widgets'] : [],
          failedItems: passed ? [] : ['Responsive Design'],
          metadata: { responsiveWidgetsFound: false, mediaQueryFound: false, layoutBuilderFound: false, breakpointsFound: false }
        },
        executionTime: Date.now() - startTime
      };

    } catch (error) {
      logger.error('UIUXValidator', `Responsive design validation failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  private async findDartFiles(dir: string): Promise<string[]> {
    const files: string[] = [];
    
    try {
      const items = await fs.readdir(dir);
      
      for (const item of items) {
        const fullPath = path.join(dir, item);
        const stat = await fs.stat(fullPath);
        
        if (stat.isDirectory()) {
          const subFiles = await this.findDartFiles(fullPath);
          files.push(...subFiles);
        } else if (item.endsWith('.dart')) {
          files.push(fullPath);
        }
      }
    } catch (error) {
      // Ignore errors for inaccessible directories
    }
    
    return files;
  }
}