const LRUCache = require('lru-cache');
const redisClientService = require('./redis-client.service');
const structuredLogger = require('./structured-logger.service');

class CacheService {
  constructor() {
    // L1: Memory cache (ultra-rapide)
    this.memoryCache = new LRUCache({
      max: parseInt(process.env.MEMORY_CACHE_MAX) || 500,
      ttl: parseInt(process.env.MEMORY_CACHE_TTL) || 1000 * 60 * 5, // 5 minutes
      updateAgeOnGet: true,
      updateAgeOnHas: true
    });

    // L2: Redis cache (rapide)
    this.redisClient = redisClientService;
    this.defaultTTL = parseInt(process.env.REDIS_CACHE_TTL) || 3600; // 1 hour
    
    // Cache statistics
    this.stats = {
      memoryHits: 0,
      memoryMisses: 0,
      redisHits: 0,
      redisMisses: 0,
      databaseHits: 0,
      totalRequests: 0
    };

    // Initialize Redis connection
    this.initializeRedis();
  }

  async initializeRedis() {
    try {
      await this.redisClient.connect();
      structuredLogger.logInfo('CACHE_SERVICE_INITIALIZED', {
        memoryCacheMax: this.memoryCache.max,
        memoryCacheTTL: this.memoryCache.ttl,
        redisTTL: this.defaultTTL
      });
    } catch (error) {
      structuredLogger.logError('CACHE_SERVICE_INIT_FAILED', {
        error: error.message
      });
    }
  }

  /**
   * Get data from cache with fallback to fetcher function
   * @param {String} key - Cache key
   * @param {Function} fetcher - Function to fetch data if not in cache
   * @param {Object} options - Cache options
   * @returns {Promise<Any>} Cached or fetched data
   */
  async get(key, fetcher, options = {}) {
    this.stats.totalRequests++;

    try {
      // L1: Memory cache (ultra-rapide)
      let data = this.memoryCache.get(key);
      if (data !== undefined) {
        this.stats.memoryHits++;
        structuredLogger.logDebug('CACHE_MEMORY_HIT', { key });
        return data;
      }
      this.stats.memoryMisses++;

      // L2: Redis cache (rapide)
      if (this.redisClient.isReady) {
        try {
          const redisData = await this.redisClient.getClient().get(key);
          if (redisData !== null) {
            this.stats.redisHits++;
            data = JSON.parse(redisData);
            
            // Store in memory cache for next time
            this.memoryCache.set(key, data);
            
            structuredLogger.logDebug('CACHE_REDIS_HIT', { key });
            return data;
          }
          this.stats.redisMisses++;
        } catch (redisError) {
          structuredLogger.logWarning('CACHE_REDIS_ERROR', {
            error: redisError.message,
            key
          });
        }
      }

      // L3: Database (lent) - Call fetcher function
      this.stats.databaseHits++;
      data = await fetcher();
      
      if (data !== null && data !== undefined) {
        // Store in both caches
        const ttl = options.ttl || this.defaultTTL;
        
        // Store in memory cache
        this.memoryCache.set(key, data);
        
        // Store in Redis cache
        if (this.redisClient.isReady) {
          try {
            await this.redisClient.getClient().setex(key, ttl, JSON.stringify(data));
          } catch (redisError) {
            structuredLogger.logWarning('CACHE_REDIS_SET_ERROR', {
              error: redisError.message,
              key
            });
          }
        }
        
        structuredLogger.logDebug('CACHE_DATABASE_HIT', { key });
      }

      return data;
    } catch (error) {
      structuredLogger.logError('CACHE_GET_ERROR', {
        error: error.message,
        key
      });
      throw error;
    }
  }

  /**
   * Set data in cache
   * @param {String} key - Cache key
   * @param {Any} data - Data to cache
   * @param {Object} options - Cache options
   */
  async set(key, data, options = {}) {
    try {
      const ttl = options.ttl || this.defaultTTL;
      
      // Store in memory cache
      this.memoryCache.set(key, data);
      
      // Store in Redis cache
      if (this.redisClient.isReady) {
        await this.redisClient.getClient().setex(key, ttl, JSON.stringify(data));
      }
      
      structuredLogger.logDebug('CACHE_SET', { key, ttl });
    } catch (error) {
      structuredLogger.logError('CACHE_SET_ERROR', {
        error: error.message,
        key
      });
    }
  }

  /**
   * Delete data from cache
   * @param {String} key - Cache key
   */
  async del(key) {
    try {
      // Remove from memory cache
      this.memoryCache.delete(key);
      
      // Remove from Redis cache
      if (this.redisClient.isReady) {
        await this.redisClient.getClient().del(key);
      }
      
      structuredLogger.logDebug('CACHE_DELETE', { key });
    } catch (error) {
      structuredLogger.logError('CACHE_DELETE_ERROR', {
        error: error.message,
        key
      });
    }
  }

  /**
   * Delete multiple keys from cache
   * @param {Array<String>} keys - Cache keys
   */
  async delMultiple(keys) {
    try {
      // Remove from memory cache
      keys.forEach(key => this.memoryCache.delete(key));
      
      // Remove from Redis cache
      if (this.redisClient.isReady && keys.length > 0) {
        await this.redisClient.getClient().del(...keys);
      }
      
      structuredLogger.logDebug('CACHE_DELETE_MULTIPLE', { keys: keys.length });
    } catch (error) {
      structuredLogger.logError('CACHE_DELETE_MULTIPLE_ERROR', {
        error: error.message,
        keys: keys.length
      });
    }
  }

  /**
   * Clear all cache
   */
  async clear() {
    try {
      // Clear memory cache
      this.memoryCache.clear();
      
      // Clear Redis cache
      if (this.redisClient.isReady) {
        await this.redisClient.getClient().flushdb();
      }
      
      // Reset statistics
      this.stats = {
        memoryHits: 0,
        memoryMisses: 0,
        redisHits: 0,
        redisMisses: 0,
        databaseHits: 0,
        totalRequests: 0
      };
      
      structuredLogger.logInfo('CACHE_CLEARED');
    } catch (error) {
      structuredLogger.logError('CACHE_CLEAR_ERROR', {
        error: error.message
      });
    }
  }

  /**
   * Check if key exists in cache
   * @param {String} key - Cache key
   * @returns {Boolean} True if exists
   */
  has(key) {
    return this.memoryCache.has(key);
  }

  /**
   * Get cache statistics
   * @returns {Object} Cache statistics
   */
  getStats() {
    const totalHits = this.stats.memoryHits + this.stats.redisHits;
    const totalMisses = this.stats.memoryMisses + this.stats.redisMisses;
    const hitRate = this.stats.totalRequests > 0 
      ? (totalHits / this.stats.totalRequests * 100).toFixed(2) 
      : 0;

    return {
      ...this.stats,
      hitRate: `${hitRate}%`,
      memoryCacheSize: this.memoryCache.size,
      memoryCacheMax: this.memoryCache.max
    };
  }

  /**
   * Create a cache key with namespace
   * @param {String} namespace - Namespace
   * @param {String} key - Key
   * @param {Object} params - Additional parameters
   * @returns {String} Formatted cache key
   */
  createKey(namespace, key, params = {}) {
    const paramString = Object.keys(params)
      .sort()
      .map(k => `${k}:${params[k]}`)
      .join('|');
    
    return paramString 
      ? `${namespace}:${key}:${paramString}` 
      : `${namespace}:${key}`;
  }

  /**
   * Cache with automatic invalidation
   * @param {String} key - Cache key
   * @param {Function} fetcher - Function to fetch data
   * @param {Object} options - Cache options
   * @returns {Promise<Any>} Cached or fetched data
   */
  async remember(key, fetcher, options = {}) {
    return this.get(key, fetcher, options);
  }

  /**
   * Cache for a specific duration
   * @param {String} key - Cache key
   * @param {Function} fetcher - Function to fetch data
   * @param {Number} ttl - Time to live in seconds
   * @returns {Promise<Any>} Cached or fetched data
   */
  async rememberFor(key, fetcher, ttl) {
    return this.get(key, fetcher, { ttl });
  }

  /**
   * Invalidate cache by pattern
   * @param {String} pattern - Redis pattern
   */
  async invalidatePattern(pattern) {
    try {
      if (this.redisClient.isReady) {
        const keys = await this.redisClient.getClient().keys(pattern);
        if (keys.length > 0) {
          await this.delMultiple(keys);
        }
      }
      
      // Also clear matching keys from memory cache
      const memoryKeys = Array.from(this.memoryCache.keys())
        .filter(key => key.includes(pattern.replace('*', '')));
      
      memoryKeys.forEach(key => this.memoryCache.delete(key));
      
      structuredLogger.logDebug('CACHE_INVALIDATE_PATTERN', { pattern, keys: keys.length });
    } catch (error) {
      structuredLogger.logError('CACHE_INVALIDATE_PATTERN_ERROR', {
        error: error.message,
        pattern
      });
    }
  }

  /**
   * Warm up cache with data
   * @param {Array} items - Items to cache
   * @param {Function} keyGenerator - Function to generate cache keys
   * @param {Function} dataGenerator - Function to generate cache data
   */
  async warmUp(items, keyGenerator, dataGenerator) {
    try {
      const promises = items.map(async (item) => {
        const key = keyGenerator(item);
        const data = await dataGenerator(item);
        await this.set(key, data);
      });
      
      await Promise.all(promises);
      
      structuredLogger.logInfo('CACHE_WARM_UP_COMPLETE', {
        items: items.length
      });
    } catch (error) {
      structuredLogger.logError('CACHE_WARM_UP_ERROR', {
        error: error.message,
        items: items.length
      });
    }
  }
}

module.exports = new CacheService();
