const crypto = require('crypto');
const structuredLogger = require('../services/structured-logger.service');

class CSRFMiddleware {
  constructor() {
    this.secret = process.env.CSRF_SECRET || crypto.randomBytes(32).toString('hex');
    this.tokenExpiry = 24 * 60 * 60 * 1000; // 24 hours
    this.tokens = new Map(); // In production, use Redis
  }

  generateToken(req, res, next) {
    try {
      const sessionId = req.sessionID || req.ip;
      const timestamp = Date.now();
      const randomBytes = crypto.randomBytes(16).toString('hex');
      
      const tokenData = `${sessionId}:${timestamp}:${randomBytes}`;
      const token = crypto
        .createHmac('sha256', this.secret)
        .update(tokenData)
        .digest('hex');

      // Store token with expiry
      this.tokens.set(token, {
        sessionId,
        timestamp,
        expires: timestamp + this.tokenExpiry
      });

      // Clean expired tokens
      this.cleanExpiredTokens();

      res.locals.csrfToken = token;
      res.cookie('XSRF-TOKEN', token, {
        httpOnly: false,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: this.tokenExpiry
      });

      next();
    } catch (error) {
      structuredLogger.logError('CSRF_TOKEN_GENERATION_FAILED', {
        error: error.message,
        sessionId: req.sessionID || req.ip
      });
      next(error);
    }
  }

  validateToken(req, res, next) {
    try {
      // Skip CSRF for safe methods
      if (['GET', 'HEAD', 'OPTIONS'].includes(req.method)) {
        return next();
      }

      const token = req.headers['x-csrf-token'] || req.body._csrf || req.query._csrf;
      
      if (!token) {
        return res.status(403).json({
          success: false,
          error: {
            code: 'CSRF_TOKEN_MISSING',
            message: 'CSRF token is required for this request'
          }
        });
      }

      const tokenData = this.tokens.get(token);
      if (!tokenData) {
        return res.status(403).json({
          success: false,
          error: {
            code: 'CSRF_TOKEN_INVALID',
            message: 'Invalid CSRF token'
          }
        });
      }

      // Check expiry
      if (Date.now() > tokenData.expires) {
        this.tokens.delete(token);
        return res.status(403).json({
          success: false,
          error: {
            code: 'CSRF_TOKEN_EXPIRED',
            message: 'CSRF token has expired'
          }
        });
      }

      // Verify session
      const sessionId = req.sessionID || req.ip;
      if (tokenData.sessionId !== sessionId) {
        return res.status(403).json({
          success: false,
          error: {
            code: 'CSRF_TOKEN_MISMATCH',
            message: 'CSRF token does not match session'
          }
        });
      }

      next();
    } catch (error) {
      structuredLogger.logError('CSRF_VALIDATION_FAILED', {
        error: error.message,
        token: req.headers['x-csrf-token'] ? 'present' : 'missing'
      });
      next(error);
    }
  }

  cleanExpiredTokens() {
    const now = Date.now();
    for (const [token, data] of this.tokens.entries()) {
      if (now > data.expires) {
        this.tokens.delete(token);
      }
    }
  }

  // Middleware for API routes that need CSRF protection
  protect() {
    return [this.generateToken, this.validateToken];
  }
}

module.exports = new CSRFMiddleware();
