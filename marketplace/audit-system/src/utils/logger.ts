/**
 * Comprehensive logging utility for audit system
 */

import * as fs from 'fs-extra';
import * as path from 'path';
import chalk from 'chalk';

export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  CRITICAL = 4
}

export interface LogEntry {
  timestamp: Date;
  level: LogLevel;
  category: string;
  message: string;
  metadata?: any;
}

export class AuditLogger {
  private logEntries: LogEntry[] = [];
  private logFile: string;
  private minLevel: LogLevel;

  constructor(logFile: string = 'audit.log', minLevel: LogLevel = LogLevel.INFO) {
    this.logFile = path.resolve(logFile);
    this.minLevel = minLevel;
    this.ensureLogDirectory();
  }

  private ensureLogDirectory(): void {
    const logDir = path.dirname(this.logFile);
    fs.ensureDirSync(logDir);
  }

  private shouldLog(level: LogLevel): boolean {
    return level >= this.minLevel;
  }

  private formatMessage(entry: LogEntry): string {
    const timestamp = entry.timestamp.toISOString();
    const levelName = LogLevel[entry.level];
    const metadata = entry.metadata ? ` | ${JSON.stringify(entry.metadata)}` : '';
    return `[${timestamp}] ${levelName} [${entry.category}] ${entry.message}${metadata}`;
  }

  private getColorForLevel(level: LogLevel): (text: string) => string {
    switch (level) {
      case LogLevel.DEBUG: return chalk.gray;
      case LogLevel.INFO: return chalk.blue;
      case LogLevel.WARN: return chalk.yellow;
      case LogLevel.ERROR: return chalk.red;
      case LogLevel.CRITICAL: return chalk.bgRed.white;
      default: return chalk.white;
    }
  }

  log(level: LogLevel, category: string, message: string, metadata?: any): void {
    if (!this.shouldLog(level)) return;

    const entry: LogEntry = {
      timestamp: new Date(),
      level,
      category,
      message,
      metadata
    };

    this.logEntries.push(entry);

    // Console output with colors
    const colorFn = this.getColorForLevel(level);
    const formattedMessage = this.formatMessage(entry);
    console.log(colorFn(formattedMessage));

    // File output
    this.writeToFile(entry);
  }

  debug(category: string, message: string, metadata?: any): void {
    this.log(LogLevel.DEBUG, category, message, metadata);
  }

  info(category: string, message: string, metadata?: any): void {
    this.log(LogLevel.INFO, category, message, metadata);
  }

  warn(category: string, message: string, metadata?: any): void {
    this.log(LogLevel.WARN, category, message, metadata);
  }

  error(category: string, message: string, metadata?: any): void {
    this.log(LogLevel.ERROR, category, message, metadata);
  }

  critical(category: string, message: string, metadata?: any): void {
    this.log(LogLevel.CRITICAL, category, message, metadata);
  }

  private writeToFile(entry: LogEntry): void {
    const formattedMessage = this.formatMessage(entry);
    fs.appendFileSync(this.logFile, formattedMessage + '\n');
  }

  getLogEntries(level?: LogLevel): LogEntry[] {
    if (level !== undefined) {
      return this.logEntries.filter(entry => entry.level >= level);
    }
    return [...this.logEntries];
  }

  clearLogs(): void {
    this.logEntries = [];
    if (fs.existsSync(this.logFile)) {
      fs.unlinkSync(this.logFile);
    }
  }

  exportLogs(outputPath: string): void {
    const logs = this.logEntries.map(entry => this.formatMessage(entry)).join('\n');
    fs.writeFileSync(outputPath, logs);
  }
}

// Global logger instance
export const logger = new AuditLogger('logs/audit-system.log', LogLevel.INFO);