const CircuitBreaker = require('opossum');
const redisClientService = require('./redis-client.service');

class RedisCircuitService {
  constructor() {
    this.options = {
      timeout: 2000, // 2s timeout (plus réaliste)
      errorThresholdPercentage: 20, // 20% error rate (plus sensible)
      resetTimeout: 30000, // 30s before half-open
      rollingCountTimeout: 10000, // 10s rolling window
      rollingCountBuckets: 10 // number of buckets
    };

    this.redisCircuitBreaker = new CircuitBreaker(
      async (operation, ...args) => {
        if (!redisClientService.isReady) {
          throw new Error('Redis not ready');
        }
        const client = redisClientService.getClient();
        return await client[operation](...args);
      },
      this.options
    );

    this.setupEventListeners();
    this.setupFallback();
  }

  setupEventListeners() {
    this.redisCircuitBreaker.on('open', () => {
      console.error('🚧 Redis Circuit OPEN - Fallback mode activated');
    });

    this.redisCircuitBreaker.on('halfOpen', () => {
      console.log('🔄 Redis Circuit HALF-OPEN - Testing Redis');
    });

    this.redisCircuitBreaker.on('close', () => {
      console.log('✅ Redis Circuit CLOSED - Redis healthy');
    });

    this.redisCircuitBreaker.on('fallback', (result) => {
      console.warn('⚠️ Redis unavailable - Using fallback strategy');
    });
  }

  setupFallback() {
    this.redisCircuitBreaker.fallback(() => {
      console.warn('⚠️ Redis unavailable - Using fallback strategy');
      return null; // or throw error to deny access
    });
  }

  async executeRedisCommand(operation, ...args) {
    try {
      return await this.redisCircuitBreaker.fire(operation, ...args);
    } catch (error) {
      if (error.message.includes('Circuit')) {
        throw new Error('AUTH_SERVICE_DEGRADED');
      }
      throw error;
    }
  }

  getCircuitState() {
    return {
      state: this.redisCircuitBreaker.state,
      stats: this.redisCircuitBreaker.stats,
      options: this.options
    };
  }

  async healthCheck() {
    try {
      const result = await this.executeRedisCommand('ping');
      return {
        status: 'healthy',
        response: result,
        circuitState: this.redisCircuitBreaker.state,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        error: error.message,
        circuitState: this.redisCircuitBreaker.state,
        timestamp: new Date().toISOString()
      };
    }
  }
}

module.exports = new RedisCircuitService();


