// ========================================
// DATABASE HYBRID SERVICE - PHASE 4
// MongoDB (produits) + PostgreSQL (users/orders)
// ========================================

const mongoose = require('mongoose');
const { Pool } = require('pg');
const Redis = require('ioredis');
const productionConfig = require('../../config/production.config');
const structuredLogger = require('./structured-logger.service');

class DatabaseHybridService {
  constructor() {
    this.mongoConnection = null;
    this.postgresPool = null;
    this.redisClient = null;
    this.isConnected = false;
    this.healthStatus = {
      mongodb: 'disconnected',
      postgresql: 'disconnected',
      redis: 'disconnected'
    };
  }

  // ========================================
  // CONNECTION MANAGEMENT
  // ========================================
  
  async connect() {
    try {
      console.log('🚀 Initializing hybrid database connections...');
      
      // Connect to MongoDB Atlas
      await this.connectMongoDB();
      
      // Connect to PostgreSQL Neon
      await this.connectPostgreSQL();
      
      // Connect to Redis
      await this.connectRedis();
      
      this.isConnected = true;
      console.log('✅ All database connections established successfully');
      
      // Setup graceful shutdown
      this.setupGracefulShutdown();
      
      return true;
    } catch (error) {
      console.error('❌ Database connection failed:', error.message);
      structuredLogger.logError('DATABASE_CONNECTION_FAILED', { error: error.message });
      throw error;
    }
  }

  async connectMongoDB() {
    try {
      const { uri, options } = productionConfig.databases.mongodb;
      
      // Mask URI for logging
      const maskedUri = uri.replace(/\/\/([^:]+):([^@]+)@/, '//***:***@');
      console.log(`🔄 Connecting to MongoDB Atlas: ${maskedUri}`);
      
      this.mongoConnection = await mongoose.connect(uri, {
        ...options,
        bufferCommands: false,
        bufferMaxEntries: 0
      });

      // Validate connection
      await mongoose.connection.db.admin().ping();
      console.log('✅ MongoDB Atlas connected and validated');
      
      this.healthStatus.mongodb = 'connected';
      
      // Connection event handlers
      mongoose.connection.on('error', (error) => {
        console.error('❌ MongoDB error:', error);
        this.healthStatus.mongodb = 'error';
        structuredLogger.logError('MONGODB_ERROR', { error: error.message });
      });

      mongoose.connection.on('disconnected', () => {
        console.warn('⚠️ MongoDB disconnected');
        this.healthStatus.mongodb = 'disconnected';
        structuredLogger.logWarning('MONGODB_DISCONNECTED');
      });

    } catch (error) {
      console.error('❌ MongoDB connection failed:', error.message);
      this.healthStatus.mongodb = 'failed';
      throw error;
    }
  }

  async connectPostgreSQL() {
    try {
      const { uri, options } = productionConfig.databases.postgresql;
      
      // Mask URI for logging
      const maskedUri = uri.replace(/\/\/([^:]+):([^@]+)@/, '//***:***@');
      console.log(`🔄 Connecting to PostgreSQL Neon: ${maskedUri}`);
      
      this.postgresPool = new Pool({
        connectionString: uri,
        ...options
      });

      // Test connection
      const client = await this.postgresPool.connect();
      await client.query('SELECT NOW()');
      client.release();
      
      console.log('✅ PostgreSQL Neon connected and validated');
      this.healthStatus.postgresql = 'connected';
      
      // Pool event handlers
      this.postgresPool.on('error', (error) => {
        console.error('❌ PostgreSQL pool error:', error);
        this.healthStatus.postgresql = 'error';
        structuredLogger.logError('POSTGRESQL_ERROR', { error: error.message });
      });

    } catch (error) {
      console.error('❌ PostgreSQL connection failed:', error.message);
      this.healthStatus.postgresql = 'failed';
      throw error;
    }
  }

  async connectRedis() {
    try {
      const { url, options } = productionConfig.databases.redis;
      console.log(`🔄 Connecting to Redis: ${url}`);
      
      this.redisClient = new Redis(url, {
        ...options,
        retryStrategy: (times) => {
          const delay = Math.min(times * 50, 2000);
          return delay;
        }
      });

      // Test connection
      await this.redisClient.ping();
      console.log('✅ Redis connected and validated');
      this.healthStatus.redis = 'connected';
      
      // Redis event handlers
      this.redisClient.on('error', (error) => {
        console.error('❌ Redis error:', error);
        this.healthStatus.redis = 'error';
        structuredLogger.logError('REDIS_ERROR', { error: error.message });
      });

      this.redisClient.on('connect', () => {
        console.log('✅ Redis reconnected');
        this.healthStatus.redis = 'connected';
      });

    } catch (error) {
      console.error('❌ Redis connection failed:', error.message);
      this.healthStatus.redis = 'failed';
      // Redis is optional, don't throw
      console.warn('⚠️ Redis connection failed, continuing without cache');
    }
  }

  // ========================================
  // DATABASE OPERATIONS
  // ========================================
  
  // MongoDB operations (products, shops, templates)
  getMongoDB() {
    if (!this.mongoConnection) {
      throw new Error('MongoDB not connected');
    }
    return mongoose.connection;
  }

  // PostgreSQL operations (users, orders, transactions)
  async queryPostgreSQL(text, params = []) {
    if (!this.postgresPool) {
      throw new Error('PostgreSQL not connected');
    }
    
    const startTime = Date.now();
    try {
      const result = await this.postgresPool.query(text, params);
      const duration = Date.now() - startTime;
      
      // Log slow queries
      if (duration > 1000) {
        structuredLogger.logWarning('SLOW_QUERY', { 
          query: text, 
          duration, 
          params: params.length 
        });
      }
      
      return result;
    } catch (error) {
      structuredLogger.logError('POSTGRESQL_QUERY_ERROR', { 
        query: text, 
        error: error.message,
        params: params.length 
      });
      throw error;
    }
  }

  // Redis operations (cache, sessions)
  async getRedis() {
    if (!this.redisClient || this.healthStatus.redis !== 'connected') {
      return null;
    }
    return this.redisClient;
  }

  // ========================================
  // HEALTH CHECK & MONITORING
  // ========================================
  
  async healthCheck() {
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      databases: { ...this.healthStatus },
      details: {}
    };

    try {
      // Test MongoDB
      if (this.mongoConnection) {
        await mongoose.connection.db.admin().ping();
        health.details.mongodb = { status: 'ok', responseTime: 'fast' };
      }
    } catch (error) {
      health.status = 'unhealthy';
      health.details.mongodb = { status: 'error', error: error.message };
    }

    try {
      // Test PostgreSQL
      if (this.postgresPool) {
        const startTime = Date.now();
        await this.postgresPool.query('SELECT 1');
        const responseTime = Date.now() - startTime;
        health.details.postgresql = { status: 'ok', responseTime: `${responseTime}ms` };
      }
    } catch (error) {
      health.status = 'unhealthy';
      health.details.postgresql = { status: 'error', error: error.message };
    }

    try {
      // Test Redis
      if (this.redisClient) {
        const startTime = Date.now();
        await this.redisClient.ping();
        const responseTime = Date.now() - startTime;
        health.details.redis = { status: 'ok', responseTime: `${responseTime}ms` };
      }
    } catch (error) {
      health.details.redis = { status: 'error', error: error.message };
      // Redis is optional, don't affect overall health
    }

    return health;
  }

  // ========================================
  // TRANSACTION MANAGEMENT
  // ========================================
  
  async withTransaction(callback) {
    if (!this.postgresPool) {
      throw new Error('PostgreSQL not connected');
    }

    const client = await this.postgresPool.connect();
    try {
      await client.query('BEGIN');
      const result = await callback(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  // ========================================
  // GRACEFUL SHUTDOWN
  // ========================================
  
  setupGracefulShutdown() {
    const shutdown = async (signal) => {
      console.log(`\n🔄 Received ${signal}, shutting down gracefully...`);
      
      try {
        // Close MongoDB connection
        if (this.mongoConnection) {
          await mongoose.connection.close();
          console.log('✅ MongoDB connection closed');
        }

        // Close PostgreSQL pool
        if (this.postgresPool) {
          await this.postgresPool.end();
          console.log('✅ PostgreSQL pool closed');
        }

        // Close Redis connection
        if (this.redisClient) {
          await this.redisClient.quit();
          console.log('✅ Redis connection closed');
        }

        console.log('✅ All database connections closed gracefully');
        process.exit(0);
      } catch (error) {
        console.error('❌ Error during graceful shutdown:', error);
        process.exit(1);
      }
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));
  }

  // ========================================
  // UTILITY METHODS
  // ========================================
  
  isConnected() {
    return this.isConnected;
  }

  getConnectionStatus() {
    return {
      mongodb: this.healthStatus.mongodb,
      postgresql: this.healthStatus.postgresql,
      redis: this.healthStatus.redis,
      overall: this.isConnected
    };
  }

  async disconnect() {
    try {
      if (this.mongoConnection) {
        await mongoose.connection.close();
      }
      if (this.postgresPool) {
        await this.postgresPool.end();
      }
      if (this.redisClient) {
        await this.redisClient.quit();
      }
      this.isConnected = false;
      console.log('✅ All database connections closed');
    } catch (error) {
      console.error('❌ Error during disconnect:', error);
      throw error;
    }
  }
}

// Singleton instance
const databaseHybridService = new DatabaseHybridService();

module.exports = databaseHybridService;
