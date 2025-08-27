const JWTSecurityService = require('../services/jwt-security.service');
const { SecurityValidatorService } = require('../services/security-validator.service');
const structuredLogger = require('../services/structured-logger.service');

// PHASE 3: Enhanced Authentication Middleware with Security Hardening
class EnhancedAuthMiddleware {
  constructor() {
    this.jwtService = new JWTSecurityService();
    this.validator = new SecurityValidatorService();
    this.logger = structuredLogger;
    
    // Bind methods to preserve context
    this.authenticate = this.authenticate.bind(this);
    this.requireAuth = this.requireAuth.bind(this);
    this.requireRole = this.requireRole.bind(this);
    this.requirePermission = this.requirePermission.bind(this);
  }

  // Main authentication middleware
  async authenticate(req, res, next) {
    try {
      const token = this._extractToken(req);
      
      if (!token) {
        // Allow request to continue without authentication
        // Individual routes can decide if auth is required
        return next();
      }

      // Validate token
      const decoded = await this.jwtService.validateAccessToken(token);
      
      // Attach user info to request
      req.user = {
        sub: decoded.sub,
        email: decoded.email,
        role: decoded.role || 'user',
        permissions: decoded.permissions || [],
        iat: decoded.iat,
        exp: decoded.exp,
        jti: decoded.jti
      };

      // Log successful authentication
      this.logger.info('User authenticated successfully', {
        userId: req.user.sub,
        role: req.user.role,
        ip: req.ip,
        userAgent: req.get('User-Agent')
      });

      next();
    } catch (error) {
      this.logger.warn('Authentication failed', {
        error: error.message,
        ip: req.ip,
        userAgent: req.get('User-Agent'),
        path: req.path
      });

      // Don't throw error here - let individual routes handle auth requirements
      next();
    }
  }

  // Require authentication middleware
  requireAuth(req, res, next) {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required',
        code: 'AUTH_REQUIRED'
      });
    }

    // Check if token is about to expire (within 5 minutes)
    const now = Math.floor(Date.now() / 1000);
    const timeToExpiry = req.user.exp - now;
    
    if (timeToExpiry < 300) { // 5 minutes
      res.set('X-Token-Refresh-Suggested', 'true');
      this.logger.info('Token refresh suggested', {
        userId: req.user.sub,
        timeToExpiry
      });
    }

    next();
  }

  // Role-based access control
  requireRole(roles) {
    if (typeof roles === 'string') {
      roles = [roles];
    }

    return (req, res, next) => {
      if (!req.user) {
        return res.status(401).json({
          success: false,
          message: 'Authentication required',
          code: 'AUTH_REQUIRED'
        });
      }

      if (!roles.includes(req.user.role)) {
        this.logger.warn('Access denied - insufficient role', {
          userId: req.user.sub,
          userRole: req.user.role,
          requiredRoles: roles,
          path: req.path
        });

        return res.status(403).json({
          success: false,
          message: 'Insufficient permissions',
          code: 'INSUFFICIENT_ROLE'
        });
      }

      next();
    };
  }

  // Permission-based access control
  requirePermission(permissions) {
    if (typeof permissions === 'string') {
      permissions = [permissions];
    }

    return (req, res, next) => {
      if (!req.user) {
        return res.status(401).json({
          success: false,
          message: 'Authentication required',
          code: 'AUTH_REQUIRED'
        });
      }

      // Admin role bypasses permission checks
      if (req.user.role === 'admin') {
        return next();
      }

      const userPermissions = req.user.permissions || [];
      const hasPermission = permissions.some(permission => 
        userPermissions.includes(permission)
      );

      if (!hasPermission) {
        this.logger.warn('Access denied - insufficient permissions', {
          userId: req.user.sub,
          userPermissions,
          requiredPermissions: permissions,
          path: req.path
        });

        return res.status(403).json({
          success: false,
          message: 'Insufficient permissions',
          code: 'INSUFFICIENT_PERMISSIONS'
        });
      }

      next();
    };
  }

  // Optional authentication (for public endpoints that benefit from user context)
  optionalAuth(req, res, next) {
    // This is the same as authenticate - it sets req.user if token is valid
    // but doesn't fail if no token is provided
    return this.authenticate(req, res, next);
  }

  // Resource ownership check
  requireOwnership(getResourceUserId) {
    return async (req, res, next) => {
      if (!req.user) {
        return res.status(401).json({
          success: false,
          message: 'Authentication required',
          code: 'AUTH_REQUIRED'
        });
      }

      try {
        const resourceUserId = typeof getResourceUserId === 'function' 
          ? await getResourceUserId(req)
          : req.params[getResourceUserId] || req.body[getResourceUserId];

        // Admin can access any resource
        if (req.user.role === 'admin') {
          return next();
        }

        if (req.user.sub !== resourceUserId) {
          this.logger.warn('Access denied - not resource owner', {
            userId: req.user.sub,
            resourceUserId,
            path: req.path
          });

          return res.status(403).json({
            success: false,
            message: 'Access denied - not resource owner',
            code: 'NOT_RESOURCE_OWNER'
          });
        }

        next();
      } catch (error) {
        this.logger.error('Ownership check failed', {
          error: error.message,
          userId: req.user.sub,
          path: req.path
        });

        return res.status(500).json({
          success: false,
          message: 'Authorization check failed',
          code: 'AUTH_CHECK_FAILED'
        });
      }
    };
  }

  // Rate limiting by user
  requireUserRateLimit(maxRequests = 100, windowMs = 60000) {
    const userRequests = new Map();

    return (req, res, next) => {
      if (!req.user) {
        return next(); // Let other middleware handle auth requirement
      }

      const userId = req.user.sub;
      const now = Date.now();
      const windowStart = now - windowMs;

      // Clean old entries
      if (userRequests.has(userId)) {
        const requests = userRequests.get(userId);
        const validRequests = requests.filter(time => time > windowStart);
        userRequests.set(userId, validRequests);
      }

      const userRequestList = userRequests.get(userId) || [];
      
      if (userRequestList.length >= maxRequests) {
        this.logger.warn('User rate limit exceeded', {
          userId,
          requestCount: userRequestList.length,
          maxRequests,
          windowMs
        });

        return res.status(429).json({
          success: false,
          message: 'User rate limit exceeded',
          code: 'USER_RATE_LIMIT_EXCEEDED',
          retryAfter: Math.ceil(windowMs / 1000)
        });
      }

      // Add current request
      userRequestList.push(now);
      userRequests.set(userId, userRequestList);

      next();
    };
  }

  // Security headers middleware
  addSecurityHeaders(req, res, next) {
    // Add security headers
    res.set({
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      'Permissions-Policy': 'geolocation=(), microphone=(), camera=()'
    });

    // Add user-specific headers if authenticated
    if (req.user) {
      res.set({
        'X-User-ID': req.user.sub,
        'X-User-Role': req.user.role
      });
    }

    next();
  }

  // Extract token from request
  _extractToken(req) {
    // Check Authorization header
    const authHeader = req.get('Authorization');
    if (authHeader && authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7);
    }

    // Check query parameter (less secure, for specific use cases)
    if (req.query.token) {
      this.logger.warn('Token provided in query parameter', {
        ip: req.ip,
        path: req.path
      });
      return req.query.token;
    }

    // Check cookie (if using cookie-based auth)
    if (req.cookies && req.cookies.auth_token) {
      return req.cookies.auth_token;
    }

    return null;
  }

  // Middleware factory for complex authorization rules
  createAuthRule(rule) {
    return async (req, res, next) => {
      try {
        const result = await rule(req);
        
        if (result.allowed) {
          return next();
        }

        this.logger.warn('Custom auth rule denied access', {
          userId: req.user?.sub,
          rule: rule.name || 'anonymous',
          reason: result.reason,
          path: req.path
        });

        return res.status(result.statusCode || 403).json({
          success: false,
          message: result.message || 'Access denied',
          code: result.code || 'ACCESS_DENIED'
        });
      } catch (error) {
        this.logger.error('Auth rule execution failed', {
          error: error.message,
          rule: rule.name || 'anonymous',
          path: req.path
        });

        return res.status(500).json({
          success: false,
          message: 'Authorization check failed',
          code: 'AUTH_RULE_ERROR'
        });
      }
    };
  }
}

// Create singleton instance
const enhancedAuth = new EnhancedAuthMiddleware();

// Export middleware functions
module.exports = {
  authenticate: enhancedAuth.authenticate,
  requireAuth: enhancedAuth.requireAuth,
  requireRole: enhancedAuth.requireRole,
  requirePermission: enhancedAuth.requirePermission,
  optionalAuth: enhancedAuth.optionalAuth,
  requireOwnership: enhancedAuth.requireOwnership,
  requireUserRateLimit: enhancedAuth.requireUserRateLimit,
  addSecurityHeaders: enhancedAuth.addSecurityHeaders,
  createAuthRule: enhancedAuth.createAuthRule,
  
  // Export the class for testing
  EnhancedAuthMiddleware
};