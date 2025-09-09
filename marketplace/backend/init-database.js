const mongoose = require('mongoose');

// MongoDB connection URI
const uri = 'mongodb://localhost:27017/marketplace';

console.log('🔄 Initializing Marketplace Database...');

mongoose.connect(uri, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(async () => {
  console.log('✅ MongoDB connection successful!');
  
  // Get database instance
  const db = mongoose.connection.db;
  
  // Create collections with indexes
  console.log('\n📁 Creating collections and indexes...');
  
  // Users collection
  try {
    await db.createCollection('users');
    const usersCollection = db.collection('users');
    await usersCollection.createIndex({ "email": 1 }, { unique: true });
    await usersCollection.createIndex({ "createdAt": -1 });
    console.log('  ✅ Users collection created with indexes');
  } catch (err) {
    if (err.code === 48) {
      console.log('  ℹ️  Users collection already exists');
    } else {
      console.error('  ❌ Error creating users collection:', err.message);
    }
  }
  
  // Products collection
  try {
    await db.createCollection('products');
    const productsCollection = db.collection('products');
    await productsCollection.createIndex({ "name": "text", "description": "text" });
    await productsCollection.createIndex({ "category": 1 });
    await productsCollection.createIndex({ "price": 1 });
    await productsCollection.createIndex({ "createdAt": -1 });
    console.log('  ✅ Products collection created with indexes');
  } catch (err) {
    if (err.code === 48) {
      console.log('  ℹ️  Products collection already exists');
    } else {
      console.error('  ❌ Error creating products collection:', err.message);
    }
  }
  
  // Orders collection
  try {
    await db.createCollection('orders');
    const ordersCollection = db.collection('orders');
    await ordersCollection.createIndex({ "userId": 1, "createdAt": -1 });
    await ordersCollection.createIndex({ "status": 1 });
    console.log('  ✅ Orders collection created with indexes');
  } catch (err) {
    if (err.code === 48) {
      console.log('  ℹ️  Orders collection already exists');
    } else {
      console.error('  ❌ Error creating orders collection:', err.message);
    }
  }
  
  // Cart collection
  try {
    await db.createCollection('cart');
    const cartCollection = db.collection('cart');
    await cartCollection.createIndex({ "userId": 1 });
    await cartCollection.createIndex({ "productId": 1 });
    console.log('  ✅ Cart collection created with indexes');
  } catch (err) {
    if (err.code === 48) {
      console.log('  ℹ️  Cart collection already exists');
    } else {
      console.error('  ❌ Error creating cart collection:', err.message);
    }
  }
  
  // XP/Levels collection
  try {
    await db.createCollection('xp_levels');
    const xpLevelsCollection = db.collection('xp_levels');
    await xpLevelsCollection.createIndex({ "level": 1 }, { unique: true });
    console.log('  ✅ XP Levels collection created with indexes');
  } catch (err) {
    if (err.code === 48) {
      console.log('  ℹ️  XP Levels collection already exists');
    } else {
      console.error('  ❌ Error creating XP Levels collection:', err.message);
    }
  }
  
  // List all collections
  const collections = await db.listCollections().toArray();
  console.log(`\n📁 Database initialized with ${collections.length} collections:`);
  
  collections.forEach(collection => {
    console.log(`  - ${collection.name}`);
  });
  
  // Close the connection
  await mongoose.connection.close();
  console.log('\n✅ Database initialization completed successfully!');
})
.catch(err => {
  console.error('❌ MongoDB connection failed:', err.message);
});