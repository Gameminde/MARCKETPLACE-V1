/**
 * Comprehensive error handling for audit system
 */

import { logger } from './logger';

export enum AuditErrorType {
  SYSTEM_ERROR = 'SYSTEM_ERROR',
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  RUNTIME_ERROR = 'RUNTIME_ERROR',
  CONFIGURATION_ERROR = 'CONFIGURATION_ERROR'
}

export class AuditError extends Error {
  public readonly type: AuditErrorType;
  public readonly category: string;
  public readonly recoverable: boolean;
  public readonly metadata?: any;

  constructor(
    type: AuditErrorType,
    category: string,
    message: string,
    recoverable: boolean = true,
    metadata?: any
  ) {
    super(message);
    this.name = 'AuditError';
    this.type = type;
    this.category = category;
    this.recoverable = recoverable;
    this.metadata = metadata;
  }
}

export class SystemError extends AuditError {
  constructor(category: string, message: string, metadata?: any) {
    super(AuditErrorType.SYSTEM_ERROR, category, message, false, metadata);
  }
}

export class ValidationError extends AuditError {
  constructor(category: string, message: string, metadata?: any) {
    super(AuditErrorType.VALIDATION_ERROR, category, message, true, metadata);
  }
}

export class RuntimeError extends AuditError {
  constructor(category: string, message: string, metadata?: any) {
    super(AuditErrorType.RUNTIME_ERROR, category, message, true, metadata);
  }
}

export class ConfigurationError extends AuditError {
  constructor(category: string, message: string, metadata?: any) {
    super(AuditErrorType.CONFIGURATION_ERROR, category, message, false, metadata);
  }
}

export interface ErrorReport {
  totalErrors: number;
  criticalErrors: number;
  recoverableErrors: number;
  errorsByCategory: Record<string, number>;
  errorsByType: Record<AuditErrorType, number>;
  errors: AuditError[];
}

export class AuditErrorHandler {
  private errors: AuditError[] = [];
  private maxRetries: number = 3;
  private retryDelay: number = 1000;

  handleError(error: AuditError): void {
    this.errors.push(error);
    
    // Log the error
    if (error.recoverable) {
      logger.warn(error.category, `Recoverable error: ${error.message}`, error.metadata);
    } else {
      logger.error(error.category, `Critical error: ${error.message}`, error.metadata);
    }
  }

  async handleWithRetry<T>(
    operation: () => Promise<T>,
    category: string,
    operationName: string
  ): Promise<T> {
    let lastError: Error | null = null;
    
    for (let attempt = 1; attempt <= this.maxRetries; attempt++) {
      try {
        logger.debug(category, `Attempting ${operationName} (attempt ${attempt}/${this.maxRetries})`);
        return await operation();
      } catch (error) {
        lastError = error as Error;
        
        if (attempt < this.maxRetries) {
          logger.warn(category, `${operationName} failed, retrying in ${this.retryDelay}ms`, {
            attempt,
            error: error instanceof Error ? error.message : String(error)
          });
          await this.delay(this.retryDelay);
        }
      }
    }
    
    // All retries failed
    const auditError = new RuntimeError(
      category,
      `${operationName} failed after ${this.maxRetries} attempts: ${lastError?.message}`,
      { lastError, attempts: this.maxRetries }
    );
    
    this.handleError(auditError);
    throw auditError;
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  generateErrorReport(): ErrorReport {
    const errorsByCategory: Record<string, number> = {};
    const errorsByType: Record<AuditErrorType, number> = {
      [AuditErrorType.SYSTEM_ERROR]: 0,
      [AuditErrorType.VALIDATION_ERROR]: 0,
      [AuditErrorType.RUNTIME_ERROR]: 0,
      [AuditErrorType.CONFIGURATION_ERROR]: 0
    };
    
    let criticalErrors = 0;
    let recoverableErrors = 0;
    
    for (const error of this.errors) {
      // Count by category
      errorsByCategory[error.category] = (errorsByCategory[error.category] || 0) + 1;
      
      // Count by type
      errorsByType[error.type] = (errorsByType[error.type] || 0) + 1;
      
      // Count by recoverability
      if (error.recoverable) {
        recoverableErrors++;
      } else {
        criticalErrors++;
      }
    }
    
    return {
      totalErrors: this.errors.length,
      criticalErrors,
      recoverableErrors,
      errorsByCategory,
      errorsByType,
      errors: [...this.errors]
    };
  }

  clearErrors(): void {
    this.errors = [];
  }

  hasErrors(): boolean {
    return this.errors.length > 0;
  }

  hasCriticalErrors(): boolean {
    return this.errors.some(error => !error.recoverable);
  }

  getErrors(): AuditError[] {
    return [...this.errors];
  }
}

// Global error handler instance
export const errorHandler = new AuditErrorHandler();