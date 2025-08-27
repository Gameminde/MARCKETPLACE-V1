const mongoose = require('mongoose');

class DatabaseService {
  constructor() {
    this.mongoConnection = null;
    this.isConnected = false;
    this.connectionOptions = {
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
      bufferCommands: false
    };
  }

  async connect() {
    try {
      if (this.isConnected) {
        console.log('✅ MongoDB already connected');
        return;
      }

      const mongoUri = process.env.MONGODB_URI;
      if (!mongoUri) {
        throw new Error('MONGODB_URI environment variable is required');
      }

      // Pour le développement, on simule la connexion si c'est un URI localhost
      if (mongoUri.includes('localhost') || mongoUri.includes('127.0.0.1')) {
        console.log('🔄 Simulating MongoDB connection for local development...');
        this.isConnected = true;
        console.log('✅ MongoDB connection simulated successfully');
        return;
      }

      console.log('🔄 Connecting to MongoDB...');
      
      this.mongoConnection = await mongoose.connect(mongoUri, this.connectionOptions);
      
      this.isConnected = true;
      console.log('✅ MongoDB connected successfully');

      // Event handlers
      mongoose.connection.on('error', (error) => {
        console.error('❌ MongoDB connection error:', error);
        this.isConnected = false;
      });

      mongoose.connection.on('disconnected', () => {
        console.log('🔌 MongoDB disconnected');
        this.isConnected = false;
      });

      mongoose.connection.on('reconnected', () => {
        console.log('🔄 MongoDB reconnected');
        this.isConnected = true;
      });

      // Graceful shutdown
      process.on('SIGINT', this.gracefulShutdown.bind(this));
      process.on('SIGTERM', this.gracefulShutdown.bind(this));

    } catch (error) {
      console.error('❌ MongoDB connection failed:', error);
      this.isConnected = false;
      throw error;
    }
  }

  async disconnect() {
    try {
      if (this.mongoConnection) {
        await mongoose.disconnect();
        this.mongoConnection = null;
        this.isConnected = false;
        console.log('🔌 MongoDB disconnected');
      }
    } catch (error) {
      console.error('❌ Error disconnecting MongoDB:', error);
    }
  }

  async gracefulShutdown() {
    console.log('🔄 Gracefully shutting down database connections...');
    try {
      await this.disconnect();
      process.exit(0);
    } catch (error) {
      console.error('❌ Error during graceful shutdown:', error);
      process.exit(1);
    }
  }

  getConnectionStatus() {
    return {
      isConnected: this.isConnected,
      mongoConnection: this.mongoConnection ? 'active' : 'inactive',
      timestamp: new Date().toISOString()
    };
  }

  async healthCheck() {
    try {
      if (!this.isConnected) {
        return {
          status: 'disconnected',
          error: 'Database not connected',
          timestamp: new Date().toISOString()
        };
      }

      // Test de connexion simple
      await mongoose.connection.db.admin().ping();
      
      return {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        connections: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  getMongoConnection() {
    return this.mongoConnection;
  }

  isReady() {
    return this.isConnected && mongoose.connection.readyState === 1;
  }
}

module.exports = new DatabaseService();


