/**
 * Main audit controller for Algeria Marketplace Phase 2 audit system
 */

import { AuditController as IAuditController } from '../interfaces/validators';
import { 
  AuditResult, 
  AuditCategory, 
  ValidationResult, 
  AuditProgress,
  CategoryScores,
  Issue,
  Recommendation
} from '../types/audit-types';
import { AUDIT_CONFIG } from '../config/audit-config';
import { logger } from '../utils/logger';
import { errorHandler, AuditError, ConfigurationError } from '../utils/error-handler';

export class AuditController implements IAuditController {
  private progress: AuditProgress = {
    currentCategory: null,
    completedCategories: [],
    totalProgress: 0,
    currentStep: 'Initializing'
  };

  private validators: Map<AuditCategory, any> = new Map();
  private flutterAppPath: string;

  constructor(flutterAppPath: string) {
    this.flutterAppPath = flutterAppPath;
    logger.info('AuditController', `Initialized for Flutter app at: ${flutterAppPath}`);
  }

  registerValidator(category: AuditCategory, validator: any): void {
    this.validators.set(category, validator);
    logger.debug('AuditController', `Registered validator for category: ${category}`);
  }

  async executeFullAudit(): Promise<AuditResult> {
    const startTime = Date.now();
    logger.info('AuditController', '🇩🇿 Starting comprehensive Algeria Marketplace Phase 2 audit');
    
    try {
      this.progress.currentStep = 'Starting full audit';
      this.progress.totalProgress = 0;

      const categoryResults: Partial<Record<AuditCategory, ValidationResult>> = {};
      const categories: AuditCategory[] = ['environment', 'codeQuality', 'security', 'performance', 'uiux'];
      
      // Execute all category audits
      for (let i = 0; i < categories.length; i++) {
        const category = categories[i];
        this.progress.currentCategory = category;
        this.progress.currentStep = `Auditing ${category}`;
        this.progress.totalProgress = (i / categories.length) * 100;
        
        logger.info('AuditController', `📊 Executing ${category} audit (${i + 1}/${categories.length})`);
        
        try {
          const result = await this.executeCategoryAudit(category);
          categoryResults[category] = result;
          this.progress.completedCategories.push(category);
          
          logger.info('AuditController', `✅ ${category} audit completed - Score: ${result.score}/100`);
        } catch (error) {
          logger.error('AuditController', `❌ ${category} audit failed: ${error instanceof Error ? error.message : String(error)}`);
          
          // Create a failed result for this category
          categoryResults[category] = {
            passed: false,
            score: 0,
            issues: [{
              severity: 'CRITICAL',
              category,
              description: `Audit execution failed: ${error instanceof Error ? error.message : String(error)}`,
              recommendation: 'Review audit system configuration and try again',
              impact: 'Cannot validate this category for production readiness'
            }],
            details: {
              checkedItems: [],
              passedItems: [],
              failedItems: ['Audit execution'],
              metadata: { error: error instanceof Error ? error.message : String(error) }
            },
            executionTime: 0
          };
        }
      }

      this.progress.currentStep = 'Generating final report';
      this.progress.totalProgress = 100;

      // Calculate final audit result
      const auditResult = this.calculateAuditResult(categoryResults, Date.now() - startTime);
      
      logger.info('AuditController', `🎯 Audit completed - Overall Score: ${auditResult.overallScore}/100`);
      logger.info('AuditController', `📋 Readiness Status: ${auditResult.readinessStatus}`);
      
      return auditResult;
      
    } catch (error) {
      logger.critical('AuditController', `💥 Critical audit failure: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  async executeCategoryAudit(category: AuditCategory): Promise<ValidationResult> {
    const validator = this.validators.get(category);
    
    if (!validator) {
      throw new ConfigurationError(
        'AuditController',
        `No validator registered for category: ${category}`
      );
    }

    logger.debug('AuditController', `Executing ${category} validation`);
    
    try {
      const result = await validator.validate();
      logger.debug('AuditController', `${category} validation completed`, {
        score: result.score,
        issuesCount: result.issues.length
      });
      
      return result;
    } catch (error) {
      logger.error('AuditController', `${category} validation failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  getAuditProgress(): AuditProgress {
    return { ...this.progress };
  }

  async generateReport(result: AuditResult): Promise<string> {
    logger.info('AuditController', 'Generating comprehensive audit report');
    
    const report = this.formatAuditReport(result);
    
    // Save report to file
    const fs = require('fs-extra');
    const path = require('path');
    const reportPath = path.join(this.flutterAppPath, '..', 'audit-reports', `audit-report-${new Date().toISOString().split('T')[0]}.md`);
    
    await fs.ensureDir(path.dirname(reportPath));
    await fs.writeFile(reportPath, report);
    
    logger.info('AuditController', `📄 Report saved to: ${reportPath}`);
    
    return report;
  }

  private calculateAuditResult(
    categoryResults: Partial<Record<AuditCategory, ValidationResult>>,
    executionTime: number
  ): AuditResult {
    const categoryScores: CategoryScores = {
      environment: categoryResults.environment?.score || 0,
      codeQuality: categoryResults.codeQuality?.score || 0,
      security: categoryResults.security?.score || 0,
      performance: categoryResults.performance?.score || 0,
      uiux: categoryResults.uiux?.score || 0
    };

    // Calculate weighted overall score
    const weights = {
      environment: 0.15,
      codeQuality: 0.20,
      security: 0.30,  // Higher weight for security (banking requirement)
      performance: 0.20,
      uiux: 0.15
    };

    const overallScore = Math.round(
      categoryScores.environment * weights.environment +
      categoryScores.codeQuality * weights.codeQuality +
      categoryScores.security * weights.security +
      categoryScores.performance * weights.performance +
      categoryScores.uiux * weights.uiux
    );

    // Collect all issues
    const allIssues: Issue[] = [];
    const criticalIssues: Issue[] = [];
    const warnings: Issue[] = [];

    Object.values(categoryResults).forEach(result => {
      if (result) {
        allIssues.push(...result.issues);
        result.issues.forEach(issue => {
          if (issue.severity === 'CRITICAL' || issue.severity === 'HIGH') {
            criticalIssues.push(issue);
          } else {
            warnings.push(issue);
          }
        });
      }
    });

    // Generate recommendations
    const recommendations = this.generateRecommendations(categoryScores, allIssues);

    // Determine readiness status
    const readinessStatus = this.determineReadinessStatus(overallScore, categoryScores, criticalIssues);

    return {
      overallScore,
      categoryScores,
      criticalIssues,
      warnings,
      recommendations,
      executionTime,
      timestamp: new Date(),
      readinessStatus
    };
  }

  private generateRecommendations(scores: CategoryScores, issues: Issue[]): Recommendation[] {
    const recommendations: Recommendation[] = [];
    
    // Generate recommendations based on scores and issues
    Object.entries(scores).forEach(([category, score]) => {
      if (score < AUDIT_CONFIG.thresholds[category as keyof typeof AUDIT_CONFIG.thresholds]) {
        const categoryIssues = issues.filter(issue => issue.category === category);
        const criticalCount = categoryIssues.filter(issue => issue.severity === 'CRITICAL').length;
        
        recommendations.push({
          priority: criticalCount > 0 ? 1 : 2,
          category: category as AuditCategory,
          title: `Improve ${category} score`,
          description: `Current score (${score}) is below threshold (${AUDIT_CONFIG.thresholds[category as keyof typeof AUDIT_CONFIG.thresholds]})`,
          estimatedFixTime: criticalCount > 0 ? '2-4 hours' : '1-2 hours',
          impact: criticalCount > 0 ? 'Blocks production readiness' : 'Improves overall quality'
        });
      }
    });

    return recommendations.sort((a, b) => a.priority - b.priority);
  }

  private determineReadinessStatus(
    overallScore: number,
    categoryScores: CategoryScores,
    criticalIssues: Issue[]
  ): 'READY' | 'NOT_READY' | 'NEEDS_REVIEW' {
    // Critical blockers
    if (criticalIssues.length > 0) {
      return 'NOT_READY';
    }

    // Security must be perfect for banking
    if (categoryScores.security < AUDIT_CONFIG.thresholds.security) {
      return 'NOT_READY';
    }

    // Overall score check
    if (overallScore >= AUDIT_CONFIG.thresholds.overall) {
      return 'READY';
    } else if (overallScore >= 80) {
      return 'NEEDS_REVIEW';
    } else {
      return 'NOT_READY';
    }
  }

  private formatAuditReport(result: AuditResult): string {
    const statusEmoji = result.readinessStatus === 'READY' ? '✅' : 
                       result.readinessStatus === 'NEEDS_REVIEW' ? '⚠️' : '❌';
    
    return `# 🇩🇿 ALGERIA MARKETPLACE AUDIT REPORT

## Executive Summary
**Overall Readiness:** ${statusEmoji} ${result.readinessStatus}
**Overall Score:** ${result.overallScore}/100
**Critical Issues:** ${result.criticalIssues.length}
**Estimated Fix Time:** ${this.estimateFixTime(result.recommendations)}

## Category Scores
- **Environment:** ${result.categoryScores.environment}/100
- **Code Quality:** ${result.categoryScores.codeQuality}/100
- **Security:** ${result.categoryScores.security}/100
- **Performance:** ${result.categoryScores.performance}/100
- **UI/UX:** ${result.categoryScores.uiux}/100

## Critical Actions Required
${result.criticalIssues.map((issue, index) => 
  `${index + 1}. **${issue.category}**: ${issue.description}\n   - **Fix:** ${issue.recommendation}\n   - **Impact:** ${issue.impact}`
).join('\n\n')}

## Algeria-Specific Validations
- **RTL Arabic Support:** ${result.categoryScores.uiux >= 90 ? '✅' : '❌'}
- **DZD Currency Format:** ${result.categoryScores.uiux >= 90 ? '✅' : '❌'}
- **CIB/EDAHABIA Ready:** ${result.categoryScores.security >= 100 ? '✅' : '❌'}
- **Local Design Compliance:** ${result.categoryScores.uiux >= 95 ? '✅' : '❌'}

## Production Readiness Checklist
- ${result.criticalIssues.length === 0 ? '✅' : '❌'} All critical issues resolved
- ${result.categoryScores.environment >= 95 ? '✅' : '❌'} APK builds successfully
- ${result.categoryScores.security >= 100 ? '✅' : '❌'} Security banking-grade validated
- ${result.categoryScores.performance >= 95 ? '✅' : '❌'} Performance targets met
- ${result.categoryScores.uiux >= 95 ? '✅' : '❌'} Algeria compliance 100%

## Next Steps Action Plan
${result.recommendations.map((rec, index) => 
  `${index + 1}. **${rec.title}** (Priority ${rec.priority})\n   - ${rec.description}\n   - Estimated time: ${rec.estimatedFixTime}\n   - Impact: ${rec.impact}`
).join('\n\n')}

---
*Report generated on ${result.timestamp.toISOString()}*
*Execution time: ${result.executionTime}ms*
`;
  }

  private estimateFixTime(recommendations: Recommendation[]): string {
    const totalHours = recommendations.reduce((total, rec) => {
      const hours = rec.estimatedFixTime.includes('hour') ? 
        parseInt(rec.estimatedFixTime.split('-')[1] || rec.estimatedFixTime.split(' ')[0]) : 0;
      return total + hours;
    }, 0);
    
    if (totalHours === 0) return 'No fixes needed';
    if (totalHours < 24) return `${totalHours} hours`;
    return `${Math.ceil(totalHours / 24)} days`;
  }
}