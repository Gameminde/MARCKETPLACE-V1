const { RateLimiterRedis } = require('rate-limiter-flexible');
const redisClientService = require('../services/redis-client.service');
const structuredLogger = require('../services/structured-logger.service');

class RateLimitingMiddleware {
  constructor() {
    this.redisClient = redisClientService;
    this.limiters = new Map();
    this.initializeLimiters();
  }

  initializeLimiters() {
    // General API rate limiter
    this.limiters.set('general', new RateLimiterRedis({
      storeClient: this.redisClient.getClient(),
      keyPrefix: 'rl_general',
      points: parseInt(process.env.RATE_LIMIT_GENERAL_POINTS) || 100,
      duration: parseInt(process.env.RATE_LIMIT_GENERAL_DURATION) || 900, // 15 minutes
      blockDuration: parseInt(process.env.RATE_LIMIT_GENERAL_BLOCK) || 900,
    }));

    // Strict rate limiter for auth endpoints
    this.limiters.set('auth', new RateLimiterRedis({
      storeClient: this.redisClient.getClient(),
      keyPrefix: 'rl_auth',
      points: parseInt(process.env.RATE_LIMIT_AUTH_POINTS) || 10,
      duration: parseInt(process.env.RATE_LIMIT_AUTH_DURATION) || 900, // 15 minutes
      blockDuration: parseInt(process.env.RATE_LIMIT_AUTH_BLOCK) || 1800, // 30 minutes
    }));

    // Upload rate limiter
    this.limiters.set('upload', new RateLimiterRedis({
      storeClient: this.redisClient.getClient(),
      keyPrefix: 'rl_upload',
      points: parseInt(process.env.RATE_LIMIT_UPLOAD_POINTS) || 5,
      duration: parseInt(process.env.RATE_LIMIT_UPLOAD_DURATION) || 3600, // 1 hour
      blockDuration: parseInt(process.env.RATE_LIMIT_UPLOAD_BLOCK) || 3600,
    }));

    // Search rate limiter
    this.limiters.set('search', new RateLimiterRedis({
      storeClient: this.redisClient.getClient(),
      keyPrefix: 'rl_search',
      points: parseInt(process.env.RATE_LIMIT_SEARCH_POINTS) || 50,
      duration: parseInt(process.env.RATE_LIMIT_SEARCH_DURATION) || 60, // 1 minute
      blockDuration: parseInt(process.env.RATE_LIMIT_SEARCH_BLOCK) || 300, // 5 minutes
    }));

    // Payment rate limiter
    this.limiters.set('payment', new RateLimiterRedis({
      storeClient: this.redisClient.getClient(),
      keyPrefix: 'rl_payment',
      points: parseInt(process.env.RATE_LIMIT_PAYMENT_POINTS) || 3,
      duration: parseInt(process.env.RATE_LIMIT_PAYMENT_DURATION) || 300, // 5 minutes
      blockDuration: parseInt(process.env.RATE_LIMIT_PAYMENT_BLOCK) || 1800, // 30 minutes
    }));
  }

  getLimiter(type = 'general') {
    return this.limiters.get(type) || this.limiters.get('general');
  }

  createRateLimitMiddleware(type = 'general', options = {}) {
    const limiter = this.getLimiter(type);
    const keyGenerator = options.keyGenerator || this.defaultKeyGenerator;
    const skipSuccessfulRequests = options.skipSuccessfulRequests || false;
    const skipFailedRequests = options.skipFailedRequests || false;

    return async (req, res, next) => {
      try {
        const key = keyGenerator(req);
        const rateLimiterRes = await limiter.consume(key);

        // Add rate limit headers
        res.set({
          'X-RateLimit-Limit': limiter.points,
          'X-RateLimit-Remaining': rateLimiterRes.remainingPoints,
          'X-RateLimit-Reset': new Date(Date.now() + rateLimiterRes.msBeforeNext).toISOString(),
        });

        // Log rate limit usage
        structuredLogger.logInfo('RATE_LIMIT_CONSUMED', {
          type,
          key,
          remaining: rateLimiterRes.remainingPoints,
          totalHits: rateLimiterRes.totalHits,
          ip: req.ip,
          userAgent: req.get('User-Agent'),
          endpoint: req.path
        });

        next();
      } catch (rateLimiterRes) {
        // Rate limit exceeded
        const secs = Math.round(rateLimiterRes.msBeforeNext / 1000) || 1;
        
        structuredLogger.logWarning('RATE_LIMIT_EXCEEDED', {
          type,
          key: keyGenerator(req),
          ip: req.ip,
          userAgent: req.get('User-Agent'),
          endpoint: req.path,
          retryAfter: secs,
          totalHits: rateLimiterRes.totalHits
        });

        res.set('Retry-After', secs);
        res.status(429).json({
          success: false,
          error: {
            code: 'RATE_LIMIT_EXCEEDED',
            message: `Too many requests. Try again in ${secs} seconds.`,
            retryAfter: secs,
            limit: limiter.points,
            window: limiter.duration
          }
        });
      }
    };
  }

  defaultKeyGenerator(req) {
    // Use user ID if authenticated, otherwise use IP
    const userId = req.user?.id || req.user?.userId;
    return userId ? `user:${userId}` : `ip:${req.ip}`;
  }

  // Specific middleware for different endpoint types
  general() {
    return this.createRateLimitMiddleware('general');
  }

  auth() {
    return this.createRateLimitMiddleware('auth', {
      keyGenerator: (req) => {
        // More strict key generation for auth
        const email = req.body?.email || req.query?.email;
        return email ? `auth:${email}:${req.ip}` : `auth:${req.ip}`;
      }
    });
  }

  upload() {
    return this.createRateLimitMiddleware('upload', {
      keyGenerator: (req) => {
        const userId = req.user?.id || req.user?.userId;
        return userId ? `upload:user:${userId}` : `upload:ip:${req.ip}`;
      }
    });
  }

  search() {
    return this.createRateLimitMiddleware('search', {
      keyGenerator: (req) => {
        const userId = req.user?.id || req.user?.userId;
        return userId ? `search:user:${userId}` : `search:ip:${req.ip}`;
      }
    });
  }

  payment() {
    return this.createRateLimitMiddleware('payment', {
      keyGenerator: (req) => {
        const userId = req.user?.id || req.user?.userId;
        return userId ? `payment:user:${userId}` : `payment:ip:${req.ip}`;
      }
    });
  }

  // Dynamic rate limiting based on user role
  dynamic() {
    return async (req, res, next) => {
      try {
        let limiterType = 'general';
        
        // Adjust limits based on user role
        if (req.user?.role === 'admin') {
          limiterType = 'general'; // Admins get general limits
        } else if (req.user?.role === 'seller') {
          limiterType = 'general'; // Sellers get general limits
        } else if (req.user?.role === 'user') {
          limiterType = 'general'; // Regular users get general limits
        }

        // Adjust based on endpoint
        if (req.path.includes('/auth/')) {
          limiterType = 'auth';
        } else if (req.path.includes('/upload') || req.path.includes('/images')) {
          limiterType = 'upload';
        } else if (req.path.includes('/search')) {
          limiterType = 'search';
        } else if (req.path.includes('/payment') || req.path.includes('/stripe')) {
          limiterType = 'payment';
        }

        const middleware = this.createRateLimitMiddleware(limiterType);
        return middleware(req, res, next);
      } catch (error) {
        structuredLogger.logError('DYNAMIC_RATE_LIMIT_ERROR', {
          error: error.message,
          path: req.path,
          userRole: req.user?.role
        });
        next(error);
      }
    };
  }

  // Reset rate limit for a specific key
  async reset(key, type = 'general') {
    try {
      const limiter = this.getLimiter(type);
      await limiter.delete(key);
      
      structuredLogger.logInfo('RATE_LIMIT_RESET', {
        key,
        type
      });
      
      return true;
    } catch (error) {
      structuredLogger.logError('RATE_LIMIT_RESET_FAILED', {
        error: error.message,
        key,
        type
      });
      return false;
    }
  }

  // Get rate limit status for a key
  async getStatus(key, type = 'general') {
    try {
      const limiter = this.getLimiter(type);
      const status = await limiter.get(key);
      
      return {
        remaining: status ? status.remainingPoints : limiter.points,
        totalHits: status ? status.totalHits : 0,
        msBeforeNext: status ? status.msBeforeNext : 0,
        isBlocked: status ? status.remainingPoints <= 0 : false
      };
    } catch (error) {
      structuredLogger.logError('RATE_LIMIT_STATUS_ERROR', {
        error: error.message,
        key,
        type
      });
      return null;
    }
  }
}

module.exports = new RateLimitingMiddleware();
