const winston = require('winston');

class LoggerService {
  constructor() {
    this.logger = winston.createLogger({
      level: process.env.LOG_LEVEL || 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
      ),
      transports: [
        new winston.transports.Console({
          format: winston.format.combine(
            winston.format.colorize(),
            winston.format.simple()
          )
        }),
        new winston.transports.File({
          filename: 'logs/app.log',
          level: 'info',
          maxsize: 5242880, // 5MB
          maxFiles: 5
        }),
        new winston.transports.File({
          filename: 'logs/error.log',
          level: 'error',
          maxsize: 5242880, // 5MB
          maxFiles: 5
        })
      ]
    });
  }

  info(message, meta = {}) {
    this.logger.info(message, {
      ...meta,
      timestamp: new Date().toISOString(),
      service: 'marketplace-api'
    });
  }

  error(message, meta = {}) {
    this.logger.error(message, {
      ...meta,
      timestamp: new Date().toISOString(),
      service: 'marketplace-api'
    });
  }

  warn(message, meta = {}) {
    this.logger.warn(message, {
      ...meta,
      timestamp: new Date().toISOString(),
      service: 'marketplace-api'
    });
  }

  debug(message, meta = {}) {
    this.logger.debug(message, {
      ...meta,
      timestamp: new Date().toISOString(),
      service: 'marketplace-api'
    });
  }

  logRequest(req, res, responseTime) {
    const logData = {
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      responseTime: `${responseTime}ms`,
      ip: req.ip,
      userAgent: req.headers['user-agent'],
      userId: req.user?.sub || 'anonymous'
    };

    if (res.statusCode >= 400) {
      this.warn('HTTP Request', logData);
    } else {
      this.info('HTTP Request', logData);
    }
  }

  logError(error, req = null) {
    const logData = {
      message: error.message,
      stack: error.stack,
      name: error.name,
      code: error.code
    };

    if (req) {
      logData.request = {
        method: req.method,
        url: req.url,
        ip: req.ip,
        userAgent: req.headers['user-agent'],
        userId: req.user?.sub || 'anonymous'
      };
    }

    this.error('Application Error', logData);
  }

  logSecurityEvent(event, data) {
    this.warn('Security Event', {
      event,
      ...data,
      timestamp: new Date().toISOString(),
      service: 'marketplace-api'
    });
  }

  logPerformanceMetric(metric, value, metadata = {}) {
    this.info('Performance Metric', {
      metric,
      value,
      ...metadata,
      timestamp: new Date().toISOString(),
      service: 'marketplace-api'
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

module.exports = new LoggerService();


