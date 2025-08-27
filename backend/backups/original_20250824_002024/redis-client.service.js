const { createClient } = require('redis');

class RedisClientService {
  constructor() {
    this.client = null;
    this.isReady = false;
    this.isConnecting = false;
    this.maxRetries = 5;
    this.retryCount = 0;
    this.reconnectStrategy = {
      retries: 5,
      delay: 1000,
      backoff: 'exponential'
    };
  }

  async connect() {
    if (this.isConnecting || this.isReady) return;

    this.isConnecting = true;
    
    try {
      this.client = createClient({
        url: process.env.REDIS_URL || 'redis://localhost:6379',
        socket: {
          reconnectStrategy: this.reconnectStrategy
        }
      });

      this.setupEventHandlers();
      
      await this.client.connect();
      this.isReady = true;
      this.isConnecting = false;
      this.retryCount = 0;
      
      console.log('✅ Redis connected successfully');
    } catch (error) {
      this.isConnecting = false;
      this.handleConnectionError(error);
    }
  }

  setupEventHandlers() {
    this.client.on('ready', () => {
      this.isReady = true;
      console.log('✅ Redis client ready');
    });

    this.client.on('error', (error) => {
      console.error('❌ Redis error:', error);
      this.isReady = false;
    });

    this.client.on('end', () => {
      console.log('🔌 Redis connection ended');
      this.isReady = false;
    });

    this.client.on('reconnecting', () => {
      console.log('🔄 Redis reconnecting...');
      this.isReady = false;
    });
  }

  async disconnect() {
    if (this.client) {
      try {
        await this.client.quit();
        this.isReady = false;
        console.log('🔌 Redis disconnected');
      } catch (error) {
        console.error('❌ Redis disconnect error:', error);
      }
    }
  }

  getClient() {
    if (!this.client || !this.isReady) {
      throw new Error('Redis client not ready');
    }
    return this.client;
  }

  getStatus() {
    return {
      isReady: this.isReady,
      isConnecting: this.isConnecting,
      retryCount: this.retryCount
    };
  }

  async healthCheck() {
    try {
      if (!this.client || !this.isReady) {
        return { status: 'disconnected', error: 'Client not ready' };
      }
      
      await this.client.ping();
      return { status: 'healthy', timestamp: new Date().toISOString() };
    } catch (error) {
      return { status: 'unhealthy', error: error.message, timestamp: new Date().toISOString() };
    }
  }

  async forceReconnect() {
    console.log('🔄 Force reconnecting Redis...');
    await this.disconnect();
    this.retryCount = 0;
    await this.connect();
  }

  handleConnectionError(error) {
    console.error('❌ Redis connection failed:', error.message);
    this.retryCount++;
    
    if (this.retryCount < this.maxRetries) {
      const delay = Math.min(1000 * Math.pow(2, this.retryCount), 30000);
      console.log(`🔄 Retrying Redis connection in ${delay}ms (attempt ${this.retryCount}/${this.maxRetries})`);
      
      setTimeout(() => {
        this.connect();
      }, delay);
    } else {
      console.error('❌ Max Redis connection retries reached');
      process.exit(1);
    }
  }
}

module.exports = new RedisClientService();
