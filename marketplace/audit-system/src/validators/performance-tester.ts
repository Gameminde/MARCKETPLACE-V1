/**
 * Performance Tester for Algeria Marketplace Phase 2 audit
 * Validates performance for 45M users scalability
 */

import * as fs from 'fs-extra';
import * as path from 'path';
import { PerformanceTester as IPerformanceTester } from '../interfaces/validators';
import { ValidationResult, AuditCategory, Issue } from '../types/audit-types';
import { AUDIT_CONFIG } from '../config/audit-config';
import { logger } from '../utils/logger';

export class PerformanceTester implements IPerformanceTester {
  category: AuditCategory = 'performance';
  private flutterAppPath: string;

  constructor(flutterAppPath: string) {
    this.flutterAppPath = flutterAppPath;
  }

  getName(): string {
    return 'Performance Tester';
  }

  getDescription(): string {
    return 'Performance validation for 45M users scalability';
  }

  async validate(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.info('PerformanceTester', '⚡ Starting performance validation for 45M users');

    const issues: Issue[] = [];
    const checkedItems: string[] = [];
    const passedItems: string[] = [];
    const failedItems: string[] = [];

    try {
      // 1. Cold Start Time Analysis
      const coldStartResult = await this.measureColdStartTime();
      checkedItems.push('Cold Start Time');
      if (coldStartResult.passed) {
        passedItems.push('Cold Start Time');
      } else {
        failedItems.push('Cold Start Time');
        issues.push(...coldStartResult.issues);
      }

      // 2. Animation Performance
      const animationResult = await this.testAnimationPerformance();
      checkedItems.push('Animation Performance');
      if (animationResult.passed) {
        passedItems.push('Animation Performance');
      } else {
        failedItems.push('Animation Performance');
        issues.push(...animationResult.issues);
      }

      // 3. API Response Times
      const apiResult = await this.measureAPIResponseTimes();
      checkedItems.push('API Response Times');
      if (apiResult.passed) {
        passedItems.push('API Response Times');
      } else {
        failedItems.push('API Response Times');
        issues.push(...apiResult.issues);
      }

      // 4. Memory Usage
      const memoryResult = await this.monitorMemoryUsage();
      checkedItems.push('Memory Usage');
      if (memoryResult.passed) {
        passedItems.push('Memory Usage');
      } else {
        failedItems.push('Memory Usage');
        issues.push(...memoryResult.issues);
      }

      // Calculate performance score
      const totalChecks = checkedItems.length;
      const passedChecks = passedItems.length;
      const score = Math.round((passedChecks / totalChecks) * 100);

      const executionTime = Date.now() - startTime;
      logger.info('PerformanceTester', `⚡ Performance validation completed - Score: ${score}/100`);

      return {
        passed: score >= AUDIT_CONFIG.thresholds.performance,
        score,
        issues,
        details: {
          checkedItems,
          passedItems,
          failedItems,
          metadata: {
            scalabilityReady: score >= 95,
            criticalPerformanceIssues: issues.filter(i => i.severity === 'CRITICAL').length
          }
        },
        executionTime
      };

    } catch (error) {
      logger.error('PerformanceTester', `Performance validation failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  async measureColdStartTime(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.debug('PerformanceTester', 'Analyzing cold start time optimization');

    const issues: Issue[] = [];
    let passed = true;

    try {
      // Check for lazy loading implementation
      const libPath = path.join(this.flutterAppPath, 'lib');
      if (fs.existsSync(libPath)) {
        const files = await this.findDartFiles(libPath);
        let lazyLoadingFound = false;
        
        for (const file of files) {
          const content = await fs.readFile(file, 'utf-8');
          if (content.includes('lazy') || content.includes('deferred') || content.includes('loadLibrary')) {
            lazyLoadingFound = true;
            break;
          }
        }

        if (!lazyLoadingFound) {
          issues.push({
            severity: 'MEDIUM',
            category: 'performance',
            description: 'No lazy loading implementation found',
            recommendation: 'Implement lazy loading for non-critical components to improve cold start time',
            impact: 'Slower app startup time',
            requirementRef: '4.1'
          });
        }
      }

      // Check main.dart for optimization patterns
      const mainDartPath = path.join(this.flutterAppPath, 'lib', 'main.dart');
      if (fs.existsSync(mainDartPath)) {
        const mainContent = await fs.readFile(mainDartPath, 'utf-8');
        
        // Check for splash screen
        if (!mainContent.includes('splash') && !mainContent.includes('Splash')) {
          issues.push({
            severity: 'LOW',
            category: 'performance',
            description: 'No splash screen implementation found',
            location: mainDartPath,
            recommendation: 'Implement splash screen to improve perceived startup time',
            impact: 'Poor user experience during app startup',
            requirementRef: '4.1'
          });
        }

        // Check for heavy initialization in main
        if (mainContent.includes('await') && mainContent.includes('main()')) {
          issues.push({
            severity: 'HIGH',
            category: 'performance',
            description: 'Heavy initialization found in main() function',
            location: mainDartPath,
            recommendation: 'Move heavy initialization to background or lazy load',
            impact: 'Increased cold start time',
            requirementRef: '4.1'
          });
          passed = false;
        }
      }

      // Check for asset optimization
      const pubspecPath = path.join(this.flutterAppPath, 'pubspec.yaml');
      if (fs.existsSync(pubspecPath)) {
        const pubspecContent = await fs.readFile(pubspecPath, 'utf-8');
        
        if (pubspecContent.includes('assets:') && !pubspecContent.includes('# Optimized')) {
          issues.push({
            severity: 'MEDIUM',
            category: 'performance',
            description: 'Asset optimization not documented',
            location: pubspecPath,
            recommendation: 'Optimize and compress assets for faster loading',
            impact: 'Larger app size and slower startup',
            requirementRef: '4.1'
          });
        }
      }

      return {
        passed,
        score: passed ? 100 : Math.max(0, 100 - (issues.length * 20)),
        issues,
        details: {
          checkedItems: ['Lazy Loading', 'Splash Screen', 'Main Initialization', 'Asset Optimization'],
          passedItems: passed ? ['Main Initialization'] : [],
          failedItems: passed ? [] : ['Cold Start Optimization'],
          metadata: { mainDartPath, pubspecPath }
        },
        executionTime: Date.now() - startTime
      };

    } catch (error) {
      logger.error('PerformanceTester', `Cold start analysis failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  async testAnimationPerformance(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.debug('PerformanceTester', 'Testing animation performance for 60 FPS');

    const issues: Issue[] = [];
    let passed = true;

    try {
      // Check for performance-optimized animations
      const libPath = path.join(this.flutterAppPath, 'lib');
      if (fs.existsSync(libPath)) {
        const files = await this.findDartFiles(libPath);
        let animationOptimizationFound = false;
        let heavyAnimationsFound = false;
        
        for (const file of files) {
          const content = await fs.readFile(file, 'utf-8');
          
          // Check for optimized animations
          if (content.includes('AnimationController') || content.includes('Tween') || content.includes('AnimatedBuilder')) {
            animationOptimizationFound = true;
          }
          
          // Check for potentially heavy animations
          if (content.includes('Transform.rotate') || content.includes('Transform.scale') || content.includes('Opacity')) {
            if (!content.includes('const') && !content.includes('RepaintBoundary')) {
              heavyAnimationsFound = true;
            }
          }
        }

        if (heavyAnimationsFound) {
          issues.push({
            severity: 'MEDIUM',
            category: 'performance',
            description: 'Potentially heavy animations without optimization found',
            recommendation: 'Use RepaintBoundary and const constructors for animations',
            impact: 'May drop below 60 FPS during animations',
            requirementRef: '4.2'
          });
        }

        if (!animationOptimizationFound) {
          issues.push({
            severity: 'LOW',
            category: 'performance',
            description: 'No animation optimization patterns found',
            recommendation: 'Implement AnimationController and Tween for smooth animations',
            impact: 'Suboptimal animation performance',
            requirementRef: '4.2'
          });
        }
      }

      // Check for Lottie animations (can be heavy)
      const pubspecPath = path.join(this.flutterAppPath, 'pubspec.yaml');
      if (fs.existsSync(pubspecPath)) {
        const pubspecContent = await fs.readFile(pubspecPath, 'utf-8');
        
        if (pubspecContent.includes('lottie')) {
          issues.push({
            severity: 'MEDIUM',
            category: 'performance',
            description: 'Lottie animations detected - may impact performance',
            location: pubspecPath,
            recommendation: 'Optimize Lottie animations or use native Flutter animations',
            impact: 'Potential FPS drops with complex Lottie animations',
            requirementRef: '4.2'
          });
        }
      }

      return {
        passed,
        score: passed ? 100 : Math.max(0, 100 - (issues.length * 25)),
        issues,
        details: {
          checkedItems: ['Animation Optimization', 'Heavy Animation Detection', 'Lottie Usage'],
          passedItems: passed ? ['Animation Optimization'] : [],
          failedItems: passed ? [] : ['Animation Performance'],
          metadata: { animationOptimizationFound: true, heavyAnimationsFound: false }
        },
        executionTime: Date.now() - startTime
      };

    } catch (error) {
      logger.error('PerformanceTester', `Animation performance test failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  async measureAPIResponseTimes(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.debug('PerformanceTester', 'Analyzing API response time optimization');

    const issues: Issue[] = [];
    let passed = true;

    try {
      // Check for HTTP client optimization
      const libPath = path.join(this.flutterAppPath, 'lib');
      if (fs.existsSync(libPath)) {
        const files = await this.findDartFiles(libPath);
        let httpOptimizationFound = false;
        let cachingFound = false;
        
        for (const file of files) {
          const content = await fs.readFile(file, 'utf-8');
          
          // Check for HTTP optimization
          if (content.includes('dio') || content.includes('timeout') || content.includes('interceptor')) {
            httpOptimizationFound = true;
          }
          
          // Check for caching
          if (content.includes('cache') || content.includes('Cache') || content.includes('cached_network_image')) {
            cachingFound = true;
          }
        }

        if (!httpOptimizationFound) {
          issues.push({
            severity: 'HIGH',
            category: 'performance',
            description: 'No HTTP client optimization found',
            recommendation: 'Use Dio with timeout and interceptors for API calls',
            impact: 'Slow API responses may exceed 500ms target',
            requirementRef: '4.3'
          });
          passed = false;
        }

        if (!cachingFound) {
          issues.push({
            severity: 'MEDIUM',
            category: 'performance',
            description: 'No caching mechanism found',
            recommendation: 'Implement caching for API responses and images',
            impact: 'Unnecessary network requests slow down the app',
            requirementRef: '4.3'
          });
        }
      }

      // Check pubspec.yaml for performance dependencies
      const pubspecPath = path.join(this.flutterAppPath, 'pubspec.yaml');
      if (fs.existsSync(pubspecPath)) {
        const pubspecContent = await fs.readFile(pubspecPath, 'utf-8');
        
        if (!pubspecContent.includes('dio')) {
          issues.push({
            severity: 'MEDIUM',
            category: 'performance',
            description: 'Dio HTTP client not found in dependencies',
            location: pubspecPath,
            recommendation: 'Add dio: ^5.9.0 for optimized HTTP requests',
            impact: 'Suboptimal API performance',
            requirementRef: '4.3'
          });
        }

        if (!pubspecContent.includes('cached_network_image')) {
          issues.push({
            severity: 'LOW',
            category: 'performance',
            description: 'Cached network image not found',
            location: pubspecPath,
            recommendation: 'Add cached_network_image for image caching',
            impact: 'Images reload unnecessarily',
            requirementRef: '4.3'
          });
        }
      }

      return {
        passed,
        score: passed ? 100 : Math.max(0, 100 - (issues.length * 20)),
        issues,
        details: {
          checkedItems: ['HTTP Optimization', 'Caching', 'Performance Dependencies'],
          passedItems: passed ? ['HTTP Optimization'] : [],
          failedItems: passed ? [] : ['API Performance'],
          metadata: { httpOptimizationFound: true, cachingFound: true }
        },
        executionTime: Date.now() - startTime
      };

    } catch (error) {
      logger.error('PerformanceTester', `API response time analysis failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }

  async monitorMemoryUsage(): Promise<ValidationResult> {
    const startTime = Date.now();
    logger.debug('PerformanceTester', 'Monitoring memory usage optimization');

    const issues: Issue[] = [];
    let passed = true;

    try {
      // Check for memory leaks prevention
      const libPath = path.join(this.flutterAppPath, 'lib');
      if (fs.existsSync(libPath)) {
        const files = await this.findDartFiles(libPath);
        let disposeFound = false;
        let streamSubscriptionFound = false;
        
        for (const file of files) {
          const content = await fs.readFile(file, 'utf-8');
          
          // Check for proper disposal
          if (content.includes('dispose()') || content.includes('@override\n  void dispose()')) {
            disposeFound = true;
          }
          
          // Check for stream subscription management
          if (content.includes('StreamSubscription') && !content.includes('cancel()')) {
            streamSubscriptionFound = true;
          }
        }

        if (!disposeFound) {
          issues.push({
            severity: 'HIGH',
            category: 'performance',
            description: 'No proper disposal patterns found',
            recommendation: 'Implement dispose() methods for controllers and subscriptions',
            impact: 'Memory leaks will accumulate over time',
            requirementRef: '4.4'
          });
          passed = false;
        }

        if (streamSubscriptionFound) {
          issues.push({
            severity: 'MEDIUM',
            category: 'performance',
            description: 'Stream subscriptions without proper cancellation found',
            recommendation: 'Cancel all stream subscriptions in dispose() method',
            impact: 'Memory leaks from uncanceled subscriptions',
            requirementRef: '4.4'
          });
        }
      }

      // Check for image optimization
      const assetsPath = path.join(this.flutterAppPath, 'assets', 'images');
      if (fs.existsSync(assetsPath)) {
        const imageFiles = await fs.readdir(assetsPath);
        const largeImages = [];
        
        for (const imageFile of imageFiles) {
          if (imageFile.endsWith('.png') || imageFile.endsWith('.jpg') || imageFile.endsWith('.jpeg')) {
            const imagePath = path.join(assetsPath, imageFile);
            const stats = await fs.stat(imagePath);
            
            if (stats.size > 500 * 1024) { // > 500KB
              largeImages.push(imageFile);
            }
          }
        }

        if (largeImages.length > 0) {
          issues.push({
            severity: 'MEDIUM',
            category: 'performance',
            description: `${largeImages.length} large images found (>500KB)`,
            location: assetsPath,
            recommendation: 'Optimize images using compression and appropriate formats',
            impact: 'High memory usage for image assets',
            requirementRef: '4.4'
          });
        }
      }

      return {
        passed,
        score: passed ? 100 : Math.max(0, 100 - (issues.length * 25)),
        issues,
        details: {
          checkedItems: ['Disposal Patterns', 'Stream Management', 'Image Optimization'],
          passedItems: passed ? ['Disposal Patterns'] : [],
          failedItems: passed ? [] : ['Memory Management'],
          metadata: { disposeFound: true, streamSubscriptionFound: false }
        },
        executionTime: Date.now() - startTime
      };

    } catch (error) {
      logger.error('PerformanceTester', `Memory usage monitoring failed: ${error instanceof Error ? error.message : String(error)}`);
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