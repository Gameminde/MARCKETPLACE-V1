const express = require('express');
const router = express.Router();
const xpController = require('../controllers/xp.controller');
const authMiddleware = require('../middleware/auth.middleware');

// ========================================
// PUBLIC ROUTES (No authentication required)
// ========================================

/**
 * @route GET /api/v1/xp/achievements
 * @desc Get all available achievements
 * @access Public
 */
router.get('/achievements', xpController.getAchievements.bind(xpController));

/**
 * @route GET /api/v1/xp/leaderboard
 * @desc Get leaderboard (public view)
 * @access Public
 * @query {string} type - daily, weekly, monthly, all_time (default: all_time)
 * @query {number} limit - Number of results (default: 50, max: 100)
 */
router.get('/leaderboard', xpController.getLeaderboard.bind(xpController));

/**
 * @route GET /api/v1/xp/levels
 * @desc Get level information and XP requirements
 * @access Public
 */
router.get('/levels', xpController.getLevelInfo.bind(xpController));

// ========================================
// PROTECTED ROUTES (Authentication required)
// ========================================

// Apply authentication middleware to all routes below
router.use(authMiddleware);

/**
 * @route GET /api/v1/xp/user
 * @desc Get current user's XP data
 * @access Private
 */
router.get('/user', xpController.getUserXP.bind(xpController));

/**
 * @route POST /api/v1/xp/initialize
 * @desc Initialize XP system for current user
 * @access Private
 */
router.post('/initialize', xpController.initializeUserXP.bind(xpController));

/**
 * @route POST /api/v1/xp/track
 * @desc Track user activity and award XP
 * @access Private
 * @body {string} activityType - Type of activity (product_view, purchase, review, share, referral)
 * @body {string} [sourceId] - ID of related entity
 * @body {string} [description] - Activity description
 * @body {object} [metadata] - Additional metadata
 */
router.post('/track', xpController.trackActivity.bind(xpController));

/**
 * @route POST /api/v1/xp/track/bulk
 * @desc Track multiple activities in bulk
 * @access Private
 * @body {array} activities - Array of activity objects
 */
router.post('/track/bulk', xpController.trackBulkActivities.bind(xpController));

/**
 * @route GET /api/v1/xp/user/achievements
 * @desc Get current user's achievements
 * @access Private
 */
router.get('/user/achievements', xpController.getUserAchievements.bind(xpController));

/**
 * @route GET /api/v1/xp/user/challenges
 * @desc Get current user's active challenges
 * @access Private
 */
router.get('/user/challenges', xpController.getUserChallenges.bind(xpController));

/**
 * @route GET /api/v1/xp/user/rank
 * @desc Get current user's rank in leaderboard
 * @access Private
 * @query {string} type - daily, weekly, monthly, all_time (default: all_time)
 */
router.get('/user/rank', xpController.getUserRank.bind(xpController));

/**
 * @route GET /api/v1/xp/user/history
 * @desc Get current user's XP transaction history
 * @access Private
 * @query {number} page - Page number (default: 1)
 * @query {number} limit - Results per page (default: 20, max: 100)
 */
router.get('/user/history', xpController.getUserXPHistory.bind(xpController));

// ========================================
// ADMIN ROUTES (Admin role required)
// ========================================

/**
 * @route POST /api/v1/xp/award/:userId?
 * @desc Award XP to a user (admin only)
 * @access Admin
 * @param {string} [userId] - Target user ID (optional, defaults to current user)
 * @body {number} amount - XP amount to award
 * @body {string} source - Source of XP award
 * @body {string} [sourceId] - ID of related entity
 * @body {string} description - Description of XP award
 */
router.post('/award/:userId?', 
  authMiddleware.requireRole('admin'), 
  xpController.awardXP.bind(xpController)
);

/**
 * @route GET /api/v1/xp/stats
 * @desc Get XP system statistics (admin only)
 * @access Admin
 */
router.get('/stats', 
  authMiddleware.requireRole('admin'), 
  xpController.getXPStats.bind(xpController)
);

// ========================================
// MIDDLEWARE FOR ACTIVITY TRACKING
// ========================================

/**
 * Middleware to automatically track product views
 * This can be used in product routes to automatically award XP
 */
const trackProductView = async (req, res, next) => {
  try {
    if (req.user && req.params.productId) {
      // Don't await - fire and forget to avoid slowing down the main request
      setImmediate(async () => {
        try {
          const xpService = require('../services/xp.service');
          await xpService.trackActivity(req.user.id, 'product_view', {
            sourceId: req.params.productId,
            description: 'Product viewed'
          });
        } catch (error) {
          // Log error but don't fail the main request
          console.error('Error tracking product view XP:', error);
        }
      });
    }
    next();
  } catch (error) {
    next(); // Don't fail the main request
  }
};

/**
 * Middleware to automatically track purchases
 * This can be used in payment/order routes
 */
const trackPurchase = async (req, res, next) => {
  try {
    if (req.user && req.body.orderId) {
      setImmediate(async () => {
        try {
          const xpService = require('../services/xp.service');
          await xpService.trackActivity(req.user.id, 'purchase', {
            sourceId: req.body.orderId,
            description: 'Purchase completed'
          });
        } catch (error) {
          console.error('Error tracking purchase XP:', error);
        }
      });
    }
    next();
  } catch (error) {
    next();
  }
};

/**
 * Middleware to automatically track reviews
 * This can be used in review routes
 */
const trackReview = async (req, res, next) => {
  try {
    if (req.user && req.params.productId) {
      setImmediate(async () => {
        try {
          const xpService = require('../services/xp.service');
          await xpService.trackActivity(req.user.id, 'review', {
            sourceId: req.params.productId,
            description: 'Review written'
          });
        } catch (error) {
          console.error('Error tracking review XP:', error);
        }
      });
    }
    next();
  } catch (error) {
    next();
  }
};

/**
 * Middleware to automatically track social shares
 * This can be used in sharing endpoints
 */
const trackShare = async (req, res, next) => {
  try {
    if (req.user && req.body.productId) {
      setImmediate(async () => {
        try {
          const xpService = require('../services/xp.service');
          await xpService.trackActivity(req.user.id, 'share', {
            sourceId: req.body.productId,
            description: 'Product shared'
          });
        } catch (error) {
          console.error('Error tracking share XP:', error);
        }
      });
    }
    next();
  } catch (error) {
    next();
  }
};

// Export middleware for use in other routes
router.trackProductView = trackProductView;
router.trackPurchase = trackPurchase;
router.trackReview = trackReview;
router.trackShare = trackShare;

module.exports = router;