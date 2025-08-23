const jwt = require('jsonwebtoken');
const { blacklistToken } = require('../services/redis.service');

class AuthMiddleware {
  constructor() {
    this.secret = process.env.JWT_SECRET;
    this.algorithm = 'HS256';
  }

  async verifyToken(token) {
    try {
      if (!token) {
        throw new Error('Token missing');
      }

      // Vérifier si le token est blacklisté
      const isBlacklisted = await blacklistToken.isBlacklisted(token);
      if (isBlacklisted) {
        throw new Error('Token blacklisted');
      }

      const decoded = jwt.verify(token, this.secret, { algorithms: [this.algorithm] });
      return decoded;
    } catch (error) {
      throw new Error(`Token verification failed: ${error.message}`);
    }
  }

  createAuthMiddleware() {
    return async (req, res, next) => {
      try {
        const authHeader = req.headers.authorization;
        
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
          return res.status(401).json({
            success: false,
            code: 'AUTHENTICATION_FAILED',
            message: 'Bearer token required'
          });
        }

        const token = authHeader.substring(7);
        const decoded = await this.verifyToken(token);

        // Ajouter les informations utilisateur au request
        req.user = {
          sub: decoded.sub,
          email: decoded.email,
          role: decoded.role || 'user',
          iat: decoded.iat,
          exp: decoded.exp
        };

        next();
      } catch (error) {
        return res.status(401).json({
          success: false,
          code: 'AUTHENTICATION_FAILED',
          message: error.message
        });
      }
    };
  }

  createRoleMiddleware(requiredRole) {
    return (req, res, next) => {
      if (!req.user) {
        return res.status(401).json({
          success: false,
          code: 'AUTHENTICATION_FAILED',
          message: 'Authentication required'
        });
      }

      if (req.user.role !== requiredRole && req.user.role !== 'admin') {
        return res.status(403).json({
          success: false,
          code: 'AUTHORIZATION_DENIED',
          message: `Role ${requiredRole} required`
        });
      }

      next();
    };
  }

  createOptionalAuthMiddleware() {
    return async (req, res, next) => {
      try {
        const authHeader = req.headers.authorization;
        
        if (authHeader && authHeader.startsWith('Bearer ')) {
          const token = authHeader.substring(7);
          const decoded = await this.verifyToken(token);

          req.user = {
            sub: decoded.sub,
            email: decoded.email,
            role: decoded.role || 'user',
            iat: decoded.iat,
            exp: decoded.exp
          };
        }

        next();
      } catch (error) {
        // Pour l'auth optionnelle, on continue même si le token est invalide
        next();
      }
    };
  }
}

const authMiddleware = new AuthMiddleware();

// Export principal pour compatibilité
module.exports = authMiddleware.createAuthMiddleware();

// Exports nommés pour fonctionnalités avancées
module.exports.authMiddleware = authMiddleware.createAuthMiddleware();
module.exports.requireRole = authMiddleware.createRoleMiddleware.bind(authMiddleware);
module.exports.optionalAuth = authMiddleware.createOptionalAuthMiddleware();
module.exports.verifyToken = authMiddleware.verifyToken.bind(authMiddleware);


