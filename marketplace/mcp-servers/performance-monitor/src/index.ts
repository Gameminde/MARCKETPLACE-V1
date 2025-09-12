#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import fs from 'fs-extra';
import path from 'path';
import { glob } from 'glob';

interface PerformanceMetrics {
  fps: number;
  coldStartTime: number;
  apiResponseTime: number;
  memoryUsage: number;
  buildSize: number;
  animationFrameDrops: number;
}

class FlutterPerformanceServer {
  private server: Server;
  private targetFps: number;
  private maxColdStart: number;
  private maxApiResponse: number;

  constructor() {
    this.server = new Server(
      {
        name: 'flutter-performance-monitor',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.targetFps = parseInt(process.env.TARGET_FPS || '60');
    this.maxColdStart = parseInt(process.env.MAX_COLD_START || '3000');
    this.maxApiResponse = parseInt(process.env.MAX_API_RESPONSE || '500');

    this.setupToolHandlers();
  }

  private setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'analyze_flutter_performance',
            description: 'Analyze Flutter app performance metrics',
            inputSchema: {
              type: 'object',
              properties: {
                projectPath: {
                  type: 'string',
                  description: 'Path to Flutter project',
                },
              },
              required: ['projectPath'],
            },
          },
          {
            name: 'check_build_size',
            description: 'Check Flutter build size and optimization',
            inputSchema: {
              type: 'object',
              properties: {
                buildPath: {
                  type: 'string',
                  description: 'Path to Flutter build directory',
                },
              },
              required: ['buildPath'],
            },
          },
          {
            name: 'validate_animations',
            description: 'Validate animation performance',
            inputSchema: {
              type: 'object',
              properties: {
                projectPath: {
                  type: 'string',
                  description: 'Path to Flutter project',
                },
              },
              required: ['projectPath'],
            },
          },
          {
            name: 'memory_usage_analysis',
            description: 'Analyze memory usage patterns',
            inputSchema: {
              type: 'object',
              properties: {
                projectPath: {
                  type: 'string',
                  description: 'Path to Flutter project',
                },
              },
              required: ['projectPath'],
            },
          },
        ],
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      if (!args) {
        throw new Error('Missing arguments');
      }

      try {
        switch (name) {
          case 'analyze_flutter_performance':
            return await this.analyzePerformance(args.projectPath as string);
          
          case 'check_build_size':
            return await this.checkBuildSize(args.buildPath as string);
          
          case 'validate_animations':
            return await this.validateAnimations(args.projectPath as string);
          
          case 'memory_usage_analysis':
            return await this.analyzeMemoryUsage(args.projectPath as string);
          
          default:
            throw new Error(`Unknown tool: ${name}`);
        }
      } catch (error) {
        return {
          content: [
            {
              type: 'text',
              text: `Error: ${error instanceof Error ? error.message : String(error)}`,
            },
          ],
        };
      }
    });
  }

  private async analyzePerformance(projectPath: string) {
    const metrics = await this.gatherPerformanceMetrics(projectPath);
    
    const analysis = {
      overall_score: this.calculateOverallScore(metrics),
      metrics,
      recommendations: this.generateRecommendations(metrics),
      status: this.getPerformanceStatus(metrics),
    };

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(analysis, null, 2),
        },
      ],
    };
  }

  private async checkBuildSize(buildPath: string) {
    try {
      const apkFiles = await glob('**/*.apk', { cwd: buildPath });
      const sizeAnalysis = [];

      for (const apkFile of apkFiles) {
        const fullPath = path.join(buildPath, apkFile);
        const stats = await fs.stat(fullPath);
        const sizeInMB = (stats.size / (1024 * 1024)).toFixed(2);
        
        sizeAnalysis.push({
          file: apkFile,
          size_mb: parseFloat(sizeInMB),
          size_bytes: stats.size,
          status: parseFloat(sizeInMB) < 50 ? 'optimal' : 'needs_optimization',
        });
      }

      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify({
              build_size_analysis: sizeAnalysis,
              recommendations: this.getBuildSizeRecommendations(sizeAnalysis),
            }, null, 2),
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Build size analysis failed: ${error}`,
          },
        ],
      };
    }
  }

  private async validateAnimations(projectPath: string) {
    try {
      const dartFiles = await glob('**/*.dart', { cwd: projectPath });
      const animationAnalysis = {
        total_files: dartFiles.length,
        animation_files: 0,
        potential_issues: [] as Array<{file: string, issue: string}>,
        recommendations: [] as string[],
      };

      for (const file of dartFiles) {
        const content = await fs.readFile(path.join(projectPath, file), 'utf-8');
        
        if (content.includes('AnimationController') || content.includes('Tween')) {
          animationAnalysis.animation_files++;
          
          // Check for potential performance issues
          if (content.includes('setState') && content.includes('Animation')) {
            animationAnalysis.potential_issues.push({
              file,
              issue: 'setState in animation - consider AnimatedBuilder',
            });
          }
          
          if (!content.includes('dispose()') && content.includes('AnimationController')) {
            animationAnalysis.potential_issues.push({
              file,
              issue: 'AnimationController not disposed - memory leak risk',
            });
          }
        }
      }

      animationAnalysis.recommendations = this.getAnimationRecommendations(animationAnalysis);

      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(animationAnalysis, null, 2),
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Animation validation failed: ${error}`,
          },
        ],
      };
    }
  }

  private async analyzeMemoryUsage(projectPath: string) {
    try {
      const dartFiles = await glob('**/*.dart', { cwd: projectPath });
      const memoryAnalysis = {
        total_files: dartFiles.length,
        potential_memory_leaks: [] as Array<{file: string, issue: string}>,
        optimization_opportunities: [] as Array<{file: string, opportunity: string}>,
        score: 0,
      };

      for (const file of dartFiles) {
        const content = await fs.readFile(path.join(projectPath, file), 'utf-8');
        
        // Check for potential memory leaks
        if (content.includes('StreamController') && !content.includes('.close()')) {
          memoryAnalysis.potential_memory_leaks.push({
            file,
            issue: 'StreamController not closed',
          });
        }
        
        if (content.includes('Timer') && !content.includes('.cancel()')) {
          memoryAnalysis.potential_memory_leaks.push({
            file,
            issue: 'Timer not cancelled',
          });
        }
        
        // Check for optimization opportunities
        if (content.includes('ListView(') && !content.includes('ListView.builder')) {
          memoryAnalysis.optimization_opportunities.push({
            file,
            opportunity: 'Use ListView.builder for better memory efficiency',
          });
        }
      }

      memoryAnalysis.score = this.calculateMemoryScore(memoryAnalysis);

      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(memoryAnalysis, null, 2),
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: `Memory analysis failed: ${error}`,
          },
        ],
      };
    }
  }

  private async gatherPerformanceMetrics(projectPath: string): Promise<PerformanceMetrics> {
    // Mock metrics - in real implementation, this would gather actual metrics
    return {
      fps: 58, // Slightly below target
      coldStartTime: 2800, // Good
      apiResponseTime: 450, // Good
      memoryUsage: 85, // MB
      buildSize: 47.5, // MB
      animationFrameDrops: 2,
    };
  }

  private calculateOverallScore(metrics: PerformanceMetrics): number {
    let score = 100;
    
    if (metrics.fps < this.targetFps) score -= 10;
    if (metrics.coldStartTime > this.maxColdStart) score -= 15;
    if (metrics.apiResponseTime > this.maxApiResponse) score -= 10;
    if (metrics.memoryUsage > 100) score -= 10;
    if (metrics.buildSize > 50) score -= 5;
    if (metrics.animationFrameDrops > 0) score -= 5;
    
    return Math.max(0, score);
  }

  private generateRecommendations(metrics: PerformanceMetrics): string[] {
    const recommendations = [];
    
    if (metrics.fps < this.targetFps) {
      recommendations.push('Optimize animations and reduce widget rebuilds');
    }
    if (metrics.coldStartTime > this.maxColdStart) {
      recommendations.push('Reduce app initialization time');
    }
    if (metrics.buildSize > 50) {
      recommendations.push('Enable code splitting and tree shaking');
    }
    
    return recommendations;
  }

  private getPerformanceStatus(metrics: PerformanceMetrics): string {
    const score = this.calculateOverallScore(metrics);
    if (score >= 90) return 'excellent';
    if (score >= 75) return 'good';
    if (score >= 60) return 'needs_improvement';
    return 'poor';
  }

  private getBuildSizeRecommendations(sizeAnalysis: any[]): string[] {
    const recommendations = [];
    
    for (const analysis of sizeAnalysis) {
      if (analysis.size_mb > 50) {
        recommendations.push(`${analysis.file}: Consider enabling tree-shaking and code splitting`);
      }
    }
    
    return recommendations;
  }

  private getAnimationRecommendations(analysis: any): string[] {
    const recommendations = [];
    
    if (analysis.potential_issues.length > 0) {
      recommendations.push('Fix animation performance issues to prevent frame drops');
    }
    
    recommendations.push('Use AnimatedBuilder for complex animations');
    recommendations.push('Always dispose AnimationControllers to prevent memory leaks');
    
    return recommendations;
  }

  private calculateMemoryScore(analysis: any): number {
    let score = 100;
    score -= analysis.potential_memory_leaks.length * 10;
    score -= analysis.optimization_opportunities.length * 5;
    return Math.max(0, score);
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('Flutter Performance MCP Server running on stdio');
  }
}

const server = new FlutterPerformanceServer();
server.run().catch(console.error);