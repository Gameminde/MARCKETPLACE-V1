// Load environment variables first
require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });

const mongoose = require('mongoose');
const databaseService = require('../services/database.service');
const structuredLogger = require('../services/structured-logger.service');

class DatabaseIndexManager {
  constructor() {
    this.indexes = {
      // User indexes
      users: [
        { email: 1 }, // Unique email index
        { role: 1 }, // Role-based queries
        { 'profile.phone': 1 }, // Phone number queries
        { createdAt: -1 }, // Recent users
        { lastLoginAt: -1 }, // Active users
        { 'stats.totalOrders': -1 }, // Top customers
        { 'stats.totalSpent': -1 } // High-value customers
      ],

      // Product indexes
      products: [
        { shopId: 1, status: 1, createdAt: -1 }, // Shop products with status
        { category: 1, status: 1 }, // Category filtering
        { price: 1 }, // Price range queries
        { name: 'text', description: 'text' }, // Text search
        { tags: 1 }, // Tag-based queries
        { 'ratings.average': -1 }, // Top rated products
        { 'ratings.count': -1 }, // Most reviewed products
        { status: 1, createdAt: -1 }, // Active products
        { featured: 1, status: 1 }, // Featured products
        { discount: -1, status: 1 }, // Discounted products
        { createdAt: -1 }, // Recent products
        { updatedAt: -1 } // Recently updated
      ],

      // Shop indexes
      shops: [
        { ownerId: 1, status: 1 }, // User's shops
        { status: 1, createdAt: -1 }, // Active shops
        { name: 'text', description: 'text' }, // Text search
        { category: 1, status: 1 }, // Category filtering
        { 'stats.totalProducts': -1 }, // Most products
        { 'stats.totalSales': -1 }, // Top selling shops
        { 'stats.rating': -1 }, // Top rated shops
        { featured: 1, status: 1 }, // Featured shops
        { createdAt: -1 }, // Recent shops
        { updatedAt: -1 } // Recently updated
      ],

      // Order indexes
      orders: [
        { userId: 1, status: 1 }, // User orders
        { shopId: 1, status: 1 }, // Shop orders
        { status: 1, createdAt: -1 }, // Orders by status
        { paymentStatus: 1, status: 1 }, // Payment queries
        { createdAt: -1 }, // Recent orders
        { 'items.productId': 1 }, // Product order history
        { totalAmount: -1 }, // High-value orders
        { 'shipping.address.country': 1 }, // Geographic queries
        { 'shipping.address.city': 1 } // City-based queries
      ],

      // Review indexes
      reviews: [
        { productId: 1, status: 1 }, // Product reviews
        { userId: 1, status: 1 }, // User reviews
        { shopId: 1, status: 1 }, // Shop reviews
        { rating: -1, status: 1 }, // High-rated reviews
        { createdAt: -1 }, // Recent reviews
        { helpful: -1, status: 1 }, // Most helpful reviews
        { productId: 1, rating: -1 } // Product rating queries
      ],

      // Cart indexes
      carts: [
        { userId: 1 }, // User cart
        { sessionId: 1 }, // Session cart
        { updatedAt: -1 }, // Recent cart updates
        { 'items.productId': 1 } // Product in carts
      ],

      // Message indexes
      messages: [
        { conversationId: 1, createdAt: -1 }, // Conversation messages
        { senderId: 1, createdAt: -1 }, // User messages
        { recipientId: 1, createdAt: -1 }, // Received messages
        { type: 1, createdAt: -1 }, // Message type queries
        { read: 1, createdAt: -1 } // Unread messages
      ],

      // Template indexes
      templates: [
        { category: 1, status: 1 }, // Template categories
        { status: 1, createdAt: -1 }, // Active templates
        { name: 'text', description: 'text' }, // Text search
        { featured: 1, status: 1 }, // Featured templates
        { downloads: -1 }, // Popular templates
        { createdAt: -1 } // Recent templates
      ]
    };
  }

  async createIndexes() {
    try {
      await databaseService.connect();
      
      structuredLogger.logInfo('DATABASE_INDEX_CREATION_START');

      for (const [collectionName, indexes] of Object.entries(this.indexes)) {
        await this.createCollectionIndexes(collectionName, indexes);
      }

      structuredLogger.logInfo('DATABASE_INDEX_CREATION_COMPLETE');
    } catch (error) {
      structuredLogger.logError('DATABASE_INDEX_CREATION_FAILED', {
        error: error.message
      });
      throw error;
    }
  }

  async createCollectionIndexes(collectionName, indexes) {
    try {
      const collection = mongoose.connection.db.collection(collectionName);
      
      structuredLogger.logInfo('CREATING_INDEXES_FOR_COLLECTION', {
        collection: collectionName,
        count: indexes.length
      });

      for (const indexSpec of indexes) {
        try {
          const options = {};
          
          // Handle text indexes
          if (typeof indexSpec === 'object' && indexSpec.text) {
            options.text = true;
          }
          
          // Handle unique indexes
          if (indexSpec.unique) {
            options.unique = true;
          }
          
          // Handle sparse indexes
          if (indexSpec.sparse) {
            options.sparse = true;
          }

          await collection.createIndex(indexSpec, options);
          
          structuredLogger.logDebug('INDEX_CREATED', {
            collection: collectionName,
            index: JSON.stringify(indexSpec),
            options
          });
        } catch (indexError) {
          if (indexError.code === 85) {
            // Index already exists
            structuredLogger.logDebug('INDEX_ALREADY_EXISTS', {
              collection: collectionName,
              index: JSON.stringify(indexSpec)
            });
          } else {
            structuredLogger.logError('INDEX_CREATION_FAILED', {
              collection: collectionName,
              index: JSON.stringify(indexSpec),
              error: indexError.message
            });
          }
        }
      }
    } catch (error) {
      structuredLogger.logError('COLLECTION_INDEX_CREATION_FAILED', {
        collection: collectionName,
        error: error.message
      });
      throw error;
    }
  }

  async dropIndexes(collectionName) {
    try {
      const collection = mongoose.connection.db.collection(collectionName);
      await collection.dropIndexes();
      
      structuredLogger.logInfo('INDEXES_DROPPED', {
        collection: collectionName
      });
    } catch (error) {
      structuredLogger.logError('INDEX_DROP_FAILED', {
        collection: collectionName,
        error: error.message
      });
      throw error;
    }
  }

  async listIndexes(collectionName) {
    try {
      const collection = mongoose.connection.db.collection(collectionName);
      const indexes = await collection.indexes();
      
      structuredLogger.logInfo('COLLECTION_INDEXES', {
        collection: collectionName,
        indexes: indexes.map(idx => ({
          name: idx.name,
          key: idx.key,
          unique: idx.unique,
          sparse: idx.sparse
        }))
      });
      
      return indexes;
    } catch (error) {
      structuredLogger.logError('INDEX_LIST_FAILED', {
        collection: collectionName,
        error: error.message
      });
      throw error;
    }
  }

  async analyzeIndexUsage() {
    try {
      const collections = Object.keys(this.indexes);
      const analysis = {};

      for (const collectionName of collections) {
        const collection = mongoose.connection.db.collection(collectionName);
        const stats = await collection.aggregate([
          { $indexStats: {} }
        ]).toArray();
        
        analysis[collectionName] = stats;
      }

      structuredLogger.logInfo('INDEX_USAGE_ANALYSIS', analysis);
      return analysis;
    } catch (error) {
      structuredLogger.logError('INDEX_ANALYSIS_FAILED', {
        error: error.message
      });
      throw error;
    }
  }

  async optimizeIndexes() {
    try {
      structuredLogger.logInfo('INDEX_OPTIMIZATION_START');

      // Analyze current index usage
      const usage = await this.analyzeIndexUsage();

      // Remove unused indexes (this is a simplified example)
      for (const [collectionName, stats] of Object.entries(usage)) {
        const unusedIndexes = stats.filter(stat => 
          stat.accesses && stat.accesses.ops === 0
        );

        for (const unusedIndex of unusedIndexes) {
          if (unusedIndex.name !== '_id_') {
            try {
              const collection = mongoose.connection.db.collection(collectionName);
              await collection.dropIndex(unusedIndex.name);
              
              structuredLogger.logInfo('UNUSED_INDEX_REMOVED', {
                collection: collectionName,
                index: unusedIndex.name
              });
            } catch (dropError) {
              structuredLogger.logWarning('INDEX_DROP_FAILED', {
                collection: collectionName,
                index: unusedIndex.name,
                error: dropError.message
              });
            }
          }
        }
      }

      structuredLogger.logInfo('INDEX_OPTIMIZATION_COMPLETE');
    } catch (error) {
      structuredLogger.logError('INDEX_OPTIMIZATION_FAILED', {
        error: error.message
      });
      throw error;
    }
  }
}

// CLI execution
if (require.main === module) {
  const manager = new DatabaseIndexManager();
  
  const command = process.argv[2];
  
  switch (command) {
    case 'create':
      manager.createIndexes()
        .then(() => {
          console.log('✅ Indexes created successfully');
          process.exit(0);
        })
        .catch((error) => {
          console.error('❌ Failed to create indexes:', error.message);
          process.exit(1);
        });
      break;
      
    case 'list':
      const collectionName = process.argv[3];
      if (!collectionName) {
        console.error('❌ Collection name required');
        process.exit(1);
      }
      
      manager.listIndexes(collectionName)
        .then(() => process.exit(0))
        .catch((error) => {
          console.error('❌ Failed to list indexes:', error.message);
          process.exit(1);
        });
      break;
      
    case 'analyze':
      manager.analyzeIndexUsage()
        .then(() => process.exit(0))
        .catch((error) => {
          console.error('❌ Failed to analyze indexes:', error.message);
          process.exit(1);
        });
      break;
      
    case 'optimize':
      manager.optimizeIndexes()
        .then(() => {
          console.log('✅ Indexes optimized successfully');
          process.exit(0);
        })
        .catch((error) => {
          console.error('❌ Failed to optimize indexes:', error.message);
          process.exit(1);
        });
      break;
      
    default:
      console.log('Usage: node create-database-indexes.js <command> [collection]');
      console.log('Commands: create, list, analyze, optimize');
      process.exit(1);
  }
}

module.exports = DatabaseIndexManager;
