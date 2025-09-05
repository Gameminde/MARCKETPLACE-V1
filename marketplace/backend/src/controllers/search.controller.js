const BaseController = require('./BaseController');
const searchService = require('../services/search.service');
const structuredLogger = require('../services/structured-logger.service');
const Joi = require('joi');

class SearchController extends BaseController {
  constructor() {
    super('SEARCH');
  }

  /**
   * Advanced product search with full-text search and filters
   */
  searchProducts = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      q: Joi.string().allow('').max(200).default(''),
      query: Joi.string().allow('').max(200).default(''), // Alternative parameter name
      page: Joi.number().integer().min(1).default(1),
      limit: Joi.number().integer().min(1).max(100).default(20),
      sort: Joi.string().valid(
        'relevance', 'price_asc', 'price_desc', 'rating', 'newest', 'popularity'
      ).default('relevance'),
      categories: Joi.array().items(Joi.string()).default([]),
      brands: Joi.array().items(Joi.string()).default([]),
      minPrice: Joi.number().min(0).optional(),
      maxPrice: Joi.number().min(0).optional(),
      rating: Joi.number().min(1).max(5).optional(),
      includeOutOfStock: Joi.boolean().default(false)
    });

    const validatedData = this.validateRequest(schema, {
      ...req.query,
      ...req.body
    });

    try {
      // Use 'q' or 'query' parameter
      const searchQuery = validatedData.q || validatedData.query;
      
      // Build search options
      const searchOptions = {
        page: validatedData.page,
        limit: validatedData.limit,
        sort: validatedData.sort,
        includeOutOfStock: validatedData.includeOutOfStock,
        filters: {
          categories: validatedData.categories,
          brands: validatedData.brands,
          rating: validatedData.rating
        }
      };

      // Add price range if specified
      if (validatedData.minPrice !== undefined || validatedData.maxPrice !== undefined) {
        searchOptions.priceRange = {
          min: validatedData.minPrice || 0,
          max: validatedData.maxPrice || 999999
        };
      }

      // Execute search
      const results = await searchService.searchProducts(searchQuery, searchOptions);

      structuredLogger.logInfo('SEARCH_REQUEST_SUCCESS', {
        userId: req.user?.sub,
        query: searchQuery,
        resultCount: results.total,
        responseTime: results.responseTime,
        cached: results.cached
      });

      res.json({
        success: true,
        data: results
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Get autocomplete suggestions
   */
  getAutocompleteSuggestions = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      q: Joi.string().required().min(1).max(100),
      limit: Joi.number().integer().min(1).max(20).default(10)
    });

    const validatedData = this.validateRequest(schema, req.query);

    try {
      const suggestions = await searchService.getAutocompleteSuggestions(
        validatedData.q,
        validatedData.limit
      );

      res.json({
        success: true,
        data: suggestions
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Get trending searches
   */
  getTrendingSearches = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      limit: Joi.number().integer().min(1).max(50).default(10),
      timeframe: Joi.string().valid('1h', '24h', '7d', '30d').default('24h')
    });

    const validatedData = this.validateRequest(schema, req.query);

    try {
      const trending = await searchService.getTrendingSearches(
        validatedData.limit,
        validatedData.timeframe
      );

      res.json({
        success: true,
        data: trending
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Get search filters for faceted search
   */
  getSearchFilters = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      q: Joi.string().allow('').max(200).default(''),
      categories: Joi.array().items(Joi.string()).default([]),
      brands: Joi.array().items(Joi.string()).default([]),
      minPrice: Joi.number().min(0).optional(),
      maxPrice: Joi.number().min(0).optional(),
      rating: Joi.number().min(1).max(5).optional()
    });

    const validatedData = this.validateRequest(schema, req.query);

    try {
      const currentFilters = {
        categories: validatedData.categories,
        brands: validatedData.brands,
        rating: validatedData.rating
      };

      if (validatedData.minPrice !== undefined || validatedData.maxPrice !== undefined) {
        currentFilters.priceRange = {
          min: validatedData.minPrice || 0,
          max: validatedData.maxPrice || 999999
        };
      }

      const filters = await searchService.getSearchFilters(validatedData.q, currentFilters);

      res.json({
        success: true,
        data: filters
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Get search analytics (admin only)
   */
  getSearchAnalytics = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      timeframe: Joi.string().valid('1h', '24h', '7d', '30d').default('7d')
    });

    const validatedData = this.validateRequest(schema, req.query);

    try {
      const analytics = await searchService.getSearchAnalytics(validatedData.timeframe);

      structuredLogger.logInfo('SEARCH_ANALYTICS_ACCESSED', {
        userId: req.user?.sub,
        timeframe: validatedData.timeframe
      });

      res.json({
        success: true,
        data: analytics
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Search suggestions based on user behavior
   */
  getPersonalizedSuggestions = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      limit: Joi.number().integer().min(1).max(20).default(10),
      type: Joi.string().valid('recent', 'recommended', 'trending').default('recommended')
    });

    const validatedData = this.validateRequest(schema, req.query);

    try {
      // Mock personalized suggestions for now
      // In production, this would use user behavior data
      const suggestions = {
        recent: [
          { query: 'iPhone 14', timestamp: new Date() },
          { query: 'MacBook Pro', timestamp: new Date() },
          { query: 'AirPods', timestamp: new Date() }
        ],
        recommended: [
          { query: 'Samsung Galaxy S23', score: 0.95, reason: 'Similar to your searches' },
          { query: 'iPad Pro', score: 0.88, reason: 'Popular in Electronics' },
          { query: 'PlayStation 5', score: 0.82, reason: 'Trending now' }
        ],
        trending: await searchService.getTrendingSearches(validatedData.limit)
      };

      res.json({
        success: true,
        data: {
          suggestions: suggestions[validatedData.type],
          type: validatedData.type,
          userId: req.user?.sub
        }
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Voice search endpoint
   */
  voiceSearch = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      audioData: Joi.string().required(), // Base64 encoded audio
      language: Joi.string().valid('fr-FR', 'en-US', 'es-ES').default('fr-FR'),
      format: Joi.string().valid('wav', 'mp3', 'webm').default('webm')
    });

    const validatedData = this.validateRequest(schema, req.body);

    try {
      // Mock voice search implementation
      // In production, this would use Google Speech-to-Text API
      const mockTranscription = this.mockVoiceToText(validatedData.audioData);
      
      // Perform search with transcribed text
      const searchResults = await searchService.searchProducts(mockTranscription, {
        limit: 10,
        sort: 'relevance'
      });

      structuredLogger.logInfo('VOICE_SEARCH_EXECUTED', {
        userId: req.user?.sub,
        transcription: mockTranscription,
        resultCount: searchResults.total,
        language: validatedData.language
      });

      res.json({
        success: true,
        data: {
          transcription: mockTranscription,
          confidence: 0.95, // Mock confidence score
          searchResults,
          language: validatedData.language
        }
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Visual search endpoint (search by image)
   */
  visualSearch = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      imageUrl: Joi.string().uri().optional(),
      imageData: Joi.string().optional(), // Base64 encoded image
      limit: Joi.number().integer().min(1).max(50).default(20)
    }).or('imageUrl', 'imageData');

    const validatedData = this.validateRequest(schema, req.body);

    try {
      // Mock visual search implementation
      // In production, this would use Google Vision API for product search
      const mockImageAnalysis = await this.mockImageToProducts(
        validatedData.imageUrl || validatedData.imageData
      );

      // Search for similar products
      const searchResults = await searchService.searchProducts(
        mockImageAnalysis.detectedObjects.join(' '),
        {
          limit: validatedData.limit,
          sort: 'relevance',
          filters: {
            categories: mockImageAnalysis.suggestedCategories
          }
        }
      );

      structuredLogger.logInfo('VISUAL_SEARCH_EXECUTED', {
        userId: req.user?.sub,
        hasImageUrl: !!validatedData.imageUrl,
        hasImageData: !!validatedData.imageData,
        detectedObjects: mockImageAnalysis.detectedObjects,
        resultCount: searchResults.total
      });

      res.json({
        success: true,
        data: {
          imageAnalysis: mockImageAnalysis,
          searchResults,
          visualSearchId: `vs_${Date.now()}`
        }
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Search history for authenticated users
   */
  getSearchHistory = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      limit: Joi.number().integer().min(1).max(100).default(50),
      page: Joi.number().integer().min(1).default(1)
    });

    const validatedData = this.validateRequest(schema, req.query);

    try {
      // Mock search history
      // In production, this would fetch from user's search history
      const mockHistory = [
        {
          query: 'iPhone 14 Pro',
          timestamp: new Date(Date.now() - 1000 * 60 * 30), // 30 minutes ago
          resultCount: 25,
          clicked: true
        },
        {
          query: 'MacBook Pro M2',
          timestamp: new Date(Date.now() - 1000 * 60 * 60 * 2), // 2 hours ago
          resultCount: 15,
          clicked: false
        },
        {
          query: 'AirPods Pro 2',
          timestamp: new Date(Date.now() - 1000 * 60 * 60 * 24), // 1 day ago
          resultCount: 30,
          clicked: true
        }
      ];

      const startIndex = (validatedData.page - 1) * validatedData.limit;
      const endIndex = startIndex + validatedData.limit;
      const paginatedHistory = mockHistory.slice(startIndex, endIndex);

      res.json({
        success: true,
        data: {
          history: paginatedHistory,
          total: mockHistory.length,
          page: validatedData.page,
          limit: validatedData.limit,
          hasMore: endIndex < mockHistory.length
        }
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Clear search history
   */
  clearSearchHistory = this.asyncHandler(async (req, res) => {
    try {
      // Mock clearing search history
      // In production, this would delete user's search history from database
      
      structuredLogger.logInfo('SEARCH_HISTORY_CLEARED', {
        userId: req.user?.sub
      });

      res.json({
        success: true,
        message: 'Search history cleared successfully'
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  // ========================================
  // MOCK IMPLEMENTATIONS
  // ========================================

  mockVoiceToText(audioData) {
    // Mock voice-to-text conversion
    const mockQueries = [
      'iPhone 14 Pro Max',
      'Samsung Galaxy S23',
      'MacBook Pro M2',
      'PlayStation 5',
      'Nintendo Switch'
    ];
    
    return mockQueries[Math.floor(Math.random() * mockQueries.length)];
  }

  async mockImageToProducts(imageSource) {
    // Mock image analysis for visual search
    const mockObjects = ['phone', 'smartphone', 'device', 'electronics'];
    const mockCategories = ['Electronics', 'Mobile Phones'];
    const mockColors = ['black', 'silver', 'blue'];
    const mockBrands = ['Apple', 'Samsung', 'Google'];

    return {
      detectedObjects: mockObjects.slice(0, 2 + Math.floor(Math.random() * 2)),
      suggestedCategories: mockCategories,
      dominantColors: mockColors.slice(0, 1 + Math.floor(Math.random() * 2)),
      possibleBrands: mockBrands.slice(0, 1 + Math.floor(Math.random() * 2)),
      confidence: 0.85 + Math.random() * 0.1,
      processingTime: 150 + Math.random() * 100
    };
  }
}

module.exports = new SearchController();