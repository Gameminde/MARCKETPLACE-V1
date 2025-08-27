const redisClientService = require('./redis-client.service');
const jwt = require('jsonwebtoken');
const structuredLogger = require('./structured-logger.service');

class TokenBlacklistService {
  constructor() {
    this.redisClient = null; // Lazy initialization
    this.keyPrefix = 'blacklist:';
  }
  
  _getRedisClient() {
    if (!this.redisClient) {
      try {
        this.redisClient = redisClientService.getClient();
      } catch (error) {
        structuredLogger.logError('REDIS_CLIENT_ERROR', {
          error: error.message,
          service: 'token-blacklist'
        });
        throw new Error('Redis client unavailable for token blacklist');
      }
    }
    return this.redisClient;
  }

  /**
   * Blacklist un token avec expiration automatique
   * @param {string} token - Token JWT à blacklister
   * @returns {Promise<boolean>} - Succès de l'opération
   */
  async blacklistToken(token) {
    try {
      if (!token || typeof token !== 'string') {
        structuredLogger.logWarning('BLACKLIST_INVALID_TOKEN');
        return false;
      }

      let decoded;
      try {
        decoded = jwt.decode(token, { complete: true });
      } catch (error) {
        structuredLogger.logWarning('BLACKLIST_TOKEN_DECODE_FAILED', {
          error: error.message
        });
        return false;
      }

      if (!decoded?.payload) {
        return false;
      }

      const now = Math.floor(Date.now() / 1000);
      const exp = decoded.payload.exp || (now + 3600);
      const ttl = Math.max(0, exp - now);

      if (ttl <= 0) {
        structuredLogger.logWarning('BLACKLIST_EXPIRED_TOKEN');
        return false;
      }

      const client = this._getRedisClient();
      const key = `${this.keyPrefix}${token}`;
      
      await client.setEx(key, ttl, 'true');
      
      structuredLogger.logInfo('TOKEN_BLACKLISTED', {
        userId: decoded.payload.sub,
        tokenType: decoded.payload.type || 'unknown',
        ttl,
        expiresAt: new Date(exp * 1000).toISOString()
      });
      
      return true;
    } catch (error) {
      structuredLogger.logError('BLACKLIST_TOKEN_ERROR', {
        error: error.message,
        stack: error.stack
      });
      return false;
    }
  }

  /**
   * Vérifier si un token est blacklisté
   * @param {string} token - Token JWT à vérifier
   * @returns {Promise<boolean>} - True si blacklisté
   */
  async isTokenBlacklisted(token) {
    try {
      if (!token || typeof token !== 'string') {
        return false;
      }

      const client = this._getRedisClient();
      const key = `${this.keyPrefix}${token}`;
      const result = await client.get(key);
      
      return result === 'true';
    } catch (error) {
      structuredLogger.logError('CHECK_BLACKLIST_ERROR', {
        error: error.message
      });
      // Fail secure: en cas d'erreur Redis, considérer comme valide
      return false;
    }
  }

  /**
   * Nettoyer les tokens expirés (maintenance)
   * @returns {Promise<number>} - Nombre de tokens nettoyés
   */
  async cleanupExpiredTokens() {
    try {
      const client = this._getRedisClient();
      const pattern = `${this.keyPrefix}*`;
      const keys = await client.keys(pattern);
      
      if (keys.length === 0) return 0;

      let cleanedCount = 0;
      for (const key of keys) {
        const ttl = await client.ttl(key);
        if (ttl <= 0) {
          await client.del(key);
          cleanedCount++;
        }
      }

      if (cleanedCount > 0) {
        structuredLogger.logInfo('BLACKLIST_CLEANUP', { cleanedCount });
      }

      return cleanedCount;
    } catch (error) {
      structuredLogger.logError('BLACKLIST_CLEANUP_ERROR', {
        error: error.message
      });
      return 0;
    }
  }

  /**
   * Obtenir les statistiques de la blacklist
   * @returns {Promise<Object>} - Statistiques
   */
  async getBlacklistStats() {
    try {
      const client = this._getRedisClient();
      const pattern = `${this.keyPrefix}*`;
      const keys = await client.keys(pattern);
      
      const stats = {
        totalTokens: keys.length,
        memoryUsage: 0,
        averageTTL: 0
      };

      if (keys.length > 0) {
        let totalTTL = 0;
        for (const key of keys) {
          const ttl = await client.ttl(key);
          totalTTL += Math.max(0, ttl);
        }
        stats.averageTTL = Math.round(totalTTL / keys.length);
      }

      return stats;
    } catch (error) {
      structuredLogger.logError('BLACKLIST_STATS_ERROR', {
        error: error.message
      });
      return { totalTokens: 0, memoryUsage: 0, averageTTL: 0 };
    }
  }

  /**
   * Fermer la connexion Redis (délégué au service centralisé)
   */
  async disconnect() {
    // La connexion est gérée par redis-client.service
    // Pas besoin de fermer ici
    this.redisClient = null;
    structuredLogger.logInfo('TOKEN_BLACKLIST_DISCONNECTED');
  }
}

// Instance singleton
const tokenBlacklistService = new TokenBlacklistService();

// Nettoyage automatique toutes les heures
setInterval(async () => {
  try {
    await tokenBlacklistService.cleanupExpiredTokens();
  } catch (error) {
    structuredLogger.logError('BLACKLIST_CLEANUP_INTERVAL_ERROR', {
      error: error.message
    });
  }
}, 60 * 60 * 1000);

module.exports = tokenBlacklistService;
