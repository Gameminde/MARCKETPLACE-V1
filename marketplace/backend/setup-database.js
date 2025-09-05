const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');
const path = require('path');

// Load environment variables
require('dotenv').config({ path: path.join(__dirname, '.env') });

class DatabaseSetup {
  constructor() {
    this.mongoServer = null;
    this.isUsingMemoryServer = false;
  }

  async start() {
    console.log('🚀 Démarrage de la configuration de la base de données...');
    
    try {
      // Essayer d'abord la connexion locale
      await this.connectToLocal();
    } catch (error) {
      console.log('⚠️  MongoDB local non disponible, utilisation de MongoDB en mémoire...');
      await this.connectToMemory();
    }
  }

  async connectToLocal() {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/marketplace';
    
    console.log('🔄 Tentative de connexion à MongoDB local...');
    console.log(`📍 URI: ${mongoUri.replace(/\/\/([^:]+):([^@]+)@/, '//***:***@')}`);
    
    await mongoose.connect(mongoUri, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 5000
    });
    
    console.log('✅ Connexion à MongoDB local réussie !');
  }

  async connectToMemory() {
    console.log('🔄 Démarrage de MongoDB en mémoire...');
    
    this.mongoServer = await MongoMemoryServer.create();
    const mongoUri = this.mongoServer.getUri();
    
    await mongoose.connect(mongoUri, {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
    
    this.isUsingMemoryServer = true;
    console.log('✅ MongoDB en mémoire démarré avec succès !');
  }

  async createIndexes() {
    console.log('📊 Création des index de base de données...');
    
    const indexes = {
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

    for (const [collectionName, collectionIndexes] of Object.entries(indexes)) {
      try {
        const collection = mongoose.connection.db.collection(collectionName);
        
        console.log(`📝 Création des index pour la collection: ${collectionName}`);
        
        for (const indexSpec of collectionIndexes) {
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
            console.log(`  ✅ Index créé: ${JSON.stringify(indexSpec)}`);
          } catch (indexError) {
            if (indexError.code === 85) {
              console.log(`  ⚠️  Index déjà existant: ${JSON.stringify(indexSpec)}`);
            } else {
              console.log(`  ❌ Erreur index: ${indexError.message}`);
            }
          }
        }
      } catch (error) {
        console.log(`❌ Erreur collection ${collectionName}: ${error.message}`);
      }
    }
    
    console.log('✅ Tous les index ont été créés avec succès !');
  }

  async stop() {
    if (this.isUsingMemoryServer && this.mongoServer) {
      console.log('🔄 Arrêt de MongoDB en mémoire...');
      await this.mongoServer.stop();
      console.log('✅ MongoDB en mémoire arrêté.');
    }
    
    await mongoose.disconnect();
    console.log('✅ Connexion MongoDB fermée.');
  }

  async run() {
    try {
      await this.start();
      await this.createIndexes();
      
      console.log('\n🎉 Configuration de la base de données terminée avec succès !');
      console.log('📊 Vous pouvez maintenant exécuter: npm start');
      
    } catch (error) {
      console.error('❌ Erreur lors de la configuration:', error.message);
      process.exit(1);
    } finally {
      await this.stop();
    }
  }
}

// Exécuter si ce fichier est appelé directement
if (require.main === module) {
  const setup = new DatabaseSetup();
  setup.run();
}

module.exports = DatabaseSetup;
