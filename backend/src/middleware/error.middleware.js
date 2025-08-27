const structuredLogger = require('../services/structured-logger.service');

class ErrorMiddleware {
  constructor() {
    this.errorMap = new Map();
    this.setupErrorMap();
  }

  setupErrorMap() {
    // Mapping des codes d'erreur vers les messages utilisateur
    this.errorMap.set('VALIDATION_ERROR', 'Données invalides');
    this.errorMap.set('AUTHENTICATION_FAILED', 'Authentification échouée');
    this.errorMap.set('AUTHORIZATION_DENIED', 'Accès refusé');
    this.errorMap.set('RATE_LIMITED', 'Trop de requêtes');
    this.errorMap.set('RESOURCE_NOT_FOUND', 'Ressource introuvable');
    this.errorMap.set('INTERNAL_ERROR', 'Erreur interne du serveur');
  }

  handleError(err, req, res, next) {
    // Log de l'erreur
    this.logError(err, req);

    // Déterminer le type d'erreur
    const errorType = this.determineErrorType(err);
    const statusCode = this.getStatusCode(errorType);
    const userMessage = this.getUserMessage(errorType);

    // Réponse structurée avec stack trace conditionnel
    const response = {
      success: false,
      error: {
        code: errorType,
        message: userMessage,
        timestamp: new Date().toISOString(),
        requestId: req.id || req.traceId || 'unknown'
      }
    };
    
    // Ajouter stack trace seulement en dev/staging
    const isDev = process.env.NODE_ENV === 'development';
    const isStaging = process.env.NODE_ENV === 'staging';
    
    if ((isDev || isStaging) && err.stack) {
      response.error.stack = err.stack;
    }
    
    res.status(statusCode).json(response);
  }

  handleNotFound(req, res, next) {
    res.status(404).json({
      success: false,
      error: {
        code: 'RESOURCE_NOT_FOUND',
        message: 'Endpoint non trouvé',
        timestamp: new Date().toISOString(),
        requestId: req.id || req.traceId || 'unknown'
      }
    });
  }

  handleValidationError(err, req, res, next) {
    if (err.isJoi) {
      res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Données de validation invalides',
          details: err.details.map(detail => ({
            field: detail.path.join('.'),
            message: detail.message
          })),
          timestamp: new Date().toISOString(),
          requestId: req.id || req.traceId || 'unknown'
        }
      });
    } else {
      next(err);
    }
  }

  handleRateLimitError(err, req, res, next) {
    if (err.status === 429) {
      res.status(429).json({
        success: false,
        error: {
          code: 'RATE_LIMITED',
          message: 'Trop de requêtes. Réessayez plus tard.',
          retryAfter: err.retryAfter || 60,
          timestamp: new Date().toISOString(),
          requestId: req.id || req.traceId || 'unknown'
        }
      });
    } else {
      next(err);
    }
  }

  handleAuthError(err, req, res, next) {
    if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
      res.status(401).json({
        success: false,
        error: {
          code: 'AUTHENTICATION_FAILED',
          message: 'Token d\'authentification invalide ou expiré',
          timestamp: new Date().toISOString(),
          requestId: req.id || req.traceId || 'unknown'
        }
      });
    } else if (err.name === 'UnauthorizedError') {
      res.status(403).json({
        success: false,
        error: {
          code: 'AUTHORIZATION_DENIED',
          message: 'Accès refusé à cette ressource',
          timestamp: new Date().toISOString(),
          requestId: req.id || req.traceId || 'unknown'
        }
      });
    } else {
      next(err);
    }
  }

  determineErrorType(err) {
    if (err.isJoi) return 'VALIDATION_ERROR';
    if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') return 'AUTHENTICATION_FAILED';
    if (err.name === 'UnauthorizedError') return 'AUTHORIZATION_DENIED';
    if (err.status === 429) return 'RATE_LIMITED';
    if (err.status === 404) return 'RESOURCE_NOT_FOUND';
    return 'INTERNAL_ERROR';
  }

  getStatusCode(errorType) {
    const statusMap = {
      'VALIDATION_ERROR': 400,
      'AUTHENTICATION_FAILED': 401,
      'AUTHORIZATION_DENIED': 403,
      'RATE_LIMITED': 429,
      'RESOURCE_NOT_FOUND': 404,
      'INTERNAL_ERROR': 500
    };
    return statusMap[errorType] || 500;
  }

  getUserMessage(errorType) {
    return this.errorMap.get(errorType) || 'Une erreur est survenue';
  }

  logError(err, req) {
    structuredLogger.logError(err, {
      url: req.url,
      method: req.method,
      ip: req.ip,
      userAgent: req.headers['user-agent'],
      userId: req.user?.sub,
      traceId: req.traceId || req.id
    });
  }

  handleUnhandledRejection(reason, promise) {
    structuredLogger.logError(new Error(`Unhandled Rejection at: ${promise}, reason: ${reason}`), {
      type: 'unhandled_rejection',
      promise: promise.toString(),
      reason: reason?.toString()
    });
  }

  handleUncaughtException(error) {
    structuredLogger.logError(error, {
      type: 'uncaught_exception'
    });
    
    // Fermer le serveur gracieusement
    process.exit(1);
  }

  setupGlobalHandlers() {
    process.on('unhandledRejection', this.handleUnhandledRejection.bind(this));
    process.on('uncaughtException', this.handleUncaughtException.bind(this));
  }
}

const errorMiddleware = new ErrorMiddleware();

const handleError = errorMiddleware.handleError.bind(errorMiddleware);
const handleNotFound = errorMiddleware.handleNotFound.bind(errorMiddleware);
const handleValidationError = errorMiddleware.handleValidationError.bind(errorMiddleware);
const handleRateLimitError = errorMiddleware.handleRateLimitError.bind(errorMiddleware);
const handleAuthError = errorMiddleware.handleAuthError.bind(errorMiddleware);

module.exports = {
  handleError,
  handleNotFound,
  handleValidationError,
  handleRateLimitError,
  handleAuthError,
  setupGlobalHandlers: errorMiddleware.setupGlobalHandlers.bind(errorMiddleware)
};


