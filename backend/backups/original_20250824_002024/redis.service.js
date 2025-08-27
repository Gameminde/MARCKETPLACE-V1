const redisClientService = require('./redis-client.service');

class BlacklistTokenService {
  constructor() {
    this.prefix = 'blacklist:';
    this.defaultTTL = 24 * 60 * 60; // 24 heures
  }

  async addToBlacklist(token, ttl = this.defaultTTL) {
    try {
      const client = redisClientService.getClient();
      const key = this.prefix + token;
      
      await client.setEx(key, ttl, '1');
      
      return true;
    } catch (error) {
      console.error('❌ Error adding token to blacklist:', error);
      return false;
    }
  }

  async isBlacklisted(token) {
    try {
      const client = redisClientService.getClient();
      const key = this.prefix + token;
      
      const result = await client.get(key);
      return result === '1';
    } catch (error) {
      console.error('❌ Error checking token blacklist:', error);
      return false;
    }
  }

  async removeFromBlacklist(token) {
    try {
      const client = redisClientService.getClient();
      const key = this.prefix + token;
      
      await client.del(key);
      return true;
    } catch (error) {
      console.error('❌ Error removing token from blacklist:', error);
      return false;
    }
  }

  async getBlacklistStats() {
    try {
      const client = redisClientService.getClient();
      const pattern = this.prefix + '*';
      
      const keys = await client.keys(pattern);
      return {
        totalBlacklisted: keys.length,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error('❌ Error getting blacklist stats:', error);
      return {
        totalBlacklisted: 0,
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  async cleanupExpiredTokens() {
    try {
      const client = redisClientService.getClient();
      const pattern = this.prefix + '*';
      
      const keys = await client.keys(pattern);
      let cleanedCount = 0;
      
      for (const key of keys) {
        const ttl = await client.ttl(key);
        if (ttl === -1 || ttl === -2) {
          await client.del(key);
          cleanedCount++;
        }
      }
      
      return {
        cleanedCount,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error('❌ Error cleaning up expired tokens:', error);
      return {
        cleanedCount: 0,
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }
}

const blacklistToken = new BlacklistTokenService();

module.exports = {
  blacklistToken
};


