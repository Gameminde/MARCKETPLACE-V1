const axios = require('axios');

async function testAPI() {
  try {
    console.log('Testing backend...');
    
    // Test health endpoint
    const healthResponse = await axios.get('http://localhost:3001/health');
    console.log('✅ Health:', healthResponse.status, healthResponse.data);
    
    // Test auth register
    const authResponse = await axios.post('http://localhost:3001/api/v1/auth/register', {
      email: 'test@marketplace.dz',
      password: 'TestPassword123!',
      firstName: 'Test',
      lastName: 'User'
    });
    console.log('✅ Auth Register:', authResponse.status, authResponse.data);
    
  } catch (error) {
    console.log('❌ Error:', error.response?.status, error.response?.data || error.message);
  }
}

testAPI();
