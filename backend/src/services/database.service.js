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

      // Log environnement sans exposer l'URI complète
      const maskedUri = mongoUri.replace(/\/\/([^:]+):([^@]+)@/, '//***:***@');
      console.log(`🔄 Connecting to MongoDB environment: ${process.env.NODE_ENV}`);
      console.log(`🔄 Masked URI: ${maskedUri}`);

      this.mongoConnection = await mongoose.connect(mongoUri, this.connectionOptions);
      
      // VALIDATION RÉELLE OBLIGATOIRE - Pas de simulation
      console.log('🔍 Validating MongoDB connection...');
      await mongoose.connection.db.admin().ping();
      console.log('✅ MongoDB ping successful');
      
      // Test écriture/lecture pour validation complète
      await this.validateConnectionWriteRead();
      
      this.isConnected = true;
      console.log('✅ MongoDB connected and validated successfully');

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

    } catch (error) {
      console.error('❌ MongoDB connection failed:', error);
      this.isConnected = false;
      throw error;
    }
  }

  async validateConnectionWriteRead() {
    try {
      const testDoc = {
        _id: 'connection_test_' + Date.now(),
        test: true,
        timestamp: new Date()
      };
      
      // Test écriture
      const collection = mongoose.connection.db.collection('_connection_test');
      await collection.insertOne(testDoc);
      
      // Test lecture
      const retrieved = await collection.findOne({ _id: testDoc._id });
      if (!retrieved) {
        throw new Error('Failed to retrieve test document');
      }
      
      // Nettoyer
      await collection.deleteOne({ _id: testDoc._id });
      
      console.log('✅ MongoDB write/read validation successful');
    } catch (error) {
      throw new Error(`MongoDB write/read validation failed: ${error.message}`);
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


