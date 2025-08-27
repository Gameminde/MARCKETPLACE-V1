const Redis = require('ioredis');
const jwt = require('jsonwebtoken');
const structuredLogger = require('./structured-logger.service');

class TokenBlacklistService {
  constructor() {
    this.redisClient = new Redis(process.env.REDIS_URI || 'redis://localhost:6379', {
      retryDelayOnFailover: 100,
      maxRetriesPerRequest: 3,
      lazyConnect: true
    });

    this.redisClient.on('error', (error) => {
      structuredLogger.logError('REDIS_CONNECTION_ERROR', { error: error.message });
    });

    this.redisClient.on('connect', () => {
      structuredLogger.logInfo('REDIS_CONNECTED', { uri: process.env.REDIS_URI || 'redis://localhost:6379' });
    });
  }

  /**
   * Blacklist un token avec expiration automatique
   * @param {string} token - Token JWT à blacklister
   * @returns {Promise<boolean>} - Succès de l'opération
   */
  async blacklistToken(token) {
    try {
      if (!token || typeof token !== 'string') {
        structuredLogger.logWarning('BLACKLIST_INVALID_TOKEN', { token: token ? 'present' : 'missing' });
        return false;
      }

      // Décoder le token pour obtenir l'expiration
      let decoded;
      try {
        decoded = jwt.decode(token, { complete: true });
      } catch (error) {
        structuredLogger.logWarning('BLACKLIST_TOKEN_DECODE_FAILED', { error: error.message });
        return false;
      }

      if (!decoded || !decoded.payload) {
        structuredLogger.logWarning('BLACKLIST_TOKEN_NO_PAYLOAD', { token: 'invalid' });
        return false;
      }

      const now = Math.floor(Date.now() / 1000);
      const exp = decoded.payload.exp || (now + 3600); // 1h par défaut si pas d'exp
      const ttl = Math.max(0, exp - now);

      // Blacklist le token avec TTL automatique
      const key = `blacklist:${token}`;
      await this.redisClient.setex(key, ttl, 'true');

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

      const key = `blacklist:${token}`;
      const result = await this.redisClient.get(key);
      
      return result === 'true';
    } catch (error) {
      structuredLogger.logError('CHECK_BLACKLIST_ERROR', {
        error: error.message,
        stack: error.stack
      });
      
      // En cas d'erreur Redis, considérer le token comme valide
      // pour éviter de bloquer les utilisateurs
      return false;
    }
  }

  /**
   * Nettoyer les tokens expirés (maintenance)
   * @returns {Promise<number>} - Nombre de tokens nettoyés
   */
  async cleanupExpiredTokens() {
    try {
      const pattern = 'blacklist:*';
      const keys = await this.redisClient.keys(pattern);
      
      if (keys.length === 0) return 0;

      let cleanedCount = 0;
      for (const key of keys) {
        const ttl = await this.redisClient.ttl(key);
        if (ttl <= 0) {
          await this.redisClient.del(key);
          cleanedCount++;
        }
      }

      if (cleanedCount > 0) {
        structuredLogger.logInfo('BLACKLIST_CLEANUP', { cleanedCount });
      }

      return cleanedCount;
    } catch (error) {
      structuredLogger.logError('BLACKLIST_CLEANUP_ERROR', {
        error: error.message,
        stack: error.stack
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
      const pattern = 'blacklist:*';
      const keys = await this.redisClient.keys(pattern);
      
      const stats = {
        totalTokens: keys.length,
        memoryUsage: 0,
        averageTTL: 0
      };

      if (keys.length > 0) {
        let totalTTL = 0;
        for (const key of keys) {
          const ttl = await this.redisClient.ttl(key);
          totalTTL += Math.max(0, ttl);
        }
        stats.averageTTL = Math.round(totalTTL / keys.length);
      }

      return stats;
    } catch (error) {
      structuredLogger.logError('BLACKLIST_STATS_ERROR', {
        error: error.message,
        stack: error.stack
      });
      return { totalTokens: 0, memoryUsage: 0, averageTTL: 0 };
    }
  }

  /**
   * Fermer la connexion Redis
   */
  async disconnect() {
    try {
      await this.redisClient.quit();
      structuredLogger.logInfo('REDIS_DISCONNECTED');
    } catch (error) {
      structuredLogger.logError('REDIS_DISCONNECT_ERROR', {
        error: error.message,
        stack: error.stack
      });
    }
  }
}

// Instance singleton
const tokenBlacklistService = new TokenBlacklistService();

// Nettoyage automatique toutes les heures
setInterval(async () => {
  await tokenBlacklistService.cleanupExpiredTokens();
}, 60 * 60 * 1000);

module.exports = tokenBlacklistService;
