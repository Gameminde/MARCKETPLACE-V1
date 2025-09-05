const structuredLogger = require('../services/structured-logger.service');

class BaseController {
  constructor() {
    this.logger = structuredLogger;
  }

  /**
   * Handle request with standardized error handling
   * @param {Object} req - Express request
   * @param {Object} res - Express response
   * @param {Function} handler - Controller handler function
   */
  async handleRequest(req, res, handler) {
    const startTime = Date.now();
    const requestId = req.id || req.traceId || 'unknown';

    try {
      this.logger.logInfo('REQUEST_START', {
        requestId,
        method: req.method,
        path: req.path,
        ip: req.ip,
        userAgent: req.get('User-Agent')
      });

      const result = await handler(req, res);
      
      const duration = Date.now() - startTime;
      this.logger.logInfo('REQUEST_SUCCESS', {
        requestId,
        duration,
        statusCode: res.statusCode || 200
      });

      return result;
    } catch (error) {
      const duration = Date.now() - startTime;
      this.logger.logError('REQUEST_ERROR', {
        requestId,
        error: error.message,
        stack: error.stack,
        duration,
        method: req.method,
        path: req.path
      });

      this.sendError(res, error);
    }
  }

  /**
   * Send success response
   * @param {Object} res - Express response
   * @param {Any} data - Response data
   * @param {Number} statusCode - HTTP status code
   * @param {Object} meta - Additional metadata
   */
  sendSuccess(res, data, statusCode = 200, meta = {}) {
    const response = {
      success: true,
      data,
      timestamp: new Date().toISOString(),
      requestId: res.locals.requestId || 'unknown'
    };

    if (Object.keys(meta).length > 0) {
      response.meta = meta;
    }

    res.status(statusCode).json(response);
  }

  /**
   * Send error response
   * @param {Object} res - Express response
   * @param {Error} error - Error object
   * @param {Number} statusCode - HTTP status code
   */
  sendError(res, error, statusCode = null) {
    const isDev = process.env.NODE_ENV === 'development';
    const isStaging = process.env.NODE_ENV === 'staging';
    
    // Determine status code
    let httpStatus = statusCode || 500;
    
    if (error.status) {
      httpStatus = error.status;
    } else if (error.name === 'ValidationError') {
      httpStatus = 400;
    } else if (error.name === 'CastError') {
      httpStatus = 400;
    } else if (error.name === 'MongoError' && error.code === 11000) {
      httpStatus = 409; // Conflict
    } else if (error.name === 'JsonWebTokenError') {
      httpStatus = 401;
    } else if (error.name === 'TokenExpiredError') {
      httpStatus = 401;
    }

    const response = {
      success: false,
      error: {
        code: error.code || this.getErrorCode(error),
        message: error.message || 'Internal server error',
        timestamp: new Date().toISOString(),
        requestId: res.locals.requestId || 'unknown'
      }
    };

    // Add stack trace in development/staging
    if ((isDev || isStaging) && error.stack) {
      response.error.stack = error.stack;
    }

    // Add validation details for validation errors
    if (error.details && Array.isArray(error.details)) {
      response.error.details = error.details;
    }

    res.status(httpStatus).json(response);
  }

  /**
   * Get error code from error object
   * @param {Error} error - Error object
   * @returns {String} Error code
   */
  getErrorCode(error) {
    if (error.code) return error.code;
    
    switch (error.name) {
      case 'ValidationError':
        return 'VALIDATION_ERROR';
      case 'CastError':
        return 'INVALID_ID';
      case 'MongoError':
        return error.code === 11000 ? 'DUPLICATE_ENTRY' : 'DATABASE_ERROR';
      case 'JsonWebTokenError':
        return 'INVALID_TOKEN';
      case 'TokenExpiredError':
        return 'TOKEN_EXPIRED';
      case 'MulterError':
        return 'FILE_UPLOAD_ERROR';
      default:
        return 'INTERNAL_ERROR';
    }
  }

  /**
   * Send paginated response
   * @param {Object} res - Express response
   * @param {Object} paginatedData - Paginated data from PaginationService
   * @param {String} baseUrl - Base URL for pagination links
   * @param {Object} query - Query parameters
   */
  sendPaginated(res, paginatedData, baseUrl, query = {}) {
    const { data, pagination } = paginatedData;
    
    const response = {
      success: true,
      data,
      pagination: {
        ...pagination,
        links: this.createPaginationLinks(pagination, baseUrl, query)
      },
      timestamp: new Date().toISOString(),
      requestId: res.locals.requestId || 'unknown'
    };

    res.status(200).json(response);
  }

  /**
   * Create pagination links
   * @param {Object} pagination - Pagination object
   * @param {String} baseUrl - Base URL
   * @param {Object} query - Query parameters
   * @returns {Object} Pagination links
   */
  createPaginationLinks(pagination, baseUrl, query = {}) {
    const { page, pages, hasNextPage, hasPrevPage, nextPage, prevPage } = pagination;
    
    const createUrl = (pageNum) => {
      const url = new URL(baseUrl);
      Object.keys(query).forEach(key => {
        if (key !== 'page') {
          url.searchParams.set(key, query[key]);
        }
      });
      url.searchParams.set('page', pageNum);
      return url.toString();
    };

    return {
      first: createUrl(1),
      last: createUrl(pages),
      next: hasNextPage ? createUrl(nextPage) : null,
      prev: hasPrevPage ? createUrl(prevPage) : null,
      self: createUrl(page)
    };
  }

  /**
   * Validate request body against schema
   * @param {Object} schema - Joi schema
   * @param {Object} data - Request data
   * @returns {Object} Validated data
   */
  validate(schema, data) {
    const { error, value } = schema.validate(data, {
      abortEarly: false,
      stripUnknown: true,
      convert: true
    });

    if (error) {
      const validationError = new Error('Validation failed');
      validationError.name = 'ValidationError';
      validationError.status = 400;
      validationError.details = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message,
        value: detail.context?.value
      }));
      throw validationError;
    }

    return value;
  }

  /**
   * Validate request body against schema (alias for validate)
   * @param {Object} schema - Joi schema
   * @param {Object} data - Request data
   * @returns {Object} Validated data
   */
  validateRequest(schema, data) {
    return this.validate(schema, data);
  }

  /**
   * Check if user has required permission
   * @param {Object} req - Express request
   * @param {String} permission - Required permission
   * @returns {Boolean} True if authorized
   */
  hasPermission(req, permission) {
    if (!req.user) return false;
    
    const userRole = req.user.role;
    const userPermissions = req.user.permissions || [];
    
    // Admin has all permissions
    if (userRole === 'admin') return true;
    
    // Check specific permission
    return userPermissions.includes(permission);
  }

  /**
   * Check if user owns resource
   * @param {Object} req - Express request
   * @param {String} resourceUserId - Resource owner ID
   * @returns {Boolean} True if user owns resource
   */
  ownsResource(req, resourceUserId) {
    if (!req.user) return false;
    
    const userId = req.user.id || req.user.userId;
    return userId === resourceUserId;
  }

  /**
   * Check if user can access resource
   * @param {Object} req - Express request
   * @param {String} resourceUserId - Resource owner ID
   * @param {String} permission - Required permission
   * @returns {Boolean} True if user can access
   */
  canAccess(req, resourceUserId, permission = null) {
    // Admin can access everything
    if (req.user?.role === 'admin') return true;
    
    // User owns the resource
    if (this.ownsResource(req, resourceUserId)) return true;
    
    // User has specific permission
    if (permission && this.hasPermission(req, permission)) return true;
    
    return false;
  }

  /**
   * Get current user from request
   * @param {Object} req - Express request
   * @returns {Object} User object
   */
  getCurrentUser(req) {
    return req.user || null;
  }

  /**
   * Get user ID from request
   * @param {Object} req - Express request
   * @returns {String} User ID
   */
  getCurrentUserId(req) {
    const user = this.getCurrentUser(req);
    return user ? (user.id || user.userId) : null;
  }

  /**
   * Create standardized error
   * @param {String} message - Error message
   * @param {Number} status - HTTP status code
   * @param {String} code - Error code
   * @returns {Error} Standardized error
   */
  createError(message, status = 500, code = 'INTERNAL_ERROR') {
    const error = new Error(message);
    error.status = status;
    error.code = code;
    return error;
  }

  /**
   * Async wrapper for controller methods
   * @param {Function} fn - Controller function
   * @returns {Function} Wrapped function
   */
  asyncWrapper(fn) {
    return (req, res, next) => {
      this.handleRequest(req, res, fn).catch(next);
    };
  }

  /**
   * Async handler for controller methods (alias for asyncWrapper)
   * @param {Function} fn - Controller function
   * @returns {Function} Wrapped function
   */
  asyncHandler(fn) {
    return this.asyncWrapper(fn);
  }
}

module.exports = BaseController;