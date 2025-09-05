const structuredLogger = require('./structured-logger.service');
const redisService = require('./redis.service');
const databaseService = require('./database.service');

class SearchService {
  constructor() {
    this.cachePrefix = 'search:';
    this.cacheExpiry = 5 * 60; // 5 minutes for search results
    this.suggestionsCacheExpiry = 60 * 60; // 1 hour for suggestions
    this.trendingCacheExpiry = 30 * 60; // 30 minutes for trending
    
    this.searchMetrics = {
      totalSearches: 0,
      averageResponseTime: 0,
      popularQueries: new Map(),
      categoryDistribution: new Map()
    };
  }

  /**
   * Advanced search with PostgreSQL full-text search
   * Target: <500ms for 10K+ products
   */
  async searchProducts(query, options = {}) {
    const startTime = Date.now();
    const searchId = this.generateSearchId();
    
    try {
      // Normalize and validate search parameters
      const searchParams = this.normalizeSearchParams(query, options);
      const cacheKey = this.generateCacheKey(searchParams);
      
      // Check cache first
      const cachedResults = await this.getCachedResults(cacheKey);
      if (cachedResults) {
        structuredLogger.logInfo('SEARCH_CACHE_HIT', {
          searchId,
          query: searchParams.query,
          cacheKey
        });
        return cachedResults;
      }

      // Build PostgreSQL full-text search query
      const searchQuery = this.buildSearchQuery(searchParams);
      
      // Execute search with performance monitoring
      const results = await this.executeSearch(searchQuery, searchParams);
      
      // Post-process results
      const processedResults = await this.postProcessResults(results, searchParams);
      
      const responseTime = Date.now() - startTime;
      
      // Cache results
      await this.cacheResults(cacheKey, processedResults);
      
      // Update metrics and analytics
      this.updateSearchMetrics(searchParams.query, responseTime, processedResults.total);
      
      // Log search analytics
      structuredLogger.logInfo('SEARCH_EXECUTED', {
        searchId,
        query: searchParams.query,
        responseTime,
        resultCount: processedResults.total,
        filters: searchParams.filters,
        sort: searchParams.sort
      });

      return {
        ...processedResults,
        searchId,
        responseTime,
        cached: false
      };

    } catch (error) {
      const responseTime = Date.now() - startTime;
      
      structuredLogger.logError('SEARCH_ERROR', {
        searchId,
        query,
        error: error.message,
        responseTime
      });

      // Return fallback results
      return this.getFallbackResults(query, options, error, responseTime);
    }
  }

  /**
   * Get intelligent auto-complete suggestions
   */
  async getAutocompleteSuggestions(query, limit = 10) {
    const startTime = Date.now();
    
    try {
      if (!query || query.length < 2) {
        return { suggestions: [], responseTime: Date.now() - startTime };
      }

      const cacheKey = `${this.cachePrefix}autocomplete:${query.toLowerCase()}`;
      const cached = await redisService.get(cacheKey);
      
      if (cached) {
        return JSON.parse(cached);
      }

      // Generate suggestions from multiple sources
      const [
        productSuggestions,
        categorySuggestions,
        brandSuggestions,
        trendingSuggestions
      ] = await Promise.all([
        this.getProductSuggestions(query, limit),
        this.getCategorySuggestions(query, limit),
        this.getBrandSuggestions(query, limit),
        this.getTrendingSuggestions(query, limit)
      ]);

      // Combine and rank suggestions
      const allSuggestions = [
        ...productSuggestions.map(s => ({ ...s, type: 'product' })),
        ...categorySuggestions.map(s => ({ ...s, type: 'category' })),
        ...brandSuggestions.map(s => ({ ...s, type: 'brand' })),
        ...trendingSuggestions.map(s => ({ ...s, type: 'trending' }))
      ];

      // Rank by relevance and popularity
      const rankedSuggestions = this.rankSuggestions(allSuggestions, query)
        .slice(0, limit);

      const result = {
        suggestions: rankedSuggestions,
        responseTime: Date.now() - startTime,
        query
      };

      // Cache suggestions
      await redisService.setex(cacheKey, this.suggestionsCacheExpiry, JSON.stringify(result));

      return result;

    } catch (error) {
      structuredLogger.logError('AUTOCOMPLETE_ERROR', {
        query,
        error: error.message
      });

      return {
        suggestions: [],
        responseTime: Date.now() - startTime,
        error: error.message
      };
    }
  }

  /**
   * Get trending searches in real-time
   */
  async getTrendingSearches(limit = 10, timeframe = '24h') {
    try {
      const cacheKey = `${this.cachePrefix}trending:${timeframe}`;
      const cached = await redisService.get(cacheKey);
      
      if (cached) {
        return JSON.parse(cached);
      }

      // Analyze search patterns from metrics
      const trending = Array.from(this.searchMetrics.popularQueries.entries())
        .sort((a, b) => b[1] - a[1])
        .slice(0, limit)
        .map(([query, count]) => ({
          query,
          searchCount: count,
          trend: this.calculateTrend(query),
          category: this.inferCategory(query)
        }));

      const result = {
        trending,
        timeframe,
        generatedAt: new Date().toISOString()
      };

      // Cache trending results
      await redisService.setex(cacheKey, this.trendingCacheExpiry, JSON.stringify(result));

      return result;

    } catch (error) {
      structuredLogger.logError('TRENDING_SEARCHES_ERROR', {
        error: error.message
      });

      return {
        trending: [],
        error: error.message
      };
    }
  }

  /**
   * Advanced filters with faceted search
   */
  async getSearchFilters(query, currentFilters = {}) {
    try {
      const cacheKey = `${this.cachePrefix}filters:${this.hashObject({ query, currentFilters })}`;
      const cached = await redisService.get(cacheKey);
      
      if (cached) {
        return JSON.parse(cached);
      }

      // Build base query for filter aggregation
      const baseQuery = this.buildSearchQuery({ query, filters: currentFilters });
      
      // Get filter aggregations
      const filters = await this.getFilterAggregations(baseQuery);
      
      const result = {
        filters,
        query,
        currentFilters
      };

      // Cache filters
      await redisService.setex(cacheKey, this.cacheExpiry, JSON.stringify(result));

      return result;

    } catch (error) {
      structuredLogger.logError('SEARCH_FILTERS_ERROR', {
        query,
        error: error.message
      });

      return {
        filters: this.getDefaultFilters(),
        error: error.message
      };
    }
  }

  /**
   * Search analytics and insights
   */
  async getSearchAnalytics(timeframe = '7d') {
    try {
      return {
        totalSearches: this.searchMetrics.totalSearches,
        averageResponseTime: this.searchMetrics.averageResponseTime,
        popularQueries: Array.from(this.searchMetrics.popularQueries.entries())
          .sort((a, b) => b[1] - a[1])
          .slice(0, 20),
        categoryDistribution: Array.from(this.searchMetrics.categoryDistribution.entries()),
        noResultsQueries: await this.getNoResultsQueries(),
        searchTrends: await this.getSearchTrends(timeframe),
        performanceMetrics: {
          cacheHitRate: await this.calculateCacheHitRate(),
          averageResultCount: await this.getAverageResultCount()
        }
      };
    } catch (error) {
      structuredLogger.logError('SEARCH_ANALYTICS_ERROR', {
        error: error.message
      });
      return { error: error.message };
    }
  }

  // ========================================
  // CORE SEARCH IMPLEMENTATION
  // ========================================

  /**
   * Normalize search parameters
   */
  normalizeSearchParams(query, options) {
    return {
      query: this.sanitizeQuery(query),
      filters: options.filters || {},
      sort: options.sort || 'relevance',
      page: Math.max(1, parseInt(options.page) || 1),
      limit: Math.min(100, Math.max(1, parseInt(options.limit) || 20)),
      includeOutOfStock: options.includeOutOfStock || false,
      priceRange: options.priceRange || null,
      categories: options.categories || [],
      brands: options.brands || [],
      rating: options.rating || null
    };
  }

  /**
   * Build PostgreSQL full-text search query
   */
  buildSearchQuery(params) {
    let query = `
      SELECT 
        p.*,
        s.name as shop_name,
        s.rating as shop_rating,
        ts_rank(
          to_tsvector('french', p.title || ' ' || p.description || ' ' || p.tags),
          plainto_tsquery('french', $1)
        ) as relevance_score,
        (
          CASE 
            WHEN p.title ILIKE $2 THEN 10
            WHEN p.title ILIKE $3 THEN 5
            ELSE 0
          END +
          CASE 
            WHEN p.description ILIKE $2 THEN 3
            WHEN p.description ILIKE $3 THEN 1
            ELSE 0
          END
        ) as exact_match_score
      FROM products p
      LEFT JOIN shops s ON p.shop_id = s.id
      WHERE 1=1
    `;

    const queryParams = [
      params.query,
      `%${params.query}%`,
      `%${params.query.split(' ').join('%')}%`
    ];
    let paramIndex = 4;

    // Add full-text search condition
    if (params.query) {
      query += ` AND to_tsvector('french', p.title || ' ' || p.description || ' ' || p.tags) @@ plainto_tsquery('french', $1)`;
    }

    // Add filters
    if (params.categories.length > 0) {
      query += ` AND p.category = ANY($${paramIndex})`;
      queryParams.push(params.categories);
      paramIndex++;
    }

    if (params.brands.length > 0) {
      query += ` AND p.brand = ANY($${paramIndex})`;
      queryParams.push(params.brands);
      paramIndex++;
    }

    if (params.priceRange) {
      query += ` AND p.price BETWEEN $${paramIndex} AND $${paramIndex + 1}`;
      queryParams.push(params.priceRange.min, params.priceRange.max);
      paramIndex += 2;
    }

    if (params.rating) {
      query += ` AND p.rating >= $${paramIndex}`;
      queryParams.push(params.rating);
      paramIndex++;
    }

    if (!params.includeOutOfStock) {
      query += ` AND p.stock > 0`;
    }

    // Add sorting
    switch (params.sort) {
      case 'price_asc':
        query += ` ORDER BY p.price ASC`;
        break;
      case 'price_desc':
        query += ` ORDER BY p.price DESC`;
        break;
      case 'rating':
        query += ` ORDER BY p.rating DESC, relevance_score DESC`;
        break;
      case 'newest':
        query += ` ORDER BY p.created_at DESC`;
        break;
      case 'popularity':
        query += ` ORDER BY p.views DESC, p.sales DESC`;
        break;
      default: // relevance
        query += ` ORDER BY (relevance_score + exact_match_score) DESC, p.rating DESC`;
    }

    // Add pagination
    query += ` LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    queryParams.push(params.limit, (params.page - 1) * params.limit);

    return { query, params: queryParams };
  }

  /**
   * Execute search query with performance monitoring
   */
  async executeSearch(searchQuery, params) {
    const startTime = Date.now();
    
    try {
      // For development, return mock results
      // In production, this would execute the actual PostgreSQL query
      const mockResults = await this.getMockSearchResults(params);
      
      const queryTime = Date.now() - startTime;
      
      structuredLogger.logInfo('SEARCH_QUERY_EXECUTED', {
        queryTime,
        resultCount: mockResults.length,
        query: params.query
      });

      return mockResults;

    } catch (error) {
      structuredLogger.logError('SEARCH_QUERY_ERROR', {
        error: error.message,
        query: params.query
      });
      throw error;
    }
  }

  /**
   * Post-process search results
   */
  async postProcessResults(results, params) {
    // Add search highlighting
    const highlightedResults = results.map(result => ({
      ...result,
      highlighted: {
        title: this.highlightText(result.title, params.query),
        description: this.highlightText(result.description, params.query)
      }
    }));

    // Add personalization scores (mock)
    const personalizedResults = highlightedResults.map(result => ({
      ...result,
      personalizationScore: Math.random() * 0.2 // Mock personalization
    }));

    return {
      results: personalizedResults,
      total: personalizedResults.length,
      page: params.page,
      limit: params.limit,
      hasMore: personalizedResults.length === params.limit,
      facets: await this.generateFacets(personalizedResults),
      suggestions: params.query ? await this.getQuerySuggestions(params.query) : []
    };
  }

  // ========================================
  // SUGGESTION SYSTEMS
  // ========================================

  async getProductSuggestions(query, limit) {
    // Mock product suggestions
    const products = [
      'iPhone 14 Pro',
      'Samsung Galaxy S23',
      'MacBook Pro M2',
      'iPad Air',
      'AirPods Pro',
      'PlayStation 5',
      'Nintendo Switch',
      'Tesla Model 3'
    ];

    return products
      .filter(product => product.toLowerCase().includes(query.toLowerCase()))
      .slice(0, limit)
      .map(product => ({
        text: product,
        score: Math.random(),
        category: 'Electronics'
      }));
  }

  async getCategorySuggestions(query, limit) {
    const categories = [
      'Electronics',
      'Fashion',
      'Home & Garden',
      'Sports',
      'Books',
      'Toys',
      'Beauty',
      'Automotive'
    ];

    return categories
      .filter(cat => cat.toLowerCase().includes(query.toLowerCase()))
      .slice(0, limit)
      .map(category => ({
        text: category,
        score: Math.random(),
        productCount: Math.floor(Math.random() * 1000)
      }));
  }

  async getBrandSuggestions(query, limit) {
    const brands = [
      'Apple',
      'Samsung',
      'Nike',
      'Adidas',
      'Sony',
      'Microsoft',
      'Google',
      'Amazon'
    ];

    return brands
      .filter(brand => brand.toLowerCase().includes(query.toLowerCase()))
      .slice(0, limit)
      .map(brand => ({
        text: brand,
        score: Math.random(),
        productCount: Math.floor(Math.random() * 500)
      }));
  }

  async getTrendingSuggestions(query, limit) {
    const trending = [
      'Black Friday deals',
      'Christmas gifts',
      'New arrivals',
      'Best sellers',
      'Sale items'
    ];

    return trending
      .filter(trend => trend.toLowerCase().includes(query.toLowerCase()))
      .slice(0, limit)
      .map(trend => ({
        text: trend,
        score: Math.random(),
        trendScore: Math.random()
      }));
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  sanitizeQuery(query) {
    if (!query) return '';
    return query.trim().replace(/[<>]/g, '').substring(0, 200);
  }

  generateSearchId() {
    return `search_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  generateCacheKey(params) {
    return `${this.cachePrefix}${this.hashObject(params)}`;
  }

  hashObject(obj) {
    const crypto = require('crypto');
    return crypto.createHash('md5').update(JSON.stringify(obj)).digest('hex');
  }

  async getCachedResults(cacheKey) {
    try {
      const cached = await redisService.get(cacheKey);
      return cached ? JSON.parse(cached) : null;
    } catch (error) {
      return null;
    }
  }

  async cacheResults(cacheKey, results) {
    try {
      await redisService.setex(cacheKey, this.cacheExpiry, JSON.stringify({
        ...results,
        cached: true,
        cachedAt: new Date().toISOString()
      }));
    } catch (error) {
      structuredLogger.logError('SEARCH_CACHE_ERROR', { error: error.message });
    }
  }

  updateSearchMetrics(query, responseTime, resultCount) {
    this.searchMetrics.totalSearches++;
    this.searchMetrics.averageResponseTime = 
      (this.searchMetrics.averageResponseTime * (this.searchMetrics.totalSearches - 1) + responseTime) / 
      this.searchMetrics.totalSearches;

    // Update popular queries
    const currentCount = this.searchMetrics.popularQueries.get(query) || 0;
    this.searchMetrics.popularQueries.set(query, currentCount + 1);

    // Infer and update category distribution
    const category = this.inferCategory(query);
    const categoryCount = this.searchMetrics.categoryDistribution.get(category) || 0;
    this.searchMetrics.categoryDistribution.set(category, categoryCount + 1);
  }

  inferCategory(query) {
    const categoryKeywords = {
      'electronics': ['phone', 'laptop', 'computer', 'tablet', 'tv', 'camera'],
      'fashion': ['shirt', 'dress', 'shoes', 'jacket', 'pants', 'clothing'],
      'home': ['furniture', 'kitchen', 'bedroom', 'living', 'decor'],
      'sports': ['fitness', 'gym', 'running', 'sports', 'exercise'],
      'books': ['book', 'novel', 'reading', 'literature', 'author'],
      'beauty': ['makeup', 'skincare', 'cosmetics', 'beauty', 'perfume']
    };

    const lowerQuery = query.toLowerCase();
    for (const [category, keywords] of Object.entries(categoryKeywords)) {
      if (keywords.some(keyword => lowerQuery.includes(keyword))) {
        return category;
      }
    }
    return 'general';
  }

  calculateTrend(query) {
    // Mock trend calculation
    return Math.random() > 0.5 ? 'up' : 'stable';
  }

  rankSuggestions(suggestions, query) {
    return suggestions.sort((a, b) => {
      // Prioritize exact matches
      const aExact = a.text.toLowerCase().startsWith(query.toLowerCase()) ? 1 : 0;
      const bExact = b.text.toLowerCase().startsWith(query.toLowerCase()) ? 1 : 0;
      
      if (aExact !== bExact) return bExact - aExact;
      
      // Then by score
      return (b.score || 0) - (a.score || 0);
    });
  }

  highlightText(text, query) {
    if (!text || !query) return text;
    
    const regex = new RegExp(`(${query})`, 'gi');
    return text.replace(regex, '<mark>$1</mark>');
  }

  async generateFacets(results) {
    // Generate facets from results
    const facets = {
      categories: {},
      brands: {},
      priceRanges: {
        '0-25': 0,
        '25-50': 0,
        '50-100': 0,
        '100+': 0
      },
      ratings: {
        '4+': 0,
        '3+': 0,
        '2+': 0,
        '1+': 0
      }
    };

    results.forEach(result => {
      // Category facets
      if (result.category) {
        facets.categories[result.category] = (facets.categories[result.category] || 0) + 1;
      }

      // Brand facets
      if (result.brand) {
        facets.brands[result.brand] = (facets.brands[result.brand] || 0) + 1;
      }

      // Price range facets
      const price = result.price || 0;
      if (price < 25) facets.priceRanges['0-25']++;
      else if (price < 50) facets.priceRanges['25-50']++;
      else if (price < 100) facets.priceRanges['50-100']++;
      else facets.priceRanges['100+']++;

      // Rating facets
      const rating = result.rating || 0;
      if (rating >= 4) facets.ratings['4+']++;
      if (rating >= 3) facets.ratings['3+']++;
      if (rating >= 2) facets.ratings['2+']++;
      if (rating >= 1) facets.ratings['1+']++;
    });

    return facets;
  }

  async getQuerySuggestions(query) {
    // Mock query suggestions
    return [
      `${query} reviews`,
      `${query} price`,
      `${query} comparison`,
      `best ${query}`,
      `${query} deals`
    ].slice(0, 3);
  }

  async getMockSearchResults(params) {
    // Mock search results for development
    const mockProducts = [
      {
        id: '1',
        title: 'iPhone 14 Pro Max',
        description: 'Latest iPhone with advanced camera system',
        price: 1099,
        category: 'Electronics',
        brand: 'Apple',
        rating: 4.8,
        stock: 50,
        views: 1500,
        sales: 120,
        shop_name: 'Apple Store',
        shop_rating: 4.9,
        created_at: new Date()
      },
      {
        id: '2',
        title: 'Samsung Galaxy S23 Ultra',
        description: 'Premium Android smartphone with S Pen',
        price: 999,
        category: 'Electronics',
        brand: 'Samsung',
        rating: 4.7,
        stock: 30,
        views: 1200,
        sales: 95,
        shop_name: 'Samsung Official',
        shop_rating: 4.8,
        created_at: new Date()
      }
    ];

    // Filter mock results based on query
    return mockProducts.filter(product => 
      !params.query || 
      product.title.toLowerCase().includes(params.query.toLowerCase()) ||
      product.description.toLowerCase().includes(params.query.toLowerCase())
    );
  }

  getFallbackResults(query, options, error, responseTime) {
    return {
      results: [],
      total: 0,
      page: options.page || 1,
      limit: options.limit || 20,
      hasMore: false,
      facets: this.getDefaultFilters(),
      suggestions: [],
      error: error.message,
      responseTime,
      fallback: true
    };
  }

  getDefaultFilters() {
    return {
      categories: {},
      brands: {},
      priceRanges: {},
      ratings: {}
    };
  }

  async getNoResultsQueries() {
    // Mock no results queries
    return [
      { query: 'unicorn phone', count: 5 },
      { query: 'flying car', count: 3 },
      { query: 'time machine', count: 2 }
    ];
  }

  async getSearchTrends(timeframe) {
    // Mock search trends
    return {
      timeframe,
      trends: [
        { date: '2024-12-01', searches: 1500 },
        { date: '2024-12-02', searches: 1650 },
        { date: '2024-12-03', searches: 1800 }
      ]
    };
  }

  async calculateCacheHitRate() {
    return 0.75; // 75% cache hit rate
  }

  async getAverageResultCount() {
    return 25.5;
  }

  getFilterAggregations(baseQuery) {
    // Mock filter aggregations
    return this.getDefaultFilters();
  }
}

module.exports = new SearchService();