#!/usr/bin/env node
/**
 * API ENDPOINTS TEST SCRIPT
 * Tests all API endpoints to identify issues
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:3001';
const API_BASE = `${BASE_URL}/api/v1`;

const testEndpoint = async (method, url, data = null, headers = {}, baseUrl = API_BASE) => {
  try {
    console.log(`\n🧪 Testing ${method.toUpperCase()} ${url}`);
    
    const config = {
      method,
      url: `${baseUrl}${url}`,
      headers: {
        'Content-Type': 'application/json',
        ...headers
      },
      timeout: 5000
    };
    
    if (data) {
      config.data = data;
    }
    
    const response = await axios(config);
    
    console.log(`✅ Status: ${response.status}`);
    console.log(`📄 Response:`, JSON.stringify(response.data, null, 2));
    
    return {
      success: true,
      status: response.status,
      data: response.data
    };
    
  } catch (error) {
    console.log(`❌ Error: ${error.response?.status || 'Network Error'}`);
    console.log(`📄 Error Data:`, error.response?.data || error.message);
    
    return {
      success: false,
      status: error.response?.status || 500,
      error: error.response?.data || error.message
    };
  }
};

const runTests = async () => {
  console.log('🚀 Starting API Endpoints Test');
  console.log(`Target: ${API_BASE}`);
  
  // Test 1: Health check (direct endpoint)
  console.log('\n🏥 Testing Health Endpoints:');
  await testEndpoint('GET', '/health', null, {}, 'http://localhost:3001');
  
  // Test 1.5: API Health check
  await testEndpoint('GET', '/health');
  
  // Test 2: Auth endpoints
  console.log('\n🔐 Testing Auth Endpoints:');
  
  // Test registration
  await testEndpoint('POST', '/auth/register', {
    email: 'test@marketplace.dz',
    password: 'TestPassword123!',
    firstName: 'Test',
    lastName: 'User'
  });
  
  // Test login
  await testEndpoint('POST', '/auth/login', {
    email: 'test@marketplace.dz',
    password: 'TestPassword123!'
  });
  
  // Test 3: Products endpoints
  console.log('\n📦 Testing Products Endpoints:');
  await testEndpoint('GET', '/products');
  await testEndpoint('POST', '/products', {
    name: 'Test Product',
    description: 'Test description',
    price: 1000,
    category: 'Electronics'
  });
  
  // Test 4: Cart endpoints (will fail without auth)
  console.log('\n🛒 Testing Cart Endpoints:');
  await testEndpoint('GET', '/cart');
  await testEndpoint('POST', '/cart/add', {
    productId: '1',
    quantity: 1
  });
  
  console.log('\n✅ API Endpoints Test Complete');
};

runTests().catch(console.error);
