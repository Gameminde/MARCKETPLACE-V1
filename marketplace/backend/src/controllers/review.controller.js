const BaseController = require('./BaseController');
const reviewService = require('../services/review.service');
const structuredLogger = require('../services/structured-logger.service');
const Joi = require('joi');

class ReviewController extends BaseController {
  constructor() {
    super('REVIEW');
  }

  /**
   * Create a new review with AI moderation
   */
  createReview = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      productId: Joi.string().required(),
      shopId: Joi.string().required(),
      orderId: Joi.string().optional(),
      rating: Joi.number().integer().min(1).max(5).required(),
      title: Joi.string().min(5).max(200).required(),
      content: Joi.string().min(10).max(5000).required(),
      images: Joi.array().items(Joi.string().uri()).max(10).default([]),
      videos: Joi.array().items(Joi.string().uri()).max(3).default([]),
      pros: Joi.array().items(Joi.string().max(100)).max(5).default([]),
      cons: Joi.array().items(Joi.string().max(100)).max(5).default([])
    });

    const validatedData = this.validateRequest(schema, req.body);

    try {
      const review = await reviewService.createReview(validatedData, req.user.sub);

      structuredLogger.logInfo('REVIEW_CREATED_SUCCESS', {
        userId: req.user.sub,
        reviewId: review.id,
        productId: validatedData.productId,
        rating: validatedData.rating,
        approved: review.moderation.approved
      });

      res.status(201).json({
        success: true,
        data: review,
        message: review.moderation.approved ? 'Review published successfully' : 'Review submitted for moderation'
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Get reviews for a product with filtering and sorting
   */
  getProductReviews = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      productId: Joi.string().required(),
      page: Joi.number().integer().min(1).default(1),
      limit: Joi.number().integer().min(1).max(100).default(20),
      sort: Joi.string().valid('newest', 'oldest', 'rating_high', 'rating_low', 'helpful').default('newest'),
      rating: Joi.number().integer().min(1).max(5).optional(),
      verified: Joi.boolean().optional(),
      withImages: Joi.boolean().optional(),
      withVideos: Joi.boolean().optional()
    });

    const validatedData = this.validateRequest(schema, {
      ...req.params,
      ...req.query
    });

    try {
      const filters = {
        productId: validatedData.productId,
        page: validatedData.page,
        limit: validatedData.limit,
        sort: validatedData.sort
      };

      // Add optional filters
      if (validatedData.rating) filters.rating = validatedData.rating;
      if (validatedData.verified !== undefined) filters.verified = validatedData.verified;
      if (validatedData.withImages) filters.hasImages = true;
      if (validatedData.withVideos) filters.hasVideos = true;

      const reviews = await reviewService.getReviews(filters);

      res.json({
        success: true,
        data: reviews
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Get reviews for a shop
   */
  getShopReviews = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      shopId: Joi.string().required(),
      page: Joi.number().integer().min(1).default(1),
      limit: Joi.number().integer().min(1).max(100).default(20),
      sort: Joi.string().valid('newest', 'oldest', 'rating_high', 'rating_low', 'helpful').default('newest')
    });

    const validatedData = this.validateRequest(schema, {
      ...req.params,
      ...req.query
    });

    try {
      const filters = {
        shopId: validatedData.shopId,
        page: validatedData.page,
        limit: validatedData.limit,
        sort: validatedData.sort
      };

      const reviews = await reviewService.getReviews(filters);

      res.json({
        success: true,
        data: reviews
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Create seller response to a review
   */
  createSellerResponse = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      reviewId: Joi.string().required(),
      content: Joi.string().min(10).max(2000).required()
    });

    const validatedData = this.validateRequest(schema, {
      ...req.params,
      ...req.body
    });

    try {
      const response = await reviewService.createSellerResponse(
        validatedData.reviewId,
        req.user.sub,
        { content: validatedData.content }
      );

      structuredLogger.logInfo('SELLER_RESPONSE_CREATED_SUCCESS', {
        sellerId: req.user.sub,
        reviewId: validatedData.reviewId,
        responseId: response.id,
        aiEnhanced: response.aiEnhanced
      });

      res.status(201).json({
        success: true,
        data: response,
        message: 'Response posted successfully'
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Mark review as helpful or not helpful
   */
  markReviewHelpful = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      reviewId: Joi.string().required(),
      helpful: Joi.boolean().required()
    });

    const validatedData = this.validateRequest(schema, {
      ...req.params,
      ...req.body
    });

    try {
      const result = await reviewService.markReviewHelpful(
        validatedData.reviewId,
        req.user.sub,
        validatedData.helpful
      );

      res.json({
        success: true,
        data: result,
        message: 'Review helpfulness updated'
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Get user's reviews
   */
  getUserReviews = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      page: Joi.number().integer().min(1).default(1),
      limit: Joi.number().integer().min(1).max(100).default(20),
      sort: Joi.string().valid('newest', 'oldest', 'rating_high', 'rating_low').default('newest'),
      status: Joi.string().valid('published', 'pending', 'rejected').optional()
    });

    const validatedData = this.validateRequest(schema, req.query);

    try {
      const filters = {
        userId: req.user.sub,
        page: validatedData.page,
        limit: validatedData.limit,
        sort: validatedData.sort
      };

      if (validatedData.status) {
        filters.status = validatedData.status;
      }

      const reviews = await reviewService.getReviews(filters);

      res.json({
        success: true,
        data: reviews
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Get review analytics (for sellers and admins)
   */
  getReviewAnalytics = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      shopId: Joi.string().optional(),
      productId: Joi.string().optional(),
      timeframe: Joi.string().valid('7d', '30d', '90d', '1y').default('30d')
    });

    const validatedData = this.validateRequest(schema, req.query);

    try {
      // Mock analytics data
      const analytics = {
        totalReviews: 150,
        averageRating: 4.3,
        ratingDistribution: {
          5: 65,
          4: 45,
          3: 25,
          2: 10,
          1: 5
        },
        verifiedReviews: 128,
        verificationRate: 85.3,
        responseRate: 78.5,
        averageResponseTime: 12, // hours
        sentimentAnalysis: {
          positive: 72,
          neutral: 18,
          negative: 10
        },
        topKeywords: [
          { keyword: 'quality', count: 45, sentiment: 'positive' },
          { keyword: 'fast delivery', count: 38, sentiment: 'positive' },
          { keyword: 'good value', count: 32, sentiment: 'positive' },
          { keyword: 'packaging', count: 28, sentiment: 'neutral' },
          { keyword: 'size', count: 22, sentiment: 'negative' }
        ],
        trends: {
          reviewsOverTime: [
            { date: '2024-12-01', count: 12, avgRating: 4.2 },
            { date: '2024-12-02', count: 15, avgRating: 4.4 },
            { date: '2024-12-03', count: 18, avgRating: 4.3 }
          ]
        },
        moderationStats: {
          autoApproved: 142,
          manualReview: 8,
          rejected: 0,
          accuracy: 94.5
        }
      };

      res.json({
        success: true,
        data: analytics
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Report a review for inappropriate content
   */
  reportReview = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      reviewId: Joi.string().required(),
      reason: Joi.string().valid(
        'inappropriate_content',
        'spam',
        'fake_review',
        'personal_information',
        'copyright_violation',
        'other'
      ).required(),
      description: Joi.string().max(500).optional()
    });

    const validatedData = this.validateRequest(schema, {
      ...req.params,
      ...req.body
    });

    try {
      // Mock report handling
      const reportId = `report_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

      structuredLogger.logInfo('REVIEW_REPORTED', {
        reportId,
        reviewId: validatedData.reviewId,
        reporterId: req.user.sub,
        reason: validatedData.reason
      });

      res.json({
        success: true,
        data: {
          reportId,
          status: 'submitted',
          message: 'Report submitted successfully. We will review it within 24 hours.'
        }
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Get review moderation queue (admin only)
   */
  getModerationQueue = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      page: Joi.number().integer().min(1).default(1),
      limit: Joi.number().integer().min(1).max(100).default(20),
      priority: Joi.string().valid('high', 'medium', 'low').optional(),
      category: Joi.string().optional()
    });

    const validatedData = this.validateRequest(schema, req.query);

    try {
      // Mock moderation queue
      const queue = {
        reviews: [
          {
            id: 'review_pending_1',
            productId: 'product_1',
            userId: 'user_1',
            rating: 1,
            content: 'This product is terrible and the seller is a scammer!',
            moderation: {
              score: 0.3,
              issues: ['Potentially inappropriate language detected'],
              priority: 'high'
            },
            createdAt: new Date().toISOString()
          }
        ],
        pagination: {
          page: validatedData.page,
          limit: validatedData.limit,
          total: 1,
          hasMore: false
        },
        stats: {
          totalPending: 1,
          highPriority: 1,
          mediumPriority: 0,
          lowPriority: 0
        }
      };

      res.json({
        success: true,
        data: queue
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Moderate a review (admin only)
   */
  moderateReview = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      reviewId: Joi.string().required(),
      action: Joi.string().valid('approve', 'reject', 'edit').required(),
      reason: Joi.string().max(500).optional(),
      editedContent: Joi.string().max(5000).optional()
    });

    const validatedData = this.validateRequest(schema, {
      ...req.params,
      ...req.body
    });

    try {
      structuredLogger.logInfo('REVIEW_MODERATED', {
        reviewId: validatedData.reviewId,
        moderatorId: req.user.sub,
        action: validatedData.action,
        reason: validatedData.reason
      });

      res.json({
        success: true,
        data: {
          reviewId: validatedData.reviewId,
          action: validatedData.action,
          status: validatedData.action === 'approve' ? 'published' : 'rejected',
          moderatedBy: req.user.sub,
          moderatedAt: new Date().toISOString()
        },
        message: `Review ${validatedData.action}d successfully`
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });
}

module.exports = new ReviewController();