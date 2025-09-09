const axios = require('axios');

async function testIntegration() {
  try {
    console.log('Testing backend API integration...');
    
    // Test health endpoint
    const healthResponse = await axios.get('http://localhost:3001/health');
    console.log('Health check:', healthResponse.data.status);
    
    // Test registration endpoint
    const registerResponse = await axios.post('http://localhost:3001/api/v1/auth/register', {
      email: 'test@example.com',
      password: 'password123',
      name: 'Test User'
    });
    
    console.log('Registration response:', registerResponse.data);
    
    console.log('Integration test completed successfully!');
  } catch (error) {
    console.error('Integration test failed:', error.message);
  }
}

testIntegration();