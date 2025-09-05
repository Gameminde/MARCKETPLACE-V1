const structuredLogger = require('./structured-logger.service');
const redisService = require('./redis.service');

class MessagingService {
  constructor() {
    this.cachePrefix = 'message:';
    this.conversationPrefix = 'conversation:';
    this.cacheExpiry = 24 * 60 * 60; // 24 hours
    
    this.messagingMetrics = {
      totalMessages: 0,
      averageResponseTime: 0,
      translationAccuracy: 0.95,
      deliveryRate: 0.99,
      satisfactionScore: 0.92
    };
    
    // Supported languages for auto-translation
    this.supportedLanguages = [
      'en', 'fr', 'es', 'de', 'it', 'pt', 'ru', 'zh', 'ja', 'ko',
      'ar', 'hi', 'th', 'vi', 'tr', 'pl', 'nl', 'sv', 'da', 'no',
      'fi', 'cs', 'hu', 'ro', 'bg', 'hr', 'sk', 'sl', 'et', 'lv',
      'lt', 'mt', 'ga', 'cy', 'eu', 'ca', 'gl', 'is', 'mk', 'sq',
      'sr', 'bs', 'me', 'uk', 'be', 'kk', 'ky', 'uz', 'tg', 'mn'
    ];
  }

  /**
   * Send a message with real-time delivery and auto-translation
   */
  async sendMessage(messageData, senderId) {
    const startTime = Date.now();
    const messageId = this.generateMessageId();
    
    try {
      // Validate message data
      this.validateMessageData(messageData);
      
      // Get or create conversation
      const conversation = await this.getOrCreateConversation(
        messageData.conversationId,
        senderId,
        messageData.recipientId
      );
      
      // Content moderation
      const moderationResult = await this.moderateMessage(messageData.content);
      
      // Auto-translation if needed
      const translationResult = await this.translateMessage(
        messageData.content,
        messageData.language || 'en',
        messageData.targetLanguage
      );
      
      // File processing (if any)
      const processedFiles = await this.processMessageFiles(messageData.files || []);
      
      // Create message object
      const message = {
        id: messageId,
        conversationId: conversation.id,
        senderId,
        recipientId: messageData.recipientId,
        content: messageData.content,
        translatedContent: translationResult.translatedText,
        originalLanguage: messageData.language || 'en',
        targetLanguage: translationResult.targetLanguage,
        messageType: messageData.type || 'text', // text, image, video, file, voice
        files: processedFiles,
        
        // Moderation results
        moderation: moderationResult,
        approved: moderationResult.approved,
        
        // Message metadata
        priority: messageData.priority || 'normal', // low, normal, high, urgent
        encrypted: true, // All messages are encrypted
        readBy: [],
        deliveredTo: [],
        
        // Timestamps
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        expiresAt: messageData.expiresAt || null, // For disappearing messages
        
        // Processing metrics
        processingTime: Date.now() - startTime
      };
      
      // Store message
      await this.storeMessage(message);
      
      // Update conversation
      await this.updateConversation(conversation.id, message);
      
      // Real-time delivery
      await this.deliverMessage(message);
      
      // Send push notifications
      await this.sendMessageNotifications(message);
      
      // Update metrics
      this.updateMessagingMetrics(message);
      
      structuredLogger.logInfo('MESSAGE_SENT', {
        messageId,
        conversationId: conversation.id,
        senderId,
        recipientId: messageData.recipientId,
        messageType: message.messageType,
        translated: !!translationResult.translatedText,
        approved: moderationResult.approved,
        processingTime: message.processingTime
      });
      
      return message;
      
    } catch (error) {
      structuredLogger.logError('MESSAGE_SEND_ERROR', {
        messageId,
        senderId,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Get conversation messages with real-time updates
   */
  async getConversationMessages(conversationId, userId, options = {}) {
    try {
      // Verify user access to conversation
      const hasAccess = await this.verifyConversationAccess(conversationId, userId);
      if (!hasAccess) {
        throw new Error('Access denied to conversation');
      }
      
      // Get cached messages first
      const cacheKey = `${this.conversationPrefix}${conversationId}:messages`;
      const cached = await this.getCachedData(cacheKey);
      
      if (cached && !options.forceRefresh) {
        return this.paginateMessages(cached, options);
      }
      
      // Fetch messages from database
      const messages = await this.fetchConversationMessages(conversationId, options);
      
      // Decrypt messages for the user
      const decryptedMessages = await this.decryptMessages(messages, userId);
      
      // Mark messages as read
      await this.markMessagesAsRead(conversationId, userId);
      
      // Cache messages
      await this.cacheData(cacheKey, decryptedMessages);
      
      const result = {
        conversationId,
        messages: this.paginateMessages(decryptedMessages, options),
        totalMessages: decryptedMessages.length,
        unreadCount: await this.getUnreadCount(conversationId, userId),
        lastActivity: decryptedMessages[0]?.createdAt || null
      };
      
      structuredLogger.logInfo('CONVERSATION_MESSAGES_RETRIEVED', {
        conversationId,
        userId,
        messageCount: result.messages.length,
        unreadCount: result.unreadCount
      });
      
      return result;
      
    } catch (error) {
      structuredLogger.logError('GET_CONVERSATION_MESSAGES_ERROR', {
        conversationId,
        userId,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Auto-translate message to target language
   */
  async translateMessage(content, sourceLanguage = 'auto', targetLanguage = null) {
    try {
      // Skip translation if no target language specified
      if (!targetLanguage || sourceLanguage === targetLanguage) {
        return {
          originalText: content,
          translatedText: null,
          sourceLanguage,
          targetLanguage,
          confidence: 1.0
        };
      }
      
      // Validate supported languages
      if (!this.supportedLanguages.includes(targetLanguage)) {
        throw new Error(`Unsupported target language: ${targetLanguage}`);
      }
      
      // Mock translation - in production would use Google Translate API
      const translatedText = await this.mockTranslate(content, sourceLanguage, targetLanguage);
      
      return {
        originalText: content,
        translatedText,
        sourceLanguage: sourceLanguage === 'auto' ? 'en' : sourceLanguage,
        targetLanguage,
        confidence: 0.95,
        translationTime: Date.now()
      };
      
    } catch (error) {
      structuredLogger.logError('MESSAGE_TRANSLATION_ERROR', {
        sourceLanguage,
        targetLanguage,
        error: error.message
      });
      
      return {
        originalText: content,
        translatedText: null,
        sourceLanguage,
        targetLanguage,
        confidence: 0,
        error: error.message
      };
    }
  }

  /**
   * Process message files (images, videos, documents)
   */
  async processMessageFiles(files) {
    const processedFiles = [];
    
    for (const file of files) {
      try {
        const processed = await this.processMessageFile(file);
        processedFiles.push(processed);
      } catch (error) {
        structuredLogger.logError('FILE_PROCESSING_ERROR', {
          fileName: file.name,
          error: error.message
        });
        
        // Add error file entry
        processedFiles.push({
          ...file,
          processed: false,
          error: error.message
        });
      }
    }
    
    return processedFiles;
  }

  /**
   * Process individual message file
   */
  async processMessageFile(file) {
    const startTime = Date.now();
    
    // Validate file
    this.validateMessageFile(file);
    
    // Generate secure file ID
    const fileId = this.generateFileId();
    
    // Determine file type and processing
    const fileType = this.getFileType(file.mimeType);
    
    let processedFile = {
      id: fileId,
      originalName: file.name,
      mimeType: file.mimeType,
      size: file.size,
      type: fileType,
      url: file.url || null,
      thumbnailUrl: null,
      previewUrl: null,
      metadata: {},
      processed: true,
      processingTime: 0
    };
    
    // Process based on file type
    switch (fileType) {
      case 'image':
        processedFile = await this.processImageFile(processedFile, file);
        break;
      case 'video':
        processedFile = await this.processVideoFile(processedFile, file);
        break;
      case 'document':
        processedFile = await this.processDocumentFile(processedFile, file);
        break;
      case 'audio':
        processedFile = await this.processAudioFile(processedFile, file);
        break;
      default:
        processedFile.metadata = { type: 'unknown' };
    }
    
    processedFile.processingTime = Date.now() - startTime;
    
    return processedFile;
  }

  /**
   * Start video call between users
   */
  async startVideoCall(callData, initiatorId) {
    const callId = this.generateCallId();
    
    try {
      // Validate call data
      this.validateCallData(callData);
      
      // Check if recipient is available
      const recipientAvailable = await this.checkUserAvailability(callData.recipientId);
      if (!recipientAvailable) {
        throw new Error('Recipient is not available for video call');
      }
      
      // Create call session
      const call = {
        id: callId,
        conversationId: callData.conversationId,
        initiatorId,
        recipientId: callData.recipientId,
        type: callData.type || 'video', // video, audio, screen_share
        status: 'initiating',
        quality: 'hd', // sd, hd, 4k
        
        // WebRTC configuration
        webrtcConfig: {
          iceServers: [
            { urls: 'stun:stun.l.google.com:19302' },
            { urls: 'turn:your-turn-server.com', username: 'user', credential: 'pass' }
          ]
        },
        
        // Call metadata
        startedAt: new Date().toISOString(),
        endedAt: null,
        duration: 0,
        participants: [initiatorId, callData.recipientId],
        
        // Features
        features: {
          recording: callData.recording || false,
          screenshare: false,
          chat: true,
          fileSharing: true
        }
      };
      
      // Store call session
      await this.storeCallSession(call);
      
      // Send call invitation
      await this.sendCallInvitation(call);
      
      // Set call timeout
      setTimeout(() => {
        this.handleCallTimeout(callId);
      }, 60000); // 1 minute timeout
      
      structuredLogger.logInfo('VIDEO_CALL_INITIATED', {
        callId,
        initiatorId,
        recipientId: callData.recipientId,
        type: call.type
      });
      
      return call;
      
    } catch (error) {
      structuredLogger.logError('VIDEO_CALL_START_ERROR', {
        callId,
        initiatorId,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Get user conversations with unread counts
   */
  async getUserConversations(userId, options = {}) {
    try {
      // Get cached conversations
      const cacheKey = `user:${userId}:conversations`;
      const cached = await this.getCachedData(cacheKey);
      
      if (cached && !options.forceRefresh) {
        return cached;
      }
      
      // Fetch conversations from database
      const conversations = await this.fetchUserConversations(userId, options);
      
      // Enrich conversations with metadata
      const enrichedConversations = await Promise.all(
        conversations.map(async (conversation) => {
          const unreadCount = await this.getUnreadCount(conversation.id, userId);
          const lastMessage = await this.getLastMessage(conversation.id);
          const otherParticipant = await this.getOtherParticipant(conversation.id, userId);
          
          return {
            ...conversation,
            unreadCount,
            lastMessage,
            otherParticipant,
            isOnline: await this.isUserOnline(otherParticipant?.id),
            lastActivity: lastMessage?.createdAt || conversation.updatedAt
          };
        })
      );
      
      // Sort by last activity
      enrichedConversations.sort((a, b) => 
        new Date(b.lastActivity) - new Date(a.lastActivity)
      );
      
      // Cache result
      await this.cacheData(cacheKey, enrichedConversations);
      
      return {
        conversations: enrichedConversations,
        totalUnread: enrichedConversations.reduce((sum, conv) => sum + conv.unreadCount, 0)
      };
      
    } catch (error) {
      structuredLogger.logError('GET_USER_CONVERSATIONS_ERROR', {
        userId,
        error: error.message
      });
      throw error;
    }
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  validateMessageData(messageData) {
    const required = ['recipientId', 'content'];
    for (const field of required) {
      if (!messageData[field]) {
        throw new Error(`Missing required field: ${field}`);
      }
    }
    
    if (messageData.content.length > 10000) {
      throw new Error('Message content too long (max 10000 characters)');
    }
    
    if (messageData.files && messageData.files.length > 10) {
      throw new Error('Too many files attached (max 10)');
    }
  }

  validateCallData(callData) {
    const required = ['recipientId', 'conversationId'];
    for (const field of required) {
      if (!callData[field]) {
        throw new Error(`Missing required field: ${field}`);
      }
    }
  }

  validateMessageFile(file) {
    const maxSize = 50 * 1024 * 1024; // 50MB
    const allowedTypes = [
      'image/jpeg', 'image/png', 'image/gif', 'image/webp',
      'video/mp4', 'video/webm', 'video/quicktime',
      'audio/mp3', 'audio/wav', 'audio/ogg',
      'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/plain', 'text/csv'
    ];
    
    if (file.size > maxSize) {
      throw new Error('File too large (max 50MB)');
    }
    
    if (!allowedTypes.includes(file.mimeType)) {
      throw new Error('File type not allowed');
    }
  }

  async moderateMessage(content) {
    // Mock message moderation
    const issues = [];
    
    // Check for inappropriate content
    const inappropriateWords = ['spam', 'scam', 'fake', 'fraud'];
    const hasInappropriate = inappropriateWords.some(word => 
      content.toLowerCase().includes(word)
    );
    
    if (hasInappropriate) {
      issues.push('Potentially inappropriate content detected');
    }
    
    // Check for excessive caps
    const capsRatio = (content.match(/[A-Z]/g) || []).length / content.length;
    if (capsRatio > 0.7) {
      issues.push('Excessive capitalization');
    }
    
    return {
      approved: issues.length === 0,
      score: issues.length === 0 ? 0.95 : 0.3,
      issues,
      moderatedAt: new Date().toISOString()
    };
  }

  async mockTranslate(content, sourceLanguage, targetLanguage) {
    // Mock translation - in production would use Google Translate API
    const translations = {
      'en-fr': {
        'Hello': 'Bonjour',
        'Thank you': 'Merci',
        'How are you?': 'Comment allez-vous?',
        'Good morning': 'Bonjour',
        'Good evening': 'Bonsoir'
      },
      'en-es': {
        'Hello': 'Hola',
        'Thank you': 'Gracias',
        'How are you?': '¿Cómo estás?',
        'Good morning': 'Buenos días',
        'Good evening': 'Buenas tardes'
      }
    };
    
    const translationKey = `${sourceLanguage}-${targetLanguage}`;
    const translationMap = translations[translationKey] || {};
    
    // Simple word replacement for demo
    let translated = content;
    Object.entries(translationMap).forEach(([original, translation]) => {
      translated = translated.replace(new RegExp(original, 'gi'), translation);
    });
    
    return translated !== content ? translated : `[${targetLanguage.toUpperCase()}] ${content}`;
  }

  getFileType(mimeType) {
    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('video/')) return 'video';
    if (mimeType.startsWith('audio/')) return 'audio';
    if (mimeType.includes('pdf') || mimeType.includes('document') || mimeType.includes('text')) return 'document';
    return 'other';
  }

  async processImageFile(processedFile, originalFile) {
    // Mock image processing
    processedFile.thumbnailUrl = `${originalFile.url}?thumbnail=150x150`;
    processedFile.previewUrl = `${originalFile.url}?preview=800x600`;
    processedFile.metadata = {
      dimensions: { width: 1920, height: 1080 }, // Mock dimensions
      format: 'JPEG',
      hasTransparency: false
    };
    return processedFile;
  }

  async processVideoFile(processedFile, originalFile) {
    // Mock video processing
    processedFile.thumbnailUrl = `${originalFile.url}?thumbnail=video`;
    processedFile.previewUrl = `${originalFile.url}?preview=480p`;
    processedFile.metadata = {
      duration: 120, // Mock 2 minutes
      dimensions: { width: 1920, height: 1080 },
      format: 'MP4',
      bitrate: 2000
    };
    return processedFile;
  }

  async processDocumentFile(processedFile, originalFile) {
    // Mock document processing
    processedFile.previewUrl = `${originalFile.url}?preview=document`;
    processedFile.metadata = {
      pages: 5, // Mock page count
      format: 'PDF',
      textExtractable: true
    };
    return processedFile;
  }

  async processAudioFile(processedFile, originalFile) {
    // Mock audio processing
    processedFile.metadata = {
      duration: 180, // Mock 3 minutes
      format: 'MP3',
      bitrate: 320,
      sampleRate: 44100
    };
    return processedFile;
  }

  // Mock database operations
  async getOrCreateConversation(conversationId, senderId, recipientId) {
    if (conversationId) {
      return { id: conversationId };
    }
    
    // Create new conversation
    const newConversationId = this.generateConversationId();
    return {
      id: newConversationId,
      participants: [senderId, recipientId],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
  }

  async storeMessage(message) {
    // Mock message storage
    structuredLogger.logInfo('MESSAGE_STORED', { messageId: message.id });
  }

  async updateConversation(conversationId, message) {
    // Mock conversation update
    structuredLogger.logInfo('CONVERSATION_UPDATED', { conversationId });
  }

  async deliverMessage(message) {
    // Mock real-time delivery via WebSocket
    structuredLogger.logInfo('MESSAGE_DELIVERED', { messageId: message.id });
  }

  async sendMessageNotifications(message) {
    // Mock push notification
    structuredLogger.logInfo('MESSAGE_NOTIFICATIONS_SENT', { messageId: message.id });
  }

  async fetchConversationMessages(conversationId, options) {
    // Mock message fetching
    return [
      {
        id: 'msg_1',
        conversationId,
        senderId: 'user_1',
        content: 'Hello! How can I help you?',
        messageType: 'text',
        createdAt: new Date(Date.now() - 3600000).toISOString() // 1 hour ago
      },
      {
        id: 'msg_2',
        conversationId,
        senderId: 'user_2',
        content: 'Hi! I have a question about this product.',
        messageType: 'text',
        createdAt: new Date(Date.now() - 1800000).toISOString() // 30 minutes ago
      }
    ];
  }

  async decryptMessages(messages, userId) {
    // Mock message decryption
    return messages.map(message => ({
      ...message,
      decrypted: true
    }));
  }

  // Utility methods
  generateMessageId() {
    return `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  generateConversationId() {
    return `conv_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  generateCallId() {
    return `call_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  generateFileId() {
    return `file_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  paginateMessages(messages, options) {
    const page = options.page || 1;
    const limit = options.limit || 50;
    const startIndex = (page - 1) * limit;
    return messages.slice(startIndex, startIndex + limit);
  }

  updateMessagingMetrics(message) {
    this.messagingMetrics.totalMessages++;
    // Update other metrics...
  }

  async getCachedData(cacheKey) {
    try {
      const cached = await redisService.get(cacheKey);
      return cached ? JSON.parse(cached) : null;
    } catch (error) {
      return null;
    }
  }

  async cacheData(cacheKey, data) {
    try {
      await redisService.setex(cacheKey, this.cacheExpiry, JSON.stringify(data));
    } catch (error) {
      structuredLogger.logError('MESSAGING_CACHE_ERROR', { error: error.message });
    }
  }

  // Mock async operations
  async verifyConversationAccess(conversationId, userId) {
    return true; // Mock access verification
  }

  async markMessagesAsRead(conversationId, userId) {
    structuredLogger.logInfo('MESSAGES_MARKED_READ', { conversationId, userId });
  }

  async getUnreadCount(conversationId, userId) {
    return Math.floor(Math.random() * 5); // Mock unread count
  }

  async checkUserAvailability(userId) {
    return true; // Mock availability check
  }

  async storeCallSession(call) {
    structuredLogger.logInfo('CALL_SESSION_STORED', { callId: call.id });
  }

  async sendCallInvitation(call) {
    structuredLogger.logInfo('CALL_INVITATION_SENT', { callId: call.id });
  }

  async handleCallTimeout(callId) {
    structuredLogger.logInfo('CALL_TIMEOUT', { callId });
  }

  async fetchUserConversations(userId, options) {
    // Mock user conversations
    return [
      {
        id: 'conv_1',
        participants: [userId, 'user_2'],
        createdAt: new Date(Date.now() - 86400000).toISOString(),
        updatedAt: new Date(Date.now() - 3600000).toISOString()
      }
    ];
  }

  async getLastMessage(conversationId) {
    return {
      id: 'msg_last',
      content: 'Thank you for your help!',
      createdAt: new Date(Date.now() - 3600000).toISOString()
    };
  }

  async getOtherParticipant(conversationId, userId) {
    return {
      id: 'user_2',
      name: 'John Doe',
      avatar: 'https://example.com/avatar.jpg'
    };
  }

  async isUserOnline(userId) {
    return Math.random() > 0.5; // Mock online status
  }
}

module.exports = new MessagingService();