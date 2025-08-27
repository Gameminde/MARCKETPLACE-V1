const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');
const structuredLogger = require('./structured-logger.service');

// Optional Redis store - fallback to memory store if not available
let RedisStore;
try {
  RedisStore = require('rate-limit-redis');
} catch (e) {
  console.warn('rate-limit-redis not available, using memory store for rate limiting');
  RedisStore = null;
}

// SOLID: Interface Segregation - Different limiters for different needs
class RateLimitingService {
  constructor(redisClient, logger) {
    this.redis = redisClient;
    this.logger = logger || structuredLogger;
    this.stores = new Map();
    
    // Initialize rate limiting configurations
    this._initializeConfigurations();
  }

  // MANDATORY: Authentication endpoints protection
  createAuthRateLimit() {
    const store = this._createStore('auth');
    
    return rateLimit({
      windowMs: 15 * 60 * 1000, // 15 minutes
      max: 5, // 5 attempts per window
      message: {
        success: false,
        message: 'Too many authentication attempts, try again later',
        retryAfter: 15 * 60 * 1000,
        code: 'RATE_LIMIT_AUTH'
      },
      standardHeaders: true,
      legacyHeaders: false,
      store: store,
      keyGenerator: (req) => {
        // Rate limit by IP and email/username combination
        const identifier = req.body?.email || req.body?.username || 'unknown';
        return `auth_limit:${req.ip}:${identifier}`;
      },
      onLimitReached: (req, res, options) => {
        this.logger.warn('Authentication rate limit exceeded', {
          ip: req.ip,
          identifier: req.body?.email || req.body?.username,
          userAgent: req.get('User-Agent'),
          timestamp: new Date().toISOString()
        });
        
        // Additional security measures
        this._handleSuspiciousActivity(req, 'auth_rate_limit');
      },
      skip: (req) => {
        // Skip rate limiting for trusted IPs (if configured)
        const trustedIPs = process.env.TRUSTED_IPS?.split(',') || [];
        return trustedIPs.includes(req.ip);
      }
    });
  }

  // MANDATORY: API endpoints protection
  createAPIRateLimit() {
    const store = this._createStore('api');
    
    return rateLimit({
      windowMs: 1 * 60 * 1000, // 1 minute
      max: (req) => {
        // Authenticated users get higher limits
        if (req.user) {
          return req.user.role === 'premium' ? 200 : 100;
        }
        return 50; // Anonymous users
      },
      message: {
        success: false,
        message: 'API rate limit exceeded',
        retryAfter: 60 * 1000,
        code: 'RATE_LIMIT_API'
      },
      keyGenerator: (req) => {
        // Authenticated users get per-user limits
        if (req.user) {
          return `api_limit:user:${req.user.sub}`;
        }
        // Anonymous users limited by IP
        return `api_limit:ip:${req.ip}`;
      },
      onLimitReached: (req, res, options) => {
        this.logger.warn('API rate limit exceeded', {
          ip: req.ip,
          userId: req.user?.sub,
          endpoint: req.path,
          method: req.method
        });
      },
      store: store
    });
  }

  // MANDATORY: Upload endpoints protection
  createUploadRateLimit() {
    const store = this._createStore('upload');
    
    return rateLimit({
      windowMs: 60 * 60 * 1000, // 1 hour
      max: (req) => {
        if (req.user?.role === 'premium') return 100;
        if (req.user) return 50;
        return 10; // Anonymous users
      },
      message: {
        success: false,
        message: 'Upload rate limit exceeded',
        retryAfter: 60 * 60 * 1000,
        code: 'RATE_LIMIT_UPLOAD'
      },
      keyGenerator: (req) => {
        if (req.user) {
          return `upload_limit:user:${req.user.sub}`;
        }
        return `upload_limit:ip:${req.ip}`;
      },
      store: store
    });
  }

  // Registration rate limiting (stricter)
  createRegistrationRateLimit() {
    const store = this._createStore('registration');
    
    return rateLimit({
      windowMs: 60 * 60 * 1000, // 1 hour
      max: 3, // Only 3 registrations per hour per IP
      message: {
        success: false,
        message: 'Too many registration attempts, try again later',
        retryAfter: 60 * 60 * 1000,
        code: 'RATE_LIMIT_REGISTRATION'
      },
      keyGenerator: (req) => `registration_limit:${req.ip}`,
      store: store,
      onLimitReached: (req, res, options) => {
        this.logger.error('Registration rate limit exceeded - possible abuse', {
          ip: req.ip,
          userAgent: req.get('User-Agent'),
          email: req.body?.email
        });
        
        this._handleSuspiciousActivity(req, 'registration_abuse');
      }
    });
  }

  // Password reset rate limiting
  createPasswordResetRateLimit() {
    const store = this._createStore('password_reset');
    
    return rateLimit({
      windowMs: 15 * 60 * 1000, // 15 minutes
      max: 3, // 3 password reset attempts
      message: {
        success: false,
        message: 'Too many password reset attempts',
        retryAfter: 15 * 60 * 1000,
        code: 'RATE_LIMIT_PASSWORD_RESET'
      },
      keyGenerator: (req) => {
        const email = req.body?.email || 'unknown';
        return `password_reset_limit:${req.ip}:${email}`;
      },
      store: store
    });
  }

  // Slow down middleware for brute force protection
  createSlowDown(options = {}) {
    return slowDown({
      windowMs: options.windowMs || 15 * 60 * 1000, // 15 minutes
      delayAfter: options.delayAfter || 10, // Start slowing down after 10 requests
      delayMs: options.delayMs || 500, // Add 500ms delay per request
      maxDelayMs: options.maxDelayMs || 10000, // Maximum 10 second delay
      keyGenerator: options.keyGenerator || ((req) => req.ip),
      onLimitReached: (req, res, options) => {
        this.logger.warn('Slow down limit reached', {
          ip: req.ip,
          path: req.path,
          delay: options.delay
        });
      }
    });
  }

  // Advanced rate limiting with custom logic
  createAdvancedRateLimit(config) {
    return async (req, res, next) => {
      try {
        const key = config.keyGenerator(req);
        const window = config.windowMs || 60000;
        const limit = typeof config.max === 'function' ? config.max(req) : config.max;
        
        const current = await this._getRequestCount(key, window);
        
        if (current >= limit) {
          const resetTime = await this._getResetTime(key);
          
          res.set({
            'X-RateLimit-Limit': limit,
            'X-RateLimit-Remaining': 0,
            'X-RateLimit-Reset': resetTime
          });
          
          if (config.onLimitReached) {
            config.onLimitReached(req, res, { current, limit });
          }
          
          return res.status(429).json(config.message || {
            success: false,
            message: 'Rate limit exceeded'
          });
        }
        
        await this._incrementRequestCount(key, window);
        
        res.set({
          'X-RateLimit-Limit': limit,
          'X-RateLimit-Remaining': Math.max(0, limit - current - 1),
          'X-RateLimit-Reset': Math.ceil(Date.now() / 1000) + Math.ceil(window / 1000)
        });
        
        next();
      } catch (error) {
        this.logger.error('Rate limiting error', { error: error.message });
        // Fail open - allow request if rate limiting fails
        next();
      }
    };
  }

  // Distributed rate limiting for microservices
  createDistributedRateLimit(serviceName, config) {
    const key = `distributed:${serviceName}`;
    
    return this.createAdvancedRateLimit({
      ...config,
      keyGenerator: (req) => {
        const baseKey = config.keyGenerator ? config.keyGenerator(req) : req.ip;
        return `${key}:${baseKey}`;
      }
    });
  }

  // Initialize configurations
  _initializeConfigurations() {
    this.configs = {
      auth: {
        windowMs: 15 * 60 * 1000,
        max: 5,
        skipSuccessfulRequests: true
      },
      api: {
        windowMs: 60 * 1000,
        max: 100,
        skipSuccessfulRequests: false
      },
      upload: {
        windowMs: 60 * 60 * 1000,
        max: 50,
        skipSuccessfulRequests: true
      }
    };
  }

  _createStore(type) {
    if (this.stores.has(type)) {
      return this.stores.get(type);
    }

    let store;
    
    if (this.redis && RedisStore) {
      // Use Redis store for production
      store = new RedisStore({
        sendCommand: (...args) => this.redis.call(...args),
        prefix: `rate_limit:${type}:`
      });
    } else {
      // Use memory store for development
      store = new Map();
      this.logger.warn(`Using memory store for rate limiting: ${type}. Use Redis in production.`);
    }

    this.stores.set(type, store);
    return store;
  }

  async _getRequestCount(key, windowMs) {
    if (!this.redis) {
      // Fallback for development
      return 0;
    }

    try {
      const count = await this.redis.get(key);
      return parseInt(count) || 0;
    } catch (error) {
      this.logger.error('Failed to get request count', { error: error.message, key });
      return 0;
    }
  }

  async _incrementRequestCount(key, windowMs) {
    if (!this.redis) {
      return;
    }

    try {
      const pipeline = this.redis.pipeline();
      pipeline.incr(key);
      pipeline.expire(key, Math.ceil(windowMs / 1000));
      await pipeline.exec();
    } catch (error) {
      this.logger.error('Failed to increment request count', { error: error.message, key });
    }
  }

  async _getResetTime(key) {
    if (!this.redis) {
      return Math.ceil(Date.now() / 1000) + 60;
    }

    try {
      const ttl = await this.redis.ttl(key);
      return Math.ceil(Date.now() / 1000) + ttl;
    } catch (error) {
      return Math.ceil(Date.now() / 1000) + 60;
    }
  }

  _handleSuspiciousActivity(req, type) {
    // Log suspicious activity for security monitoring
    this.logger.error('Suspicious activity detected', {
      type,
      ip: req.ip,
      userAgent: req.get('User-Agent'),
      path: req.path,
      method: req.method,
      timestamp: new Date().toISOString(),
      headers: {
        'x-forwarded-for': req.get('X-Forwarded-For'),
        'x-real-ip': req.get('X-Real-IP')
      }
    });

    // In production, you might want to:
    // 1. Add IP to temporary blacklist
    // 2. Send alert to security team
    // 3. Trigger additional security measures
  }

  // Get rate limiting statistics
  async getStats() {
    const stats = {};
    
    for (const [type, store] of this.stores.entries()) {
      if (this.redis) {
        try {
          const keys = await this.redis.keys(`rate_limit:${type}:*`);
          stats[type] = {
            activeKeys: keys.length,
            type: 'redis'
          };
        } catch (error) {
          stats[type] = { error: error.message };
        }
      } else {
        stats[type] = {
          activeKeys: store.size,
          type: 'memory'
        };
      }
    }
    
    return stats;
  }

  // Clear rate limiting data (for testing)
  async clearAll() {
    if (process.env.NODE_ENV !== 'test') {
      throw new Error('clearAll() can only be used in test environment');
    }

    for (const [type, store] of this.stores.entries()) {
      if (this.redis) {
        const keys = await this.redis.keys(`rate_limit:${type}:*`);
        if (keys.length > 0) {
          await this.redis.del(...keys);
        }
      } else {
        store.clear();
      }
    }
  }
}

module.exports = RateLimitingService;