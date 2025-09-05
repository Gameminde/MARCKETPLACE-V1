const express = require('express');
const router = express.Router();
const disputeController = require('../controllers/dispute.controller');
const authMiddleware = require('../middleware/auth.middleware');

// Authenticated user routes
router.use(authMiddleware);

// Dispute management
router.post('/', disputeController.createDispute);
router.get('/my-disputes', disputeController.getUserDisputes);
router.get('/:disputeId', disputeController.getDispute);

// Dispute communication
router.post('/:disputeId/messages', disputeController.addDisputeMessage);

// Resolution management
router.post('/:disputeId/accept-resolution', disputeController.acceptResolution);
router.post('/:disputeId/reject-resolution', disputeController.rejectResolution);

// Analytics (for sellers and shop owners)
router.get('/analytics', disputeController.getDisputeAnalytics);

// Mediator/Admin routes
router.get('/queue', authMiddleware.requireRole('admin'), disputeController.getDisputeQueue);
router.post('/:disputeId/assign', authMiddleware.requireRole('admin'), disputeController.assignDispute);
router.post('/:disputeId/resolve', authMiddleware.requireRole('admin'), disputeController.resolveDispute);
router.get('/templates', authMiddleware.requireRole('admin'), disputeController.getResolutionTemplates);

module.exports = router;