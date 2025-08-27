const winston = require('winston');

class StructuredLogger {
  constructor() {
    this.logger = winston.createLogger({
      level: process.env.LOG_LEVEL || 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json(),
        winston.format((info) => {
          info.service = 'marketplace-auth';
          info.version = process.env.npm_package_version || '1.0.0';
          info.environment = process.env.NODE_ENV || 'development';
          info.hostname = require('os').hostname();
          return info;
        })()
      ),
      transports: [
        new winston.transports.Console({
          format: winston.format.combine(
            winston.format.colorize(),
            winston.format.simple()
          )
        }),
        new winston.transports.File({
          filename: 'logs/auth-audit.log',
          level: 'info',
          maxsize: 5242880, // 5MB
          maxFiles: 5
        }),
        new winston.transports.File({
          filename: 'logs/auth-errors.log',
          level: 'error',
          maxsize: 5242880, // 5MB
          maxFiles: 5
        })
      ]
    });
    this.setupElasticsearch();
  }

  setupElasticsearch() {
    // Configuration Elasticsearch optionnelle
    if (process.env.ELASTICSEARCH_URL) {
      // Implémentation Elasticsearch
    }
  }

  logAuthEvent(eventType, data) {
    this.logger.info('Auth Event', {
      eventType,
      ...data,
      timestamp: new Date().toISOString()
    });
  }

  logSecurityEvent(eventType, data) {
    this.logger.warn('Security Event', {
      eventType,
      ...data,
      timestamp: new Date().toISOString()
    });
  }

  logPerformanceMetric(metric, value, metadata = {}) {
    this.logger.info('Performance Metric', {
      metric,
      value,
      ...metadata,
      timestamp: new Date().toISOString()
    });
  }

  logError(error, context = {}) {
    this.logger.error('Error', {
      message: error.message,
      stack: error.stack,
      ...context,
      timestamp: new Date().toISOString()
    });
  }

  logWarning(message, context = {}) {
    this.logger.warn('Warning', {
      message,
      ...context,
      timestamp: new Date().toISOString()
    });
  }

  logInfo(message, context = {}) {
    this.logger.info('Info', {
      message,
      ...context,
      timestamp: new Date().toISOString()
    });
  }

  logBruteForceAttempt(ip, email, userAgent) {
    this.logSecurityEvent('BRUTE_FORCE_ATTEMPT', {
      ip,
      email,
      userAgent,
      timestamp: new Date().toISOString()
    });
  }

  logUserStatusChange(userId, oldStatus, newStatus, reason) {
    this.logInfo('User Status Change', {
      userId,
      oldStatus,
      newStatus,
      reason,
      timestamp: new Date().toISOString()
    });
  }

  logAdminAction(adminId, action, target, details) {
    this.logInfo('Admin Action', {
      adminId,
      action,
      target,
      details,
      timestamp: new Date().toISOString()
    });
  }

  getStats() {
    return {
      level: this.logger.level,
      transports: this.logger.transports.length,
      timestamp: new Date().toISOString()
    };
  }
}

module.exports = new StructuredLogger();


