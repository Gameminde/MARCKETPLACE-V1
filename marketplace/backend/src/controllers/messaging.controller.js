const BaseController = require('./BaseController');
const messagingService = require('../services/messaging.service');
const structuredLogger = require('../services/structured-logger.service');
const Joi = require('joi');

class MessagingController extends BaseController {
  constructor() {
    super('MESSAGING');
  }

  /**
   * Send a message with auto-translation and real-time delivery
   */
  sendMessage = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      recipientId: Joi.string().required(),
      conversationId: Joi.string().optional(),
      content: Joi.string().min(1).max(10000).required(),
      type: Joi.string().valid('text', 'image', 'video', 'file', 'voice').default('text'),
      language: Joi.string().length(2).optional(),
      targetLanguage: Joi.string().length(2).optional(),
      priority: Joi.string().valid('low', 'normal', 'high', 'urgent').default('normal'),
      expiresAt: Joi.date().iso().optional(),
      files: Joi.array().items(Joi.object({
        name: Joi.string().required(),
        url: Joi.string().uri().required(),
        mimeType: Joi.string().required(),
        size: Joi.number().integer().min(1).required()
      })).max(10).default([])
    });

    const validatedData = this.validateRequest(schema, req.body);

    try {
      const message = await messagingService.sendMessage(validatedData, req.user.sub);

      structuredLogger.logInfo('MESSAGE_SENT_SUCCESS', {
        senderId: req.user.sub,
        recipientId: validatedData.recipientId,
        messageId: message.id,
        messageType: message.messageType,
        translated: !!message.translatedContent,
        approved: message.approved
      });

      res.status(201).json({
        success: true,
        data: message,
        message: message.approved ? 'Message sent successfully' : 'Message sent for moderation'
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Get conversation messages with real-time updates
   */
  getConversationMessages = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      conversationId: Joi.string().required(),
      page: Joi.number().integer().min(1).default(1),
      limit: Joi.number().integer().min(1).max(100).default(50),
      before: Joi.date().iso().optional(),
      after: Joi.date().iso().optional(),
      forceRefresh: Joi.boolean().default(false)
    });

    const validatedData = this.validateRequest(schema, {
      ...req.params,
      ...req.query
    });

    try {
      const options = {
        page: validatedData.page,
        limit: validatedData.limit,
        forceRefresh: validatedData.forceRefresh
      };

      if (validatedData.before) options.before = validatedData.before;
      if (validatedData.after) options.after = validatedData.after;

      const conversation = await messagingService.getConversationMessages(
        validatedData.conversationId,
        req.user.sub,
        options
      );

      res.json({
        success: true,
        data: conversation
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Get user conversations with unread counts
   */
  getUserConversations = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      page: Joi.number().integer().min(1).default(1),
      limit: Joi.number().integer().min(1).max(100).default(20),
      unreadOnly: Joi.boolean().default(false),
      forceRefresh: Joi.boolean().default(false)
    });

    const validatedData = this.validateRequest(schema, req.query);

    try {
      const options = {
        page: validatedData.page,
        limit: validatedData.limit,
        unreadOnly: validatedData.unreadOnly,
        forceRefresh: validatedData.forceRefresh
      };

      const conversations = await messagingService.getUserConversations(req.user.sub, options);

      res.json({
        success: true,
        data: conversations
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Translate a message to target language
   */
  translateMessage = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      content: Joi.string().min(1).max(10000).required(),
      sourceLanguage: Joi.string().length(2).default('auto'),
      targetLanguage: Joi.string().length(2).required()
    });

    const validatedData = this.validateRequest(schema, req.body);

    try {
      const translation = await messagingService.translateMessage(
        validatedData.content,
        validatedData.sourceLanguage,
        validatedData.targetLanguage
      );

      res.json({
        success: true,
        data: translation
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Start a video call
   */
  startVideoCall = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      recipientId: Joi.string().required(),
      conversationId: Joi.string().required(),
      type: Joi.string().valid('video', 'audio', 'screen_share').default('video'),
      recording: Joi.boolean().default(false)
    });

    const validatedData = this.validateRequest(schema, req.body);

    try {
      const call = await messagingService.startVideoCall(validatedData, req.user.sub);

      structuredLogger.logInfo('VIDEO_CALL_STARTED_SUCCESS', {
        initiatorId: req.user.sub,
        recipientId: validatedData.recipientId,
        callId: call.id,
        type: call.type
      });

      res.status(201).json({
        success: true,
        data: call,
        message: 'Video call initiated successfully'
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Answer a video call
   */
  answerVideoCall = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      callId: Joi.string().required(),
      accept: Joi.boolean().required()
    });

    const validatedData = this.validateRequest(schema, {
      ...req.params,
      ...req.body
    });

    try {
      // Mock call answer handling
      const callStatus = validatedData.accept ? 'accepted' : 'declined';

      structuredLogger.logInfo('VIDEO_CALL_ANSWERED', {
        callId: validatedData.callId,
        userId: req.user.sub,
        accepted: validatedData.accept
      });

      res.json({
        success: true,
        data: {
          callId: validatedData.callId,
          status: callStatus,
          answeredBy: req.user.sub,
          answeredAt: new Date().toISOString()
        },
        message: `Call ${callStatus} successfully`
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * End a video call
   */
  endVideoCall = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      callId: Joi.string().required(),
      reason: Joi.string().valid('completed', 'cancelled', 'timeout', 'error').default('completed')
    });

    const validatedData = this.validateRequest(schema, {
      ...req.params,
      ...req.body
    });

    try {
      // Mock call end handling
      const callDuration = Math.floor(Math.random() * 1800); // Random duration up to 30 minutes

      structuredLogger.logInfo('VIDEO_CALL_ENDED', {
        callId: validatedData.callId,
        userId: req.user.sub,
        reason: validatedData.reason,
        duration: callDuration
      });

      res.json({
        success: true,
        data: {
          callId: validatedData.callId,
          status: 'ended',
          reason: validatedData.reason,
          duration: callDuration,
          endedBy: req.user.sub,
          endedAt: new Date().toISOString()
        },
        message: 'Call ended successfully'
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Upload file for messaging
   */
  uploadMessageFile = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      conversationId: Joi.string().required(),
      file: Joi.object({
        name: Joi.string().required(),
        mimeType: Joi.string().required(),
        size: Joi.number().integer().min(1).max(50 * 1024 * 1024).required(), // 50MB max
        data: Joi.string().required() // Base64 encoded file data
      }).required()
    });

    const validatedData = this.validateRequest(schema, req.body);

    try {
      // Mock file upload processing
      const fileId = `file_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const fileUrl = `https://cdn.marketplace.com/messages/${fileId}`;

      const processedFile = {
        id: fileId,
        name: validatedData.file.name,
        mimeType: validatedData.file.mimeType,
        size: validatedData.file.size,
        url: fileUrl,
        thumbnailUrl: validatedData.file.mimeType.startsWith('image/') ? `${fileUrl}?thumbnail=150x150` : null,
        uploadedBy: req.user.sub,
        uploadedAt: new Date().toISOString(),
        conversationId: validatedData.conversationId
      };

      structuredLogger.logInfo('MESSAGE_FILE_UPLOADED', {
        fileId,
        userId: req.user.sub,
        conversationId: validatedData.conversationId,
        fileName: validatedData.file.name,
        fileSize: validatedData.file.size
      });

      res.status(201).json({
        success: true,
        data: processedFile,
        message: 'File uploaded successfully'
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Get messaging analytics (for admins)
   */
  getMessagingAnalytics = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      timeframe: Joi.string().valid('24h', '7d', '30d', '90d').default('7d'),
      userId: Joi.string().optional(),
      conversationId: Joi.string().optional()
    });

    const validatedData = this.validateRequest(schema, req.query);

    try {
      // Mock analytics data
      const analytics = {
        totalMessages: 15420,
        totalConversations: 2340,
        activeUsers: 1850,
        averageResponseTime: 8.5, // minutes
        messageTypes: {
          text: 12500,
          image: 1800,
          video: 650,
          file: 420,
          voice: 50
        },
        translationStats: {
          totalTranslations: 3200,
          topLanguagePairs: [
            { from: 'en', to: 'fr', count: 850 },
            { from: 'en', to: 'es', count: 720 },
            { from: 'fr', to: 'en', count: 680 }
          ],
          accuracy: 95.2
        },
        moderationStats: {
          totalModerated: 1240,
          autoApproved: 1180,
          manualReview: 45,
          rejected: 15,
          accuracy: 96.8
        },
        videoCallStats: {
          totalCalls: 450,
          completedCalls: 380,
          averageDuration: 12.5, // minutes
          qualityRating: 4.3
        },
        trends: {
          messagesOverTime: [
            { date: '2024-12-01', count: 520, avgResponseTime: 8.2 },
            { date: '2024-12-02', count: 580, avgResponseTime: 7.8 },
            { date: '2024-12-03', count: 610, avgResponseTime: 8.1 }
          ]
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
   * Block/unblock a user
   */
  blockUser = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      userId: Joi.string().required(),
      block: Joi.boolean().required(),
      reason: Joi.string().max(500).optional()
    });

    const validatedData = this.validateRequest(schema, {
      ...req.params,
      ...req.body
    });

    try {
      const action = validatedData.block ? 'blocked' : 'unblocked';

      structuredLogger.logInfo('USER_BLOCK_STATUS_CHANGED', {
        blockerId: req.user.sub,
        blockedUserId: validatedData.userId,
        action,
        reason: validatedData.reason
      });

      res.json({
        success: true,
        data: {
          userId: validatedData.userId,
          status: action,
          blockedBy: req.user.sub,
          blockedAt: validatedData.block ? new Date().toISOString() : null,
          unblockedAt: !validatedData.block ? new Date().toISOString() : null,
          reason: validatedData.reason
        },
        message: `User ${action} successfully`
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Report a message or conversation
   */
  reportMessage = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      messageId: Joi.string().optional(),
      conversationId: Joi.string().optional(),
      reason: Joi.string().valid(
        'spam',
        'harassment',
        'inappropriate_content',
        'scam',
        'fake_profile',
        'other'
      ).required(),
      description: Joi.string().max(1000).optional()
    }).or('messageId', 'conversationId');

    const validatedData = this.validateRequest(schema, req.body);

    try {
      const reportId = `report_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

      structuredLogger.logInfo('MESSAGE_REPORTED', {
        reportId,
        reporterId: req.user.sub,
        messageId: validatedData.messageId,
        conversationId: validatedData.conversationId,
        reason: validatedData.reason
      });

      res.json({
        success: true,
        data: {
          reportId,
          status: 'submitted',
          reportedBy: req.user.sub,
          reportedAt: new Date().toISOString(),
          estimatedReviewTime: '24 hours'
        },
        message: 'Report submitted successfully. We will review it within 24 hours.'
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Get supported languages for translation
   */
  getSupportedLanguages = this.asyncHandler(async (req, res) => {
    try {
      const languages = [
        { code: 'en', name: 'English', nativeName: 'English' },
        { code: 'fr', name: 'French', nativeName: 'Français' },
        { code: 'es', name: 'Spanish', nativeName: 'Español' },
        { code: 'de', name: 'German', nativeName: 'Deutsch' },
        { code: 'it', name: 'Italian', nativeName: 'Italiano' },
        { code: 'pt', name: 'Portuguese', nativeName: 'Português' },
        { code: 'ru', name: 'Russian', nativeName: 'Русский' },
        { code: 'zh', name: 'Chinese', nativeName: '中文' },
        { code: 'ja', name: 'Japanese', nativeName: '日本語' },
        { code: 'ko', name: 'Korean', nativeName: '한국어' },
        { code: 'ar', name: 'Arabic', nativeName: 'العربية' },
        { code: 'hi', name: 'Hindi', nativeName: 'हिन्दी' },
        { code: 'th', name: 'Thai', nativeName: 'ไทย' },
        { code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt' },
        { code: 'tr', name: 'Turkish', nativeName: 'Türkçe' }
      ];

      res.json({
        success: true,
        data: {
          languages,
          totalSupported: languages.length,
          autoDetectSupported: true
        }
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });
}

module.exports = new MessagingController();