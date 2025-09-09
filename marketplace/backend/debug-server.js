const path = require('path');
const fs = require('fs');

console.log('🔍 Debugging .env file loading...');
console.log('Current working directory:', process.cwd());
console.log('__dirname:', __dirname);

// Check if .env file exists
const envPath = path.resolve(__dirname, '.env');
console.log('Looking for .env at:', envPath);
console.log('.env file exists:', fs.existsSync(envPath));

if (fs.existsSync(envPath)) {
  console.log('.env file size:', fs.statSync(envPath).size, 'bytes');
  
  // Try to load the .env file
  try {
    const result = require('dotenv').config({ path: envPath });
    if (result.error) {
      console.error('Error loading .env:', result.error.message);
    } else {
      console.log('✅ .env loaded successfully');
      console.log('MONGODB_URI:', process.env.MONGODB_URI ? 'SET' : 'NOT SET');
      console.log('JWT_SECRET:', process.env.JWT_SECRET ? 'SET' : 'NOT SET');
    }
  } catch (error) {
    console.error('Exception loading .env:', error.message);
  }
} else {
  console.error('❌ .env file not found');
}