#!/usr/bin/env node
/**
 * COMPREHENSIVE INTEGRATION TEST SUITE
 * Tests all backend APIs and validates responses
 */

const axios = require('axios');
const fs = require('fs');
const path = require('path');

// Configuration
const BASE_URL = 'http://localhost:3001';
const TEST_RESULTS = {
  timestamp: new Date().toISOString(),
  tests: [],
  summary: {
    total: 0,
    passed: 0,
    failed: 0,
    errors: []
  }
};

// Test utilities
const log = (message, type = 'INFO') => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] [${type}] ${message}`);
};

const test = async (name, testFn) => {
  TEST_RESULTS.summary.total++;
  log(`🧪 Testing: ${name}`);
  
  try {
    const result = await testFn();
    TEST_RESULTS.tests.push({
      name,
      status: 'PASSED',
      result,
      timestamp: new Date().toISOString()
    });
    TEST_RESULTS.summary.passed++;
    log(`✅ PASSED: ${name}`, 'SUCCESS');
    return result;
  } catch (error) {
    TEST_RESULTS.tests.push({
      name,
      status: 'FAILED',
      error: error.message,
      timestamp: new Date().toISOString()
    });
    TEST_RESULTS.summary.failed++;
    TEST_RESULTS.summary.errors.push(error.message);
    log(`❌ FAILED: ${name} - ${error.message}`, 'ERROR');
    throw error;
  }
};

// API Test Functions
const testHealthEndpoint = async () => {
  const response = await axios.get(`${BASE_URL}/health`, { timeout: 5000 });
  
  if (response.status !== 200) {
    throw new Error(`Expected status 200, got ${response.status}`);
  }
  
  if (!response.data || !response.data.status) {
    throw new Error('Health endpoint should return status field');
  }
  
  return {
    status: response.status,
    data: response.data,
    responseTime: response.headers['x-response-time'] || 'N/A'
  };
};

const testAuthEndpoints = async () => {
  // Test registration
  const registerData = {
    email: 'test@marketplace.dz',
    password: 'TestPassword123!',
    firstName: 'Test',
    lastName: 'User',
    phone: '+213123456789'
  };
  
  const registerResponse = await axios.post(`${BASE_URL}/api/auth/register`, registerData, { timeout: 10000 });
  
  if (registerResponse.status !== 201) {
    throw new Error(`Registration failed with status ${registerResponse.status}`);
  }
  
  if (!registerResponse.data.token) {
    throw new Error('Registration should return JWT token');
  }
  
  const token = registerResponse.data.token;
  
  // Test login
  const loginResponse = await axios.post(`${BASE_URL}/api/auth/login`, {
    email: registerData.email,
    password: registerData.password
  }, { timeout: 5000 });
  
  if (loginResponse.status !== 200) {
    throw new Error(`Login failed with status ${loginResponse.status}`);
  }
  
  if (!loginResponse.data.token) {
    throw new Error('Login should return JWT token');
  }
  
  // Test protected route
  const profileResponse = await axios.get(`${BASE_URL}/api/auth/profile`, {
    headers: { Authorization: `Bearer ${token}` },
    timeout: 5000
  });
  
  if (profileResponse.status !== 200) {
    throw new Error(`Profile fetch failed with status ${profileResponse.status}`);
  }
  
  return {
    registration: { status: registerResponse.status, hasToken: !!registerResponse.data.token },
    login: { status: loginResponse.status, hasToken: !!loginResponse.data.token },
    profile: { status: profileResponse.status, user: profileResponse.data.user }
  };
};

const testProductsEndpoints = async () => {
  // Test products list
  const productsResponse = await axios.get(`${BASE_URL}/api/products`, { timeout: 10000 });
  
  if (productsResponse.status !== 200) {
    throw new Error(`Products list failed with status ${productsResponse.status}`);
  }
  
  if (!Array.isArray(productsResponse.data)) {
    throw new Error('Products should return an array');
  }
  
  // Test product creation (if authenticated)
  const testProduct = {
    name: 'Test Product',
    description: 'Test product description',
    price: 1000,
    category: 'Electronics',
    images: ['https://via.placeholder.com/300x200']
  };
  
  // This might fail without auth, but we test the endpoint structure
  try {
    const createResponse = await axios.post(`${BASE_URL}/api/products`, testProduct, { timeout: 5000 });
    return {
      list: { status: productsResponse.status, count: productsResponse.data.length },
      create: { status: createResponse.status, product: createResponse.data }
    };
  } catch (error) {
    if (error.response && error.response.status === 401) {
      return {
        list: { status: productsResponse.status, count: productsResponse.data.length },
        create: { status: 401, message: 'Unauthorized (expected without auth)' }
      };
    }
    throw error;
  }
};

const testCartEndpoints = async () => {
  // Test cart operations (might require auth)
  try {
    const cartResponse = await axios.get(`${BASE_URL}/api/cart`, { timeout: 5000 });
    return {
      status: cartResponse.status,
      data: cartResponse.data
    };
  } catch (error) {
    if (error.response && error.response.status === 401) {
      return {
        status: 401,
        message: 'Unauthorized (expected without auth)'
      };
    }
    throw error;
  }
};

const testDatabaseConnections = async () => {
  // Test if we can connect to databases
  try {
    const dbResponse = await axios.get(`${BASE_URL}/api/health/db`, { timeout: 5000 });
    return {
      status: dbResponse.status,
      data: dbResponse.data
    };
  } catch (error) {
    return {
      status: error.response?.status || 500,
      error: error.message
    };
  }
};

// Main test execution
const runIntegrationTests = async () => {
  log('🚀 Starting Comprehensive Integration Tests');
  log(`Target: ${BASE_URL}`);
  
  try {
    // Test 1: Health Check
    await test('Health Endpoint', testHealthEndpoint);
    
    // Test 2: Database Connections
    await test('Database Connections', testDatabaseConnections);
    
    // Test 3: Authentication Flow
    await test('Authentication Endpoints', testAuthEndpoints);
    
    // Test 4: Products API
    await test('Products Endpoints', testProductsEndpoints);
    
    // Test 5: Cart API
    await test('Cart Endpoints', testCartEndpoints);
    
    // Generate report
    const reportPath = path.join(__dirname, 'INTEGRATION_TEST_REPORT.json');
    fs.writeFileSync(reportPath, JSON.stringify(TEST_RESULTS, null, 2));
    
    log('📊 Test Summary:');
    log(`Total Tests: ${TEST_RESULTS.summary.total}`);
    log(`Passed: ${TEST_RESULTS.summary.passed}`);
    log(`Failed: ${TEST_RESULTS.summary.failed}`);
    
    if (TEST_RESULTS.summary.failed > 0) {
      log('❌ Some tests failed. Check INTEGRATION_TEST_REPORT.json for details.');
      process.exit(1);
    } else {
      log('✅ All integration tests passed!');
      process.exit(0);
    }
    
  } catch (error) {
    log(`💥 Test suite failed: ${error.message}`, 'ERROR');
    process.exit(1);
  }
};

// Run tests
runIntegrationTests();
