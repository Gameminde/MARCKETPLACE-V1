/**
 * Security Scanner for Algeria Marketplace Phase 2 audit
 * Banking-grade security validation for CIB/EDAHABIA compliance
 */

import * as fs from 'fs-extra';
import * as path from 'path';
import { SecurityScanner as ISecurityScanner } from '../interfaces/validators';
import { ValidationResult, AuditCategory, Issue } from '../types/audit-types';
import { SECURITY_STANDARDS } from '../config/audit-config';
import { logger } from '../utils/logger';

export class SecurityScanner implements ISecurityScanner {
  category: AuditCategory = 'security';
  private flutterAppPath: string;

  constructor(flutterAppPath: string) {
    this.flutterAppPath = flutterAppPath;
  }

  getName(): string {
    return 'Security Scanner';
  }

  getDescription(): string {
    return 'Banking-grade security validation for CIB/EDAHABIA compliance';
  }

  async validate(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.info('SecurityScanner', '🔒 Starting banking-grade security validation');

    const issues: Issue[] = [];
    const checkedItems: string[] = [];
    const passedItems: string[] = [];
    const failedItems: string[] = [];

    try {
      // 1. Encryption Validation
      const encryptionResult = await this.validateEncryption();
      checkedItems.push('End-to-End Encryption');
      if (encryptionResult.passed) {
        passedItems.push('End-to-End Encryption');
      } else {
        failedItems.push('End-to-End Encryption');
        issues.push(...encryptionResult.issues);
      }

      // 2. Authentication Check
      const authResult = await this.checkAuthentication();
      checkedItems.push('Authentication Mechanisms');
      if (authResult.passed) {
        passedItems.push('Authentication Mechanisms');
      } else {
        failedItems.push('Authentication Mechanisms');
        issues.push(...authResult.issues);
      }

      // 3. Input Validation
      const inputResult = await this.scanInputValidation();
      checkedItems.push('Input Validation');
      if (inputResult.passed) {
        passedItems.push('Input Validation');
      } else {
        failedItems.push('Input Validation');
        issues.push(...inputResult.issues);
      }

      // 4. Network Security
      const networkResult = await this.analyzeNetworkSecurity();
      checkedItems.push('Network Security');
      if (networkResult.passed) {
        passedItems.push('Network Security');
      } else {
        failedItems.push('Network Security');
        issues.push(...networkResult.issues);
      }

      // Calculate security score (banking requires 100%)
      const totalChecks = checkedItems.length;
      const passedChecks = passedItems.length;
      const score = Math.round((passedChecks / totalChecks) * 100);

      const executionTime = Date.now() - startTime;
      logger.info('SecurityScanner', `🔒 Security validation completed - Score: ${score}/100`);

      return {
        passed: score === 100, // Banking requires perfect security
        score,
        issues,
        details: {
          checkedItems,
          passedItems,
          failedItems,
          metadata: {
            bankingCompliance: score === 100,
            criticalSecurityIssues: issues.filter(i => i.severity === 'CRITICAL').length
          }
        },
        executionTime
      };

    } catch (error) {
      logger.error('SecurityScanner', `Security validation failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  async validateEncryption(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.debug('SecurityScanner', 'Validating encryption implementation');

    const issues: Issue[] = [];
    let passed = true;

    try {
      // Check for secure storage usage
      const secureStoragePath = path.join(this.flutterAppPath, 'lib', 'core', 'services', 'secure_config_service.dart');
      if (!fs.existsSync(secureStoragePath)) {
        issues.push({
          severity: 'CRITICAL',
          category: 'security',
          description: 'Secure storage service not found',
          location: secureStoragePath,
          recommendation: 'Implement flutter_secure_storage for sensitive data',
          impact: 'Banking data not properly encrypted',
          requirementRef: '3.1'
        });
        passed = false;
      } else {
        const secureStorageContent = await fs.readFile(secureStoragePath, 'utf-8');
        
        // Check for proper encryption usage
        if (!secureStorageContent.includes('flutter_secure_storage')) {
          issues.push({
            severity: 'HIGH',
            category: 'security',
            description: 'Secure storage not properly implemented',
            location: secureStoragePath,
            recommendation: 'Use flutter_secure_storage for all sensitive data',
            impact: 'Data may be stored in plain text',
            requirementRef: '3.1'
          });
          passed = false;
        }
      }

      // Check pubspec.yaml for security dependencies
      const pubspecPath = path.join(this.flutterAppPath, 'pubspec.yaml');
      if (fs.existsSync(pubspecPath)) {
        const pubspecContent = await fs.readFile(pubspecPath, 'utf-8');
        
        if (!pubspecContent.includes('flutter_secure_storage')) {
          issues.push({
            severity: 'CRITICAL',
            category: 'security',
            description: 'flutter_secure_storage dependency missing',
            location: pubspecPath,
            recommendation: 'Add flutter_secure_storage: ^9.2.2 to dependencies',
            impact: 'Cannot implement banking-grade encryption',
            requirementRef: '3.1'
          });
          passed = false;
        }

        if (!pubspecContent.includes('crypto')) {
          issues.push({
            severity: 'HIGH',
            category: 'security',
            description: 'crypto dependency missing for encryption',
            location: pubspecPath,
            recommendation: 'Add crypto: ^3.0.2 to dependencies',
            impact: 'Limited encryption capabilities',
            requirementRef: '3.1'
          });
        }
      }

      return {
        passed,
        score: passed ? 100 : 0,
        issues,
        details: {
          checkedItems: ['Secure Storage', 'Encryption Dependencies'],
          passedItems: passed ? ['Secure Storage', 'Encryption Dependencies'] : [],
          failedItems: passed ? [] : ['Secure Storage Implementation'],
          metadata: { secureStoragePath, pubspecPath }
        },
        executionTime: Date.now() - startTime
      };

    } catch (error) {
      logger.error('SecurityScanner', `Encryption validation failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  async checkAuthentication(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.debug('SecurityScanner', 'Checking authentication mechanisms');

    const issues: Issue[] = [];
    let passed = true;

    try {
      // Check for authentication service
      const authServicePath = path.join(this.flutterAppPath, 'lib', 'core', 'services');
      const authFiles = ['auth_service.dart', 'authentication_service.dart', 'user_service.dart'];
      
      let authServiceFound = false;
      for (const authFile of authFiles) {
        if (fs.existsSync(path.join(authServicePath, authFile))) {
          authServiceFound = true;
          break;
        }
      }

      if (!authServiceFound) {
        issues.push({
          severity: 'CRITICAL',
          category: 'security',
          description: 'Authentication service not found',
          location: authServicePath,
          recommendation: 'Implement robust authentication service for banking compliance',
          impact: 'No user authentication mechanism',
          requirementRef: '3.2'
        });
        passed = false;
      }

      // Check for JWT or token-based authentication
      const libPath = path.join(this.flutterAppPath, 'lib');
      if (fs.existsSync(libPath)) {
        const files = await this.findDartFiles(libPath);
        let jwtFound = false;
        
        for (const file of files) {
          const content = await fs.readFile(file, 'utf-8');
          if (content.includes('jwt') || content.includes('token') || content.includes('Bearer')) {
            jwtFound = true;
            break;
          }
        }

        if (!jwtFound) {
          issues.push({
            severity: 'HIGH',
            category: 'security',
            description: 'No JWT or token-based authentication found',
            recommendation: 'Implement JWT tokens for secure API authentication',
            impact: 'Weak authentication mechanism',
            requirementRef: '3.2'
          });
        }
      }

      return {
        passed,
        score: passed ? 100 : Math.max(0, 100 - (issues.length * 30)),
        issues,
        details: {
          checkedItems: ['Authentication Service', 'Token-based Auth'],
          passedItems: passed ? ['Authentication Service'] : [],
          failedItems: passed ? [] : ['Authentication Implementation'],
          metadata: { authServicePath, authServiceFound }
        },
        executionTime: Date.now() - startTime
      };

    } catch (error) {
      logger.error('SecurityScanner', `Authentication check failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  async scanInputValidation(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.debug('SecurityScanner', 'Scanning input validation coverage');

    const issues: Issue[] = [];
    let passed = true;

    try {
      // Check for form validation
      const libPath = path.join(this.flutterAppPath, 'lib');
      if (fs.existsSync(libPath)) {
        const files = await this.findDartFiles(libPath);
        let validationFound = false;
        
        for (const file of files) {
          const content = await fs.readFile(file, 'utf-8');
          if (content.includes('validator:') || content.includes('FormValidator') || content.includes('validate(')) {
            validationFound = true;
            break;
          }
        }

        if (!validationFound) {
          issues.push({
            severity: 'HIGH',
            category: 'security',
            description: 'No input validation found in forms',
            recommendation: 'Implement comprehensive input validation for all user inputs',
            impact: 'Vulnerable to injection attacks',
            requirementRef: '3.3'
          });
          passed = false;
        }
      }

      // Check for sanitization
      const sanitizationPatterns = ['sanitize', 'escape', 'clean'];
      let sanitizationFound = false;
      
      if (fs.existsSync(libPath)) {
        const files = await this.findDartFiles(libPath);
        
        for (const file of files) {
          const content = await fs.readFile(file, 'utf-8');
          for (const pattern of sanitizationPatterns) {
            if (content.toLowerCase().includes(pattern)) {
              sanitizationFound = true;
              break;
            }
          }
          if (sanitizationFound) break;
        }
      }

      if (!sanitizationFound) {
        issues.push({
          severity: 'MEDIUM',
          category: 'security',
          description: 'No input sanitization patterns found',
          recommendation: 'Implement input sanitization to prevent XSS and injection attacks',
          impact: 'Potential security vulnerabilities',
          requirementRef: '3.3'
        });
      }

      return {
        passed,
        score: passed ? 100 : Math.max(0, 100 - (issues.length * 25)),
        issues,
        details: {
          checkedItems: ['Form Validation', 'Input Sanitization'],
          passedItems: passed ? ['Form Validation'] : [],
          failedItems: passed ? [] : ['Input Validation'],
          metadata: { validationFound: true, sanitizationFound: false }
        },
        executionTime: Date.now() - startTime
      };

    } catch (error) {
      logger.error('SecurityScanner', `Input validation scan failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  async analyzeNetworkSecurity(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.debug('SecurityScanner', 'Analyzing network security configuration');

    const issues: Issue[] = [];
    let passed = true;

    try {
      // Check for HTTPS enforcement
      const libPath = path.join(this.flutterAppPath, 'lib');
      if (fs.existsSync(libPath)) {
        const files = await this.findDartFiles(libPath);
        let httpsFound = false;
        let httpFound = false;
        
        for (const file of files) {
          const content = await fs.readFile(file, 'utf-8');
          if (content.includes('https://')) {
            httpsFound = true;
          }
          if (content.includes('http://') && !content.includes('https://')) {
            httpFound = true;
          }
        }

        if (httpFound && !httpsFound) {
          issues.push({
            severity: 'CRITICAL',
            category: 'security',
            description: 'HTTP connections found without HTTPS',
            recommendation: 'Use only HTTPS for all network communications',
            impact: 'Data transmitted in plain text',
            requirementRef: '3.4'
          });
          passed = false;
        }
      }

      // Check for certificate pinning
      const androidManifestPath = path.join(this.flutterAppPath, 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
      if (fs.existsSync(androidManifestPath)) {
        const manifestContent = await fs.readFile(androidManifestPath, 'utf-8');
        
        if (!manifestContent.includes('networkSecurityConfig')) {
          issues.push({
            severity: 'HIGH',
            category: 'security',
            description: 'Network security configuration not found',
            location: androidManifestPath,
            recommendation: 'Implement network security config with certificate pinning',
            impact: 'Vulnerable to man-in-the-middle attacks',
            requirementRef: '3.4'
          });
        }
      }

      return {
        passed,
        score: passed ? 100 : Math.max(0, 100 - (issues.length * 30)),
        issues,
        details: {
          checkedItems: ['HTTPS Enforcement', 'Certificate Pinning'],
          passedItems: passed ? ['HTTPS Enforcement'] : [],
          failedItems: passed ? [] : ['Network Security'],
          metadata: { androidManifestPath }
        },
        executionTime: Date.now() - startTime
      };

    } catch (error) {
      logger.error('SecurityScanner', `Network security analysis failed: ${error instanceof Error ? error.message : String(error)}`);
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