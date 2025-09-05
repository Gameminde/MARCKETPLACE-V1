const express = require('express');
const router = express.Router();
const messagingController = require('../controllers/messaging.controller');
const authMiddleware = require('../middleware/auth.middleware');

// Public routes
router.get('/languages', messagingController.getSupportedLanguages);

// Authenticated user routes
router.use(authMiddleware);

// Messaging
router.post('/send', messagingController.sendMessage);
router.get('/conversations', messagingController.getUserConversations);
router.get('/conversations/:conversationId/messages', messagingController.getConversationMessages);

// Translation
router.post('/translate', messagingController.translateMessage);

// File upload
router.post('/upload', messagingController.uploadMessageFile);

// Video calls
router.post('/calls/start', messagingController.startVideoCall);
router.post('/calls/:callId/answer', messagingController.answerVideoCall);
router.post('/calls/:callId/end', messagingController.endVideoCall);

// User management
router.post('/users/:userId/block', messagingController.blockUser);
router.post('/report', messagingController.reportMessage);

// Admin analytics
router.get('/analytics', authMiddleware.requireRole('admin'), messagingController.getMessagingAnalytics);

module.exports = router;