const structuredLogger = require('./structured-logger.service');
const crypto = require('crypto');

// PHASE 3: Comprehensive Security Monitoring Service
class SecurityMonitoringService {
  constructor(logger) {
    this.logger = logger || structuredLogger;
    this.securityEvents = new Map();
    this.suspiciousIPs = new Set();
    this.alertThresholds = this._initializeThresholds();
    
    // Initialize monitoring
    this._startMonitoring();
  }

  // Log security events
  logSecurityEvent(type, details) {
    const event = {
      id: crypto.randomUUID(),
      type,
      timestamp: new Date().toISOString(),
      severity: this._getSeverity(type),
      details,
      hash: this._generateEventHash(type, details)
    };

    // Store event
    this._storeEvent(event);

    // Log to structured logger
    this.logger.security(event.severity, `Security event: ${type}`, event);

    // Check for patterns and trigger alerts
    this._analyzeEvent(event);

    return event.id;
  }

  // Authentication monitoring
  logAuthEvent(type, userId, ip, userAgent, details = {}) {
    return this.logSecurityEvent('auth_event', {
      authType: type,
      userId,
      ip,
      userAgent,
      success: details.success !== false,
      reason: details.reason,
      ...details
    });
  }

  // Failed login attempts
  logFailedLogin(email, ip, userAgent, reason) {
    const eventId = this.logAuthEvent('failed_login', null, ip, userAgent, {
      email,
      reason,
      success: false
    });

    // Check for brute force patterns
    this._checkBruteForcePattern(ip, email);

    return eventId;
  }

  // Successful login
  logSuccessfulLogin(userId, ip, userAgent, details = {}) {
    return this.logAuthEvent('successful_login', userId, ip, userAgent, {
      ...details,
      success: true
    });
  }

  // Suspicious activity detection
  logSuspiciousActivity(type, details) {
    const eventId = this.logSecurityEvent('suspicious_activity', {
      activityType: type,
      ...details
    });

    // Add IP to suspicious list if provided
    if (details.ip) {
      this.suspiciousIPs.add(details.ip);
      
      // Auto-expire suspicious IPs after 24 hours
      setTimeout(() => {
        this.suspiciousIPs.delete(details.ip);
      }, 24 * 60 * 60 * 1000);
    }

    return eventId;
  }

  // Rate limiting violations
  logRateLimitViolation(type, identifier, details) {
    return this.logSecurityEvent('rate_limit_violation', {
      limitType: type,
      identifier,
      ...details
    });
  }

  // Input validation failures
  logValidationFailure(endpoint, errors, ip, userId = null) {
    return this.logSecurityEvent('validation_failure', {
      endpoint,
      errors: errors.map(e => ({
        field: e.field,
        message: e.message,
        value: this._sanitizeValue(e.value)
      })),
      ip,
      userId
    });
  }

  // Malicious content detection
  logMaliciousContent(type, content, ip, userId = null) {
    return this.logSecurityEvent('malicious_content', {
      contentType: type,
      contentSample: content.substring(0, 100) + '...',
      contentHash: crypto.createHash('sha256').update(content).digest('hex'),
      ip,
      userId
    });
  }

  // Token security events
  logTokenEvent(type, userId, tokenId, details = {}) {
    return this.logSecurityEvent('token_event', {
      tokenType: type,
      userId,
      tokenId,
      ...details
    });
  }

  // File upload security events
  logFileUploadEvent(filename, mimetype, size, ip, userId, issues = []) {
    return this.logSecurityEvent('file_upload', {
      filename: this._sanitizeFilename(filename),
      mimetype,
      size,
      ip,
      userId,
      issues,
      safe: issues.length === 0
    });
  }

  // API abuse detection
  logAPIAbuse(endpoint, ip, userId, abuseType, details = {}) {
    return this.logSecurityEvent('api_abuse', {
      endpoint,
      ip,
      userId,
      abuseType,
      ...details
    });
  }

  // Get security statistics
  getSecurityStats(timeframe = '24h') {
    const since = this._getTimeframeCutoff(timeframe);
    const events = Array.from(this.securityEvents.values())
      .filter(event => new Date(event.timestamp) > since);

    const stats = {
      totalEvents: events.length,
      eventsByType: {},
      eventsBySeverity: {},
      suspiciousIPs: this.suspiciousIPs.size,
      topThreats: this._getTopThreats(events),
      timeframe,
      generatedAt: new Date().toISOString()
    };

    // Group by type
    events.forEach(event => {
      stats.eventsByType[event.type] = (stats.eventsByType[event.type] || 0) + 1;
      stats.eventsBySeverity[event.severity] = (stats.eventsBySeverity[event.severity] || 0) + 1;
    });

    return stats;
  }

  // Get security alerts
  getActiveAlerts() {
    const alerts = [];
    const now = new Date();
    const oneHour = 60 * 60 * 1000;

    // Check for recent high-severity events
    const recentEvents = Array.from(this.securityEvents.values())
      .filter(event => 
        new Date(event.timestamp) > new Date(now - oneHour) &&
        ['high', 'critical'].includes(event.severity)
      );

    if (recentEvents.length > 0) {
      alerts.push({
        type: 'high_severity_events',
        message: `${recentEvents.length} high/critical security events in the last hour`,
        severity: 'warning',
        count: recentEvents.length
      });
    }

    // Check for suspicious IP activity
    if (this.suspiciousIPs.size > 10) {
      alerts.push({
        type: 'suspicious_ips',
        message: `${this.suspiciousIPs.size} suspicious IPs detected`,
        severity: 'warning',
        count: this.suspiciousIPs.size
      });
    }

    return alerts;
  }

  // Check if IP is suspicious
  isSuspiciousIP(ip) {
    return this.suspiciousIPs.has(ip);
  }

  // Generate security report
  generateSecurityReport(timeframe = '24h') {
    const stats = this.getSecurityStats(timeframe);
    const alerts = this.getActiveAlerts();
    
    const report = {
      summary: {
        timeframe,
        totalEvents: stats.totalEvents,
        alertsCount: alerts.length,
        suspiciousIPs: stats.suspiciousIPs,
        overallRisk: this._calculateRiskLevel(stats, alerts)
      },
      statistics: stats,
      alerts,
      recommendations: this._generateRecommendations(stats, alerts),
      generatedAt: new Date().toISOString()
    };

    // Log report generation
    this.logger.info('Security report generated', {
      timeframe,
      totalEvents: stats.totalEvents,
      alertsCount: alerts.length,
      riskLevel: report.summary.overallRisk
    });

    return report;
  }

  // Initialize alert thresholds
  _initializeThresholds() {
    return {
      failedLogins: {
        perIP: { count: 10, window: 15 * 60 * 1000 }, // 10 attempts per 15 minutes
        perEmail: { count: 5, window: 15 * 60 * 1000 } // 5 attempts per 15 minutes
      },
      rateLimitViolations: {
        perIP: { count: 5, window: 60 * 1000 } // 5 violations per minute
      },
      validationFailures: {
        perIP: { count: 20, window: 60 * 1000 } // 20 failures per minute
      }
    };
  }

  // Store security event
  _storeEvent(event) {
    this.securityEvents.set(event.id, event);

    // Cleanup old events (keep last 10000 events)
    if (this.securityEvents.size > 10000) {
      const oldestEvents = Array.from(this.securityEvents.entries())
        .sort(([,a], [,b]) => new Date(a.timestamp) - new Date(b.timestamp))
        .slice(0, 1000);

      oldestEvents.forEach(([id]) => {
        this.securityEvents.delete(id);
      });
    }
  }

  // Analyze event for patterns
  _analyzeEvent(event) {
    switch (event.type) {
      case 'auth_event':
        if (event.details.authType === 'failed_login') {
          this._checkBruteForcePattern(event.details.ip, event.details.email);
        }
        break;
      
      case 'rate_limit_violation':
        this._checkRateLimitAbuse(event.details.identifier);
        break;
      
      case 'validation_failure':
        this._checkValidationAbuse(event.details.ip);
        break;
    }
  }

  // Check for brute force patterns
  _checkBruteForcePattern(ip, email) {
    const now = Date.now();
    const threshold = this.alertThresholds.failedLogins;

    // Check IP-based pattern
    const ipEvents = Array.from(this.securityEvents.values())
      .filter(event => 
        event.type === 'auth_event' &&
        event.details.authType === 'failed_login' &&
        event.details.ip === ip &&
        now - new Date(event.timestamp).getTime() < threshold.perIP.window
      );

    if (ipEvents.length >= threshold.perIP.count) {
      this.logSuspiciousActivity('brute_force_ip', {
        ip,
        attemptCount: ipEvents.length,
        timeWindow: threshold.perIP.window
      });
    }

    // Check email-based pattern
    if (email) {
      const emailEvents = Array.from(this.securityEvents.values())
        .filter(event => 
          event.type === 'auth_event' &&
          event.details.authType === 'failed_login' &&
          event.details.email === email &&
          now - new Date(event.timestamp).getTime() < threshold.perEmail.window
        );

      if (emailEvents.length >= threshold.perEmail.count) {
        this.logSuspiciousActivity('brute_force_email', {
          email,
          attemptCount: emailEvents.length,
          timeWindow: threshold.perEmail.window
        });
      }
    }
  }

  // Check for rate limit abuse
  _checkRateLimitAbuse(identifier) {
    const now = Date.now();
    const threshold = this.alertThresholds.rateLimitViolations.perIP;

    const violations = Array.from(this.securityEvents.values())
      .filter(event => 
        event.type === 'rate_limit_violation' &&
        event.details.identifier === identifier &&
        now - new Date(event.timestamp).getTime() < threshold.window
      );

    if (violations.length >= threshold.count) {
      this.logSuspiciousActivity('rate_limit_abuse', {
        identifier,
        violationCount: violations.length,
        timeWindow: threshold.window
      });
    }
  }

  // Check for validation abuse
  _checkValidationAbuse(ip) {
    const now = Date.now();
    const threshold = this.alertThresholds.validationFailures.perIP;

    const failures = Array.from(this.securityEvents.values())
      .filter(event => 
        event.type === 'validation_failure' &&
        event.details.ip === ip &&
        now - new Date(event.timestamp).getTime() < threshold.window
      );

    if (failures.length >= threshold.count) {
      this.logSuspiciousActivity('validation_abuse', {
        ip,
        failureCount: failures.length,
        timeWindow: threshold.window
      });
    }
  }

  // Get severity level for event type
  _getSeverity(type) {
    const severityMap = {
      'auth_event': 'medium',
      'suspicious_activity': 'high',
      'rate_limit_violation': 'medium',
      'validation_failure': 'low',
      'malicious_content': 'high',
      'token_event': 'medium',
      'file_upload': 'medium',
      'api_abuse': 'high'
    };

    return severityMap[type] || 'low';
  }

  // Generate event hash for deduplication
  _generateEventHash(type, details) {
    const hashInput = JSON.stringify({ type, ...details });
    return crypto.createHash('md5').update(hashInput).digest('hex');
  }

  // Sanitize sensitive values
  _sanitizeValue(value) {
    if (typeof value === 'string' && value.length > 100) {
      return value.substring(0, 100) + '...';
    }
    return value;
  }

  // Sanitize filename
  _sanitizeFilename(filename) {
    return filename.replace(/[<>:"/\\|?*]/g, '_');
  }

  // Get timeframe cutoff
  _getTimeframeCutoff(timeframe) {
    const now = new Date();
    const cutoffs = {
      '1h': 60 * 60 * 1000,
      '24h': 24 * 60 * 60 * 1000,
      '7d': 7 * 24 * 60 * 60 * 1000,
      '30d': 30 * 24 * 60 * 60 * 1000
    };

    const offset = cutoffs[timeframe] || cutoffs['24h'];
    return new Date(now.getTime() - offset);
  }

  // Get top threats
  _getTopThreats(events) {
    const threats = {};
    
    events.forEach(event => {
      if (event.severity === 'high' || event.severity === 'critical') {
        const key = `${event.type}:${event.details.ip || 'unknown'}`;
        threats[key] = (threats[key] || 0) + 1;
      }
    });

    return Object.entries(threats)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 10)
      .map(([threat, count]) => ({ threat, count }));
  }

  // Calculate overall risk level
  _calculateRiskLevel(stats, alerts) {
    let riskScore = 0;

    // Base score from event count
    riskScore += Math.min(stats.totalEvents / 100, 5);

    // Add score for high severity events
    riskScore += (stats.eventsBySeverity.high || 0) * 2;
    riskScore += (stats.eventsBySeverity.critical || 0) * 5;

    // Add score for alerts
    riskScore += alerts.length * 3;

    // Add score for suspicious IPs
    riskScore += Math.min(stats.suspiciousIPs / 10, 3);

    if (riskScore >= 15) return 'critical';
    if (riskScore >= 10) return 'high';
    if (riskScore >= 5) return 'medium';
    return 'low';
  }

  // Generate security recommendations
  _generateRecommendations(stats, alerts) {
    const recommendations = [];

    if (stats.eventsBySeverity.high > 10) {
      recommendations.push({
        type: 'high_severity_events',
        message: 'High number of high-severity security events detected',
        action: 'Review security logs and investigate potential threats'
      });
    }

    if (stats.suspiciousIPs > 5) {
      recommendations.push({
        type: 'suspicious_ips',
        message: 'Multiple suspicious IPs detected',
        action: 'Consider implementing IP-based blocking or additional verification'
      });
    }

    if (stats.eventsByType.rate_limit_violation > 20) {
      recommendations.push({
        type: 'rate_limiting',
        message: 'High number of rate limit violations',
        action: 'Review and potentially tighten rate limiting rules'
      });
    }

    return recommendations;
  }

  // Start monitoring background tasks
  _startMonitoring() {
    // Cleanup old events every hour
    setInterval(() => {
      const cutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000); // 7 days
      const eventsToDelete = [];

      for (const [id, event] of this.securityEvents.entries()) {
        if (new Date(event.timestamp) < cutoff) {
          eventsToDelete.push(id);
        }
      }

      eventsToDelete.forEach(id => {
        this.securityEvents.delete(id);
      });

      if (eventsToDelete.length > 0) {
        this.logger.info('Cleaned up old security events', {
          deletedCount: eventsToDelete.length
        });
      }
    }, 60 * 60 * 1000); // Every hour
  }
}

module.exports = SecurityMonitoringService;