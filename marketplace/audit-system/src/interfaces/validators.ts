/**
 * Core validator interfaces for Algeria Marketplace audit system
 */

import { ValidationResult, AuditCategory } from '../types/audit-types';

export interface BaseValidator {
  category: AuditCategory;
  validate(): Promise<ValidationResult>;
  getName(): string;
  getDescription(): string;
}

export interface EnvironmentValidator extends BaseValidator {
  validateFlutterSDK(): Promise<ValidationResult>;
  validateAndroidStudio(): Promise<ValidationResult>;
  validateGradleBuild(): Promise<ValidationResult>;
  generateAPK(): Promise<ValidationResult>;
}

export interface CodeQualityAnalyzer extends BaseValidator {
  analyzeArchitecture(): Promise<ValidationResult>;
  scanForUndefinedReferences(): Promise<ValidationResult>;
  validateStateManagement(): Promise<ValidationResult>;
  checkErrorHandling(): Promise<ValidationResult>;
}

export interface SecurityScanner extends BaseValidator {
  validateEncryption(): Promise<ValidationResult>;
  checkAuthentication(): Promise<ValidationResult>;
  scanInputValidation(): Promise<ValidationResult>;
  analyzeNetworkSecurity(): Promise<ValidationResult>;
}

export interface PerformanceTester extends BaseValidator {
  measureColdStartTime(): Promise<ValidationResult>;
  testAnimationPerformance(): Promise<ValidationResult>;
  measureAPIResponseTimes(): Promise<ValidationResult>;
  monitorMemoryUsage(): Promise<ValidationResult>;
}

export interface UIUXValidator extends BaseValidator {
  validateColorPalette(): Promise<ValidationResult>;
  checkRTLSupport(): Promise<ValidationResult>;
  testAccessibility(): Promise<ValidationResult>;
  validateResponsiveDesign(): Promise<ValidationResult>;
}

export interface AuditController {
  executeFullAudit(): Promise<import('../types/audit-types').AuditResult>;
  executeCategoryAudit(category: AuditCategory): Promise<ValidationResult>;
  getAuditProgress(): import('../types/audit-types').AuditProgress;
  generateReport(result: import('../types/audit-types').AuditResult): Promise<string>;
}