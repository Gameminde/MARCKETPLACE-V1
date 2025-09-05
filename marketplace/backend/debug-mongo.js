require('dotenv').config();

console.log('🔍 DEBUGGING MONGODB CONNECTION');
console.log('================================');

// Check environment variables
console.log('📍 MONGODB_URI from .env:', process.env.MONGODB_URI ? 'DEFINED' : 'NOT DEFINED');

if (process.env.MONGODB_URI) {
  const uri = process.env.MONGODB_URI;
  
  // Parse the URI to check components
  console.log('\n🔗 URI ANALYSIS:');
  console.log('Full URI (masked):', uri.replace(/\/\/[^:]+:[^@]+@/, '//***:***@'));
  
  // Check if it contains the encoded username
  if (uri.includes('Marcketplace%40admin')) {
    console.log('✅ Username is properly encoded (Marcketplace%40admin)');
  } else if (uri.includes('Marcketplace@admin')) {
    console.log('❌ Username is NOT encoded - @ character found');
    console.log('💡 Should be: Marcketplace%40admin');
  } else {
    console.log('❓ Username format unclear');
  }
  
  // Check password
  if (uri.includes(':Marcketplace@')) {
    console.log('✅ Password appears to be: Marcketplace');
  }
  
  // Check cluster
  if (uri.includes('marcketplace.zzylzct.mongodb.net')) {
    console.log('✅ Cluster: marcketplace.zzylzct.mongodb.net');
  }
  
  // Check database
  if (uri.includes('/marketplace?')) {
    console.log('✅ Database: marketplace');
  }
}

console.log('\n🧪 TESTING BASIC CONNECTION...');

// Simple connection test
const { MongoClient } = require('mongodb');

async function testConnection() {
  const client = new MongoClient(process.env.MONGODB_URI);
  
  try {
    console.log('⏳ Connecting...');
    await client.connect();
    console.log('✅ CONNECTION SUCCESSFUL!');
    
    // Test database access
    const db = client.db('marketplace');
    const collections = await db.listCollections().toArray();
    console.log(`📁 Found ${collections.length} collections`);
    
  } catch (error) {
    console.log('❌ CONNECTION FAILED:');
    console.log('Error type:', error.constructor.name);
    console.log('Error message:', error.message);
    
    if (error.message.includes('bad auth')) {
      console.log('\n🔐 AUTHENTICATION ISSUE:');
      console.log('- Check username: Marcketplace@admin');
      console.log('- Check password: Marcketplace');
      console.log('- Verify MongoDB Atlas user exists');
      console.log('- Check user permissions');
    }
    
  } finally {
    await client.close();
  }
}

testConnection();