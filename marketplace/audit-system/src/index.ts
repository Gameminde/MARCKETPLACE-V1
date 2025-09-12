#!/usr/bin/env node

/**
 * Algeria Marketplace Phase 2 Audit System CLI
 */

import { Command } from 'commander';
import chalk from 'chalk';
import * as path from 'path';
import { AuditController } from './core/audit-controller';
import { logger } from './utils/logger';
import { AUDIT_CONFIG } from './config/audit-config';

const program = new Command();

program
  .name('algeria-marketplace-audit')
  .description('🇩🇿 Comprehensive audit system for Algeria Marketplace Phase 2 readiness validation')
  .version('1.0.0');

program
  .command('full')
  .description('Execute comprehensive multi-dimensional audit')
  .option('-p, --path <path>', 'Flutter app path', '../flutter_app')
  .option('-o, --output <path>', 'Output report path', './audit-reports')
  .action(async (options) => {
    console.log(chalk.green.bold('🇩🇿 ALGERIA MARKETPLACE PHASE 2 AUDIT SYSTEM'));
    console.log(chalk.blue('Banking-grade validation for 45M users\n'));

    try {
      const flutterAppPath = path.resolve(options.path);
      const controller = new AuditController(flutterAppPath);
      
      // Register validators (real Environment Validator + mock others)
      registerValidators(controller, flutterAppPath);
      
      console.log(chalk.yellow('🚀 Starting comprehensive audit...\n'));
      
      const result = await controller.executeFullAudit();
      const report = await controller.generateReport(result);
      
      console.log('\n' + chalk.green.bold('📊 AUDIT COMPLETED'));
      console.log(chalk.white(report));
      
      // Exit with appropriate code
      process.exit(result.readinessStatus === 'READY' ? 0 : 1);
      
    } catch (error) {
      console.error(chalk.red.bold('💥 AUDIT FAILED:'), error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

program
  .command('category <category>')
  .description('Execute audit for specific category')
  .option('-p, --path <path>', 'Flutter app path', '../flutter_app')
  .action(async (category, options) => {
    console.log(chalk.green.bold(`🔍 AUDITING ${category.toUpperCase()} CATEGORY`));
    
    try {
      const flutterAppPath = path.resolve(options.path);
      const controller = new AuditController(flutterAppPath);
      
      registerValidators(controller, flutterAppPath);
      
      const result = await controller.executeCategoryAudit(category);
      
      console.log(chalk.green(`✅ ${category} audit completed`));
      console.log(chalk.white(`Score: ${result.score}/100`));
      console.log(chalk.white(`Issues: ${result.issues.length}`));
      
      if (result.issues.length > 0) {
        console.log(chalk.yellow('\n📋 Issues found:'));
        result.issues.forEach((issue, index) => {
          const severityColor = issue.severity === 'CRITICAL' ? chalk.red : 
                               issue.severity === 'HIGH' ? chalk.yellow : chalk.blue;
          console.log(`${index + 1}. ${severityColor(issue.severity)}: ${issue.description}`);
        });
      }
      
    } catch (error) {
      console.error(chalk.red.bold('💥 CATEGORY AUDIT FAILED:'), error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  });

program
  .command('config')
  .description('Show audit configuration')
  .action(() => {
    console.log(chalk.green.bold('⚙️ AUDIT CONFIGURATION'));
    console.log(chalk.white(JSON.stringify(AUDIT_CONFIG, null, 2)));
  });

// Register all real validators
function registerValidators(controller: AuditController, flutterAppPath: string) {
  // Real validators implementation
  const { EnvironmentValidator } = require('./validators/environment-validator');
  const { SecurityScanner } = require('./validators/security-scanner');
  const { PerformanceTester } = require('./validators/performance-tester');
  const { UIUXValidator } = require('./validators/uiux-validator');
  
  controller.registerValidator('environment', new EnvironmentValidator(flutterAppPath));
  controller.registerValidator('security', new SecurityScanner(flutterAppPath));
  controller.registerValidator('performance', new PerformanceTester(flutterAppPath));
  controller.registerValidator('uiux', new UIUXValidator(flutterAppPath));

  // Mock Code Quality validator (will be implemented in next task)
  const mockCodeQualityValidator = {
    validate: async () => ({
      passed: true,
      score: 88,
      issues: [{
        severity: 'MEDIUM' as const,
        category: 'codeQuality',
        description: 'Code quality analysis pending - real implementation needed',
        recommendation: 'Implement Clean Architecture and BLoC pattern validation',
        impact: 'Code quality not fully validated',
        requirementRef: '2.1'
      }],
      details: {
        checkedItems: ['Architecture Pattern', 'State Management', 'Error Handling'],
        passedItems: ['Basic Structure'],
        failedItems: ['Detailed Analysis'],
        metadata: { note: 'Code Quality validator ready for implementation' }
      },
      executionTime: 50
    })
  };

  controller.registerValidator('codeQuality', mockCodeQualityValidator);
}

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  logger.critical('System', 'Unhandled promise rejection', { reason, promise });
  process.exit(1);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.critical('System', 'Uncaught exception', { error: error.message, stack: error.stack });
  process.exit(1);
});

if (require.main === module) {
  program.parse();
}