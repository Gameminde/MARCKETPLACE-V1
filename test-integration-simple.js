#!/usr/bin/env node

/**
 * 🎯 TEST D'INTÉGRATION SIMPLIFIÉ - JOUR 3
 * Marketplace Algeria - Tests fonctionnels
 */

const axios = require('axios');

const API_BASE = 'http://localhost:3001';

async function runSimpleTests() {
  console.log('🚀 Starting Simple Integration Tests');
  
  const results = {
    backend: false,
    products: false,
    performance: []
  };
  
  try {
    // Test 1: Backend Health
    console.log('🧪 Testing Backend Health...');
    const start1 = Date.now();
    const healthResp = await axios.get(`${API_BASE}/health`);
    const time1 = Date.now() - start1;
    
    if (healthResp.status === 200) {
      console.log(`✅ Backend Health: OK (${time1}ms)`);
      results.backend = true;
      results.performance.push({ test: 'Health', time: time1 });
    }
    
    // Test 2: Products API
    console.log('🧪 Testing Products API...');
    const start2 = Date.now();
    const productsResp = await axios.get(`${API_BASE}/api/v1/products`);
    const time2 = Date.now() - start2;
    
    if (productsResp.status === 200 && productsResp.data.success) {
      console.log(`✅ Products API: OK (${time2}ms) - ${productsResp.data.data.length} products`);
      results.products = true;
      results.performance.push({ test: 'Products', time: time2 });
    }
    
    // Test 3: Cart API (sans auth - doit retourner 401)
    console.log('🧪 Testing Cart API (no auth)...');
    const start3 = Date.now();
    try {
      const cartResp = await axios.get(`${API_BASE}/api/v1/cart`);
      const time3 = Date.now() - start3;
      console.log(`⚠️ Cart API: ${cartResp.status} (${time3}ms) - Expected 401`);
    } catch (error) {
      const time3 = Date.now() - start3;
      if (error.response && error.response.status === 401) {
        console.log(`✅ Cart API: 401 Unauthorized (${time3}ms) - Correct behavior`);
        results.performance.push({ test: 'Cart (401)', time: time3 });
      } else {
        console.log(`❌ Cart API: Unexpected error (${time3}ms)`);
      }
    }
    
    // Calcul des métriques
    const avgTime = results.performance.reduce((sum, p) => sum + p.time, 0) / results.performance.length;
    const maxTime = Math.max(...results.performance.map(p => p.time));
    const minTime = Math.min(...results.performance.map(p => p.time));
    
    console.log('\n📊 Performance Summary:');
    console.log(`⚡ Average Response Time: ${avgTime.toFixed(2)}ms`);
    console.log(`🐌 Slowest: ${maxTime}ms`);
    console.log(`🚀 Fastest: ${minTime}ms`);
    
    console.log('\n🎯 Integration Status:');
    console.log(`Backend: ${results.backend ? '✅' : '❌'}`);
    console.log(`Products: ${results.products ? '✅' : '❌'}`);
    console.log(`Performance: ${avgTime < 200 ? '✅' : '⚠️'} (${avgTime.toFixed(2)}ms)`);
    
    if (results.backend && results.products && avgTime < 200) {
      console.log('\n🎉 Integration tests PASSED! Ready for Phase 2.');
      return true;
    } else {
      console.log('\n⚠️ Some tests failed. Review implementation.');
      return false;
    }
    
  } catch (error) {
    console.error('💥 Test failed:', error.message);
    return false;
  }
}

if (require.main === module) {
  runSimpleTests()
    .then(success => process.exit(success ? 0 : 1))
    .catch(error => {
      console.error('💥 Tests crashed:', error);
      process.exit(1);
    });
}

module.exports = { runSimpleTests };
