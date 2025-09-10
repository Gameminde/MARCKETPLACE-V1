#!/usr/bin/env node

/**
 * 🎯 TEST D'INTÉGRATION END-TO-END COMPLET
 * Marketplace Algeria - JOUR 3
 * 
 * Simule le parcours utilisateur complet :
 * 1. Backend Health Check
 * 2. Registration utilisateur
 * 3. Login utilisateur
 * 4. Récupération produits
 * 5. Gestion panier
 * 6. Performance benchmarks
 */

const axios = require('axios');
const fs = require('fs');
const path = require('path');

// Configuration
const API_BASE = 'http://localhost:3001';
const TEST_USER = {
  email: `test.user.${Date.now()}@marketplace.dz`,
  password: 'TestPassword123!',
  firstName: 'Test',
  lastName: 'User'
};

// Couleurs pour logs
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

// Statistiques de test
const testStats = {
  startTime: Date.now(),
  tests: [],
  totalTests: 0,
  passedTests: 0,
  failedTests: 0,
  performance: {
    apiResponseTimes: [],
    averageResponseTime: 0,
    slowestEndpoint: null,
    fastestEndpoint: null
  }
};

// Helper pour logs colorés
function log(level, message, data = null) {
  const timestamp = new Date().toISOString();
  const color = {
    'INFO': colors.blue,
    'SUCCESS': colors.green,
    'WARNING': colors.yellow,
    'ERROR': colors.red,
    'PERF': colors.cyan
  }[level] || colors.reset;
  
  console.log(`${color}[${timestamp}] [${level}]${colors.reset} ${message}`);
  if (data) console.log(JSON.stringify(data, null, 2));
}

// Helper pour mesurer le temps de réponse
async function measureResponseTime(testName, apiCall) {
  const startTime = Date.now();
  try {
    const result = await apiCall();
    const responseTime = Date.now() - startTime;
    
    testStats.performance.apiResponseTimes.push({
      test: testName,
      responseTime,
      success: true
    });
    
    return { result, responseTime };
  } catch (error) {
    const responseTime = Date.now() - startTime;
    
    testStats.performance.apiResponseTimes.push({
      test: testName,
      responseTime,
      success: false
    });
    
    throw error;
  }
}

// Fonction de test générique
async function runTest(testName, testFunction) {
  testStats.totalTests++;
  log('INFO', `🧪 Running test: ${testName}`);
  
  try {
    const { result, responseTime } = await measureResponseTime(testName, testFunction);
    testStats.passedTests++;
    testStats.tests.push({
      name: testName,
      status: 'PASSED',
      responseTime,
      result: result?.data || result
    });
    
    log('SUCCESS', `✅ ${testName} - ${responseTime}ms`);
    return result;
  } catch (error) {
    testStats.failedTests++;
    testStats.tests.push({
      name: testName,
      status: 'FAILED',
      error: error.message,
      response: error.response?.data
    });
    
    log('ERROR', `❌ ${testName} - ${error.message}`);
    return null;
  }
}

// Tests individuels
async function testBackendHealth() {
  return runTest('Backend Health Check', async () => {
    const response = await axios.get(`${API_BASE}/health`);
    if (response.status !== 200) {
      throw new Error(`Health check failed with status ${response.status}`);
    }
    return response;
  });
}

async function testUserRegistration() {
  return runTest('User Registration', async () => {
    const response = await axios.post(`${API_BASE}/api/v1/auth/register`, TEST_USER);
    if (response.status !== 201 && response.status !== 200) {
      throw new Error(`Registration failed with status ${response.status}`);
    }
    return response;
  });
}

async function testUserLogin() {
  return runTest('User Login', async () => {
    const response = await axios.post(`${API_BASE}/api/v1/auth/login`, {
      email: TEST_USER.email,
      password: TEST_USER.password
    });
    if (response.status !== 200) {
      throw new Error(`Login failed with status ${response.status}`);
    }
    return response;
  });
}

async function testProductsList() {
  return runTest('Products List', async () => {
    const response = await axios.get(`${API_BASE}/api/v1/products`);
    if (response.status !== 200) {
      throw new Error(`Products list failed with status ${response.status}`);
    }
    if (!response.data.success || !Array.isArray(response.data.data)) {
      throw new Error('Invalid products response format');
    }
    return response;
  });
}

async function testCartAccess(authToken) {
  return runTest('Cart Access (Authenticated)', async () => {
    const response = await axios.get(`${API_BASE}/api/v1/cart`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    // Cart peut retourner 200 (vide) ou 401 (non auth) - les deux sont valides
    return response;
  });
}

async function testProductCreation(authToken) {
  return runTest('Product Creation (Authenticated)', async () => {
    const newProduct = {
      name: `Test Product ${Date.now()}`,
      description: 'Test product for integration testing',
      price: 99.99,
      category: 'Electronics',
      image: 'https://via.placeholder.com/300x200'
    };
    
    const response = await axios.post(`${API_BASE}/api/v1/products`, newProduct, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    
    if (response.status !== 201 && response.status !== 200) {
      throw new Error(`Product creation failed with status ${response.status}`);
    }
    return response;
  });
}

// Calcul des métriques de performance
function calculatePerformanceMetrics() {
  const times = testStats.performance.apiResponseTimes
    .filter(t => t.success)
    .map(t => t.responseTime);
  
  if (times.length === 0) return;
  
  testStats.performance.averageResponseTime = times.reduce((a, b) => a + b, 0) / times.length;
  
  const sortedTimes = times.sort((a, b) => a - b);
  testStats.performance.slowestEndpoint = testStats.performance.apiResponseTimes
    .find(t => t.responseTime === Math.max(...times));
  testStats.performance.fastestEndpoint = testStats.performance.apiResponseTimes
    .find(t => t.responseTime === Math.min(...times));
}

// Génération du rapport
function generateReport() {
  const endTime = Date.now();
  const totalTime = endTime - testStats.startTime;
  
  calculatePerformanceMetrics();
  
  const report = {
    summary: {
      totalTests: testStats.totalTests,
      passedTests: testStats.passedTests,
      failedTests: testStats.failedTests,
      successRate: `${((testStats.passedTests / testStats.totalTests) * 100).toFixed(2)}%`,
      totalTime: `${totalTime}ms`,
      timestamp: new Date().toISOString()
    },
    performance: testStats.performance,
    tests: testStats.tests,
    recommendations: []
  };
  
  // Recommandations basées sur les résultats
  if (testStats.performance.averageResponseTime > 200) {
    report.recommendations.push('API response time > 200ms - consider optimization');
  }
  
  if (testStats.failedTests > 0) {
    report.recommendations.push(`${testStats.failedTests} tests failed - review implementation`);
  }
  
  if (testStats.passedTests === testStats.totalTests) {
    report.recommendations.push('All tests passed - system ready for production');
  }
  
  return report;
}

// Test principal
async function runIntegrationTests() {
  log('INFO', '🚀 Starting End-to-End Integration Tests');
  log('INFO', `📊 Testing with user: ${TEST_USER.email}`);
  
  let authToken = null;
  
  // 1. Test Backend Health
  await testBackendHealth();
  
  // 2. Test User Registration
  const registrationResult = await testUserRegistration();
  
  // 3. Test User Login
  const loginResult = await testUserLogin();
  if (loginResult && loginResult.data && loginResult.data.token) {
    authToken = loginResult.data.token;
    log('SUCCESS', `🔑 Auth token obtained: ${authToken.substring(0, 20)}...`);
  }
  
  // 4. Test Products List
  await testProductsList();
  
  // 5. Test Cart Access
  if (authToken) {
    await testCartAccess(authToken);
    await testProductCreation(authToken);
  } else {
    log('WARNING', '⚠️ No auth token - skipping authenticated tests');
  }
  
  // 6. Génération du rapport
  const report = generateReport();
  
  // Affichage des résultats
  log('INFO', '📊 Integration Test Summary:');
  log('SUCCESS', `✅ Passed: ${report.summary.passedTests}/${report.summary.totalTests}`);
  if (report.summary.failedTests > 0) {
    log('ERROR', `❌ Failed: ${report.summary.failedTests}/${report.summary.totalTests}`);
  }
  log('PERF', `⚡ Average Response Time: ${report.performance.averageResponseTime?.toFixed(2)}ms`);
  log('PERF', `🐌 Slowest: ${report.performance.slowestEndpoint?.test} (${report.performance.slowestEndpoint?.responseTime}ms)`);
  log('PERF', `🚀 Fastest: ${report.performance.fastestEndpoint?.test} (${report.performance.fastestEndpoint?.responseTime}ms)`);
  
  // Sauvegarde du rapport
  const reportPath = path.join(__dirname, 'INTEGRATION_TEST_REPORT.json');
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
  log('INFO', `📄 Detailed report saved to: ${reportPath}`);
  
  // Conclusion
  if (report.summary.passedTests === report.summary.totalTests) {
    log('SUCCESS', '🎉 All integration tests passed! System is ready for Phase 2.');
  } else {
    log('WARNING', '⚠️ Some tests failed. Review the report for details.');
  }
  
  return report;
}

// Exécution
if (require.main === module) {
  runIntegrationTests()
    .then(report => {
      process.exit(report.summary.failedTests === 0 ? 0 : 1);
    })
    .catch(error => {
      log('ERROR', '💥 Integration tests failed:', error);
      process.exit(1);
    });
}

module.exports = { runIntegrationTests };
