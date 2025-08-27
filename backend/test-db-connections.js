const { MongoClient, ServerApiVersion } = require('mongodb');
const { Client } = require('pg');
require('dotenv').config();

async function testMongoConnection() {
  console.log('🔍 Test de connexion MongoDB Atlas...');
  const client = new MongoClient(process.env.MONGODB_URI, {
    serverApi: {
      version: ServerApiVersion.v1,
      strict: true,
      deprecationErrors: true,
    }
  });

  try {
    await client.connect();
    await client.db("admin").command({ ping: 1 });
    console.log('✅ MongoDB Atlas : Connexion réussie !');
    
    // Test création collection
    const db = client.db('marketplace');
    await db.collection('templates').insertOne({
      test: 'connection',
      timestamp: new Date()
    });
    console.log('✅ MongoDB : Test d\'écriture réussi !');
    
    return true;
  } catch (error) {
    console.error('❌ MongoDB Erreur:', error.message);
    return false;
  } finally {
    await client.close();
  }
}

async function testPostgresConnection() {
  console.log('🔍 Test de connexion Neon PostgreSQL...');
  const client = new Client({
    connectionString: process.env.POSTGRES_URI,
  });

  try {
    await client.connect();
    const result = await client.query('SELECT version()');
    console.log('✅ Neon PostgreSQL : Connexion réussie !');
    console.log('📊 Version:', result.rows[0].version.substring(0, 50) + '...');
    
    // Test création table
    await client.query(`
      CREATE TABLE IF NOT EXISTS test_connection (
        id SERIAL PRIMARY KEY,
        message TEXT,
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);
    
    await client.query(`
      INSERT INTO test_connection (message) VALUES ('Test de connexion réussi')
    `);
    
    console.log('✅ PostgreSQL : Test d\'écriture réussi !');
    return true;
  } catch (error) {
    console.error('❌ PostgreSQL Erreur:', error.message);
    return false;
  } finally {
    await client.end();
  }
}

async function runAllTests() {
  console.log('🚀 Début des tests de connexion base de données...\n');
  
  const mongoResult = await testMongoConnection();
  console.log('');
  const postgresResult = await testPostgresConnection();
  
  console.log('\n📊 RÉSULTATS FINAUX :');
  console.log(`MongoDB Atlas : ${mongoResult ? '✅ OK' : '❌ ÉCHEC'}`);
  console.log(`Neon PostgreSQL : ${postgresResult ? '✅ OK' : '❌ ÉCHEC'}`);
  
  if (mongoResult && postgresResult) {
    console.log('\n🎉 TOUTES LES CONNEXIONS SONT FONCTIONNELLES !');
    console.log('🚀 Votre marketplace peut maintenant utiliser de vraies données !');
  } else {
    console.log('\n⚠️  Certaines connexions ont échoué. Vérifiez vos credentials.');
  }
}

runAllTests().catch(console.error);
