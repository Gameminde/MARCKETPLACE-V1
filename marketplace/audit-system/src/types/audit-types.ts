/**
 * Core audit system type definitions for Algeria Marketplace Phase 2
 */

export type AuditCategory = 'environment' | 'codeQuality' | 'security' | 'performance' | 'uiux';

export type IssueSeverity = 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';

export interface Issue {
  severity: IssueSeverity;
  category: string;
  description: string;
  location?: string;
  recommendation: string;
  impact: string;
  requirementRef?: string;
}

export interface ValidationResult {
  passed: boolean;
  score: number;
  issues: Issue[];
  details: ValidationDetails;
  executionTime: number;
}

export interface ValidationDetails {
  checkedItems: string[];
  passedItems: string[];
  failedItems: string[];
  metadata: Record<string, any>;
}

export interface CategoryScores {
  environment: number;
  codeQuality: number;
  security: number;
  performance: number;
  uiux: number;
}

export interface AuditResult {
  overallScore: number;
  categoryScores: CategoryScores;
  criticalIssues: Issue[];
  warnings: Issue[];
  recommendations: Recommendation[];
  executionTime: number;
  timestamp: Date;
  readinessStatus: 'READY' | 'NOT_READY' | 'NEEDS_REVIEW';
}

export interface Recommendation {
  priority: number;
  category: AuditCategory;
  title: string;
  description: string;
  estimatedFixTime: string;
  impact: string;
}

export interface AuditProgress {
  currentCategory: AuditCategory | null;
  completedCategories: AuditCategory[];
  totalProgress: number;
  currentStep: string;
}

export interface AuditConfiguration {
  thresholds: {
    overall: number;
    security: number;
    performance: number;
    environment: number;
    codeQuality: number;
    uiux: number;
  };
  algeriaStandards: {
    colorPalette: string[];
    rtlSupport: boolean;
    currencyFormat: string;
    bankingCompliance: string[];
  };
  performanceTargets: {
    coldStartTime: number;
    animationFPS: number;
    apiResponseTime: number;
    memoryUsage: number;
  };
}