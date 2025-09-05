const express = require('express');
const router = express.Router();
const searchController = require('../controllers/search.controller');
const authMiddleware = require('../middleware/auth.middleware');

// Public search endpoints
router.get('/products', searchController.searchProducts);
router.post('/products', searchController.searchProducts); // Support POST for complex queries
router.get('/autocomplete', searchController.getAutocompleteSuggestions);
router.get('/trending', searchController.getTrendingSearches);
router.get('/filters', searchController.getSearchFilters);

// Advanced search features
router.post('/voice', searchController.voiceSearch);
router.post('/visual', searchController.visualSearch);

// Authenticated user features
router.use(authMiddleware);

router.get('/suggestions/personalized', searchController.getPersonalizedSuggestions);
router.get('/history', searchController.getSearchHistory);
router.delete('/history', searchController.clearSearchHistory);

// Admin analytics
router.get('/analytics', authMiddleware.requireRole('admin'), searchController.getSearchAnalytics);

module.exports = router;