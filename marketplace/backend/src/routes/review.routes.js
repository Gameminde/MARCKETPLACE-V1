const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/review.controller');
const authMiddleware = require('../middleware/auth.middleware');

// Public routes
router.get('/product/:productId', reviewController.getProductReviews);
router.get('/shop/:shopId', reviewController.getShopReviews);

// Authenticated user routes
router.use(authMiddleware);

// Review management
router.post('/', reviewController.createReview);
router.get('/my-reviews', reviewController.getUserReviews);
router.post('/:reviewId/helpful', reviewController.markReviewHelpful);
router.post('/:reviewId/report', reviewController.reportReview);

// Seller response system
router.post('/:reviewId/response', reviewController.createSellerResponse);

// Analytics (for sellers and shop owners)
router.get('/analytics', reviewController.getReviewAnalytics);

// Admin routes
router.get('/moderation/queue', authMiddleware.requireRole('admin'), reviewController.getModerationQueue);
router.post('/:reviewId/moderate', authMiddleware.requireRole('admin'), reviewController.moderateReview);

module.exports = router;