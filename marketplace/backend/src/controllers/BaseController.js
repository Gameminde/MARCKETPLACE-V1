const structuredLogger = require('../services/structured-logger.service');

class BaseController {
  constructor(serviceName) {
    this.serviceName = serviceName;
  }

  asyncHandler(fn) {
    return async (req, res, next) => {
      try {
        const result = fn(req, res, next);
        if (result && typeof result.then === 'function') {
          await result;
        }
      } catch (error) {
        this.handleError(error, req, res);
      }
    };
  }

  handleError(error, req, res) {
    const isDev = process.env.NODE_ENV === 'development';
    const isStaging = process.env.NODE_ENV === 'staging';
    
    structuredLogger.logError(`${this.serviceName}_ERROR`, {
      userId: req.user?.sub,
      error: error.message,
      stack: (isDev || isStaging) ? error.stack : undefined
    });

    // Déterminer le type d'erreur et le code de statut
    let statusCode = 500;
    let errorCode = `${this.serviceName.toUpperCase()}_ERROR`;

    if (error.message.includes('non trouvé')) {
      statusCode = 404;
      errorCode = `${this.serviceName.toUpperCase()}_NOT_FOUND`;
    } else if (error.message.includes('Validation')) {
      statusCode = 400;
      errorCode = `${this.serviceName.toUpperCase()}_VALIDATION_ERROR`;
    }

    res.status(statusCode).json({
      success: false,
      code: errorCode,
      message: this.getErrorMessage(error, statusCode),
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }

  getErrorMessage(error, statusCode) {
    const messages = {
      404: 'Ressource non trouvée',
      400: 'Données invalides',
      500: 'Erreur interne du serveur'
    };
    return messages[statusCode] || 'Erreur inconnue';
  }

  validateRequest(schema, data) {
    const { error, value } = schema.validate(data);
    if (error) {
      throw new Error(`Validation: ${error.details[0].message}`);
    }
    return value;
  }

  sendSuccess(res, data, statusCode = 200) {
    res.status(statusCode).json({
      success: true,
      timestamp: new Date().toISOString(),
      ...data
    });
  }
}

module.exports = BaseController;
