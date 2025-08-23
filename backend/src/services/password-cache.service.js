const NodeCache = require('node-cache');
const crypto = require('crypto');

class PasswordValidationCache {
  constructor() {
    this.cache = new NodeCache({ stdTTL: 300, maxKeys: 10000, useClones: false });
  }

  getCacheKey(password) {
    return crypto.createHash('sha256').update(password).digest('hex');
  }

  getValidationResult(password) {
    return this.cache.get(this.getCacheKey(password));
  }

  cacheValidationResult(password, isValid) {
    if (isValid) {
      this.cache.set(this.getCacheKey(password), { isValid: true, ts: Date.now() });
    }
  }

  clearCache() {
    this.cache.flushAll();
  }

  getStats() {
    return this.cache.getStats();
  }
}

module.exports = new PasswordValidationCache();


