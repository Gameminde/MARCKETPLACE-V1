const structuredLogger = require('./structured-logger.service');
const redisService = require('./redis.service');

class DisputeService {
  constructor() {
    this.cachePrefix = 'dispute:';
    this.cacheExpiry = 60 * 60; // 1 hour
    
    this.disputeMetrics = {
      totalDisputes: 0,
      resolutionRate: 0.92,
      averageResolutionTime: 48, // hours
      satisfactionScore: 0.88,
      aiAccuracy: 0.94
    };
    
    // Dispute categories and their resolution patterns
    this.disputeCategories = {
      'product_not_received': {
        priority: 'high',
        autoResolutionRate: 0.85,
        averageTime: 24,
        commonResolutions: ['refund', 'replacement', 'tracking_update']
      },
      'product_not_as_described': {
        priority: 'medium',
        autoResolutionRate: 0.70,
        averageTime: 48,
        commonResolutions: ['partial_refund', 'return', 'exchange']
      },
      'damaged_product': {
        priority: 'high',
        autoResolutionRate: 0.80,
        averageTime: 36,
        commonResolutions: ['full_refund', 'replacement', 'repair_compensation']
      },
      'billing_issue': {
        priority: 'high',
        autoResolutionRate: 0.90,
        averageTime: 12,
        commonResolutions: ['refund', 'billing_correction', 'credit']
      },
      'seller_communication': {
        priority: 'low',
        autoResolutionRate: 0.60,
        averageTime: 72,
        commonResolutions: ['mediation', 'seller_warning', 'communication_improvement']
      }
    };
  }

  /**
   * Create a new dispute with AI-powered initial assessment
   */
  async createDispute(disputeData, userId) {
    const startTime = Date.now();
    const disputeId = this.generateDisputeId();
    
    try {
      // Validate dispute data
      this.validateDisputeData(disputeData);
      
      // AI-powered dispute categorization
      const categoryAnalysis = await this.categorizeDispute(disputeData);
      
      // Analyze dispute context and history
      const contextAnalysis = await this.analyzeDisputeContext(disputeData, userId);
      
      // Predict resolution outcome
      const resolutionPrediction = await this.predictResolution(disputeData, categoryAnalysis, contextAnalysis);
      
      // Determine if auto-resolution is possible
      const autoResolution = await this.attemptAutoResolution(disputeData, categoryAnalysis, resolutionPrediction);
      
      // Create dispute object
      const dispute = {
        id: disputeId,
        userId,
        orderId: disputeData.orderId,
        productId: disputeData.productId,
        sellerId: disputeData.sellerId,
        shopId: disputeData.shopId,
        
        // Dispute details
        category: categoryAnalysis.category,
        subcategory: categoryAnalysis.subcategory,
        title: disputeData.title,
        description: disputeData.description,
        evidence: disputeData.evidence || [],
        
        // AI Analysis
        categoryAnalysis,
        contextAnalysis,
        resolutionPrediction,
        autoResolution,
        
        // Status and workflow
        status: autoResolution.possible ? 'auto_resolved' : 'open',
        priority: categoryAnalysis.priority,
        assignedTo: autoResolution.possible ? 'ai_system' : null,
        
        // Timeline
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        dueDate: this.calculateDueDate(categoryAnalysis.priority),
        resolvedAt: autoResolution.possible ? new Date().toISOString() : null,
        
        // Communication
        messages: [],
        participants: [userId, disputeData.sellerId],
        
        // Resolution
        resolution: autoResolution.possible ? autoResolution.resolution : null,
        satisfactionRating: null,
        
        // Metrics
        processingTime: Date.now() - startTime
      };
      
      // Store dispute
      await this.storeDispute(dispute);
      
      // Send notifications
      await this.sendDisputeNotifications(dispute);
      
      // If auto-resolved, execute resolution
      if (autoResolution.possible) {
        await this.executeResolution(dispute);
      } else {
        // Assign to appropriate mediator
        await this.assignDispute(dispute);
      }
      
      // Update metrics
      this.updateDisputeMetrics(dispute);
      
      structuredLogger.logInfo('DISPUTE_CREATED', {
        disputeId,
        userId,
        category: categoryAnalysis.category,
        priority: categoryAnalysis.priority,
        autoResolved: autoResolution.possible,
        predictionConfidence: resolutionPrediction.confidence,
        processingTime: dispute.processingTime
      });
      
      return dispute;
      
    } catch (error) {
      structuredLogger.logError('DISPUTE_CREATION_ERROR', {
        disputeId,
        userId,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * AI-powered dispute categorization
   */
  async categorizeDispute(disputeData) {
    try {
      const text = `${disputeData.title} ${disputeData.description}`.toLowerCase();
      
      // Keyword-based categorization (in production would use ML model)
      let category = 'other';
      let confidence = 0.5;
      
      // Product not received
      if (/not received|didn't arrive|never got|missing|lost/.test(text)) {
        category = 'product_not_received';
        confidence = 0.9;
      }
      // Product not as described
      else if (/not as described|different|wrong|fake|counterfeit|misleading/.test(text)) {
        category = 'product_not_as_described';
        confidence = 0.85;
      }
      // Damaged product
      else if (/damaged|broken|defective|cracked|torn|scratched/.test(text)) {
        category = 'damaged_product';
        confidence = 0.88;
      }
      // Billing issues
      else if (/charged|billing|payment|refund|money|overcharged/.test(text)) {
        category = 'billing_issue';
        confidence = 0.92;
      }
      // Communication issues
      else if (/seller|communication|response|rude|unprofessional/.test(text)) {
        category = 'seller_communication';
        confidence = 0.75;
      }
      
      const categoryInfo = this.disputeCategories[category] || {
        priority: 'medium',
        autoResolutionRate: 0.5,
        averageTime: 48,
        commonResolutions: ['manual_review']
      };
      
      return {
        category,
        subcategory: this.determineSubcategory(category, text),
        confidence,
        priority: categoryInfo.priority,
        autoResolutionRate: categoryInfo.autoResolutionRate,
        estimatedResolutionTime: categoryInfo.averageTime,
        commonResolutions: categoryInfo.commonResolutions,
        keywords: this.extractKeywords(text)
      };
      
    } catch (error) {
      return {
        category: 'other',
        subcategory: 'unknown',
        confidence: 0,
        priority: 'medium',
        autoResolutionRate: 0.3,
        estimatedResolutionTime: 72,
        commonResolutions: ['manual_review'],
        error: error.message
      };
    }
  }

  /**
   * Analyze dispute context and user history
   */
  async analyzeDisputeContext(disputeData, userId) {
    try {
      // Get user dispute history
      const userHistory = await this.getUserDisputeHistory(userId);
      
      // Get seller history
      const sellerHistory = await this.getSellerDisputeHistory(disputeData.sellerId);
      
      // Get order details
      const orderDetails = await this.getOrderDetails(disputeData.orderId);
      
      // Calculate risk factors
      const riskFactors = this.calculateRiskFactors(userHistory, sellerHistory, orderDetails);
      
      return {
        userHistory: {
          totalDisputes: userHistory.totalDisputes,
          resolutionRate: userHistory.resolutionRate,
          averageRating: userHistory.averageRating,
          accountAge: userHistory.accountAge,
          riskLevel: this.calculateUserRiskLevel(userHistory)
        },
        sellerHistory: {
          totalDisputes: sellerHistory.totalDisputes,
          resolutionRate: sellerHistory.resolutionRate,
          averageRating: sellerHistory.averageRating,
          responseTime: sellerHistory.averageResponseTime,
          riskLevel: this.calculateSellerRiskLevel(sellerHistory)
        },
        orderContext: {
          orderValue: orderDetails.total,
          orderAge: this.calculateOrderAge(orderDetails.createdAt),
          deliveryStatus: orderDetails.deliveryStatus,
          paymentMethod: orderDetails.paymentMethod,
          isFirstOrder: orderDetails.isFirstOrder
        },
        riskFactors,
        overallRiskScore: this.calculateOverallRiskScore(riskFactors)
      };
      
    } catch (error) {
      return {
        userHistory: { riskLevel: 'unknown' },
        sellerHistory: { riskLevel: 'unknown' },
        orderContext: {},
        riskFactors: [],
        overallRiskScore: 0.5,
        error: error.message
      };
    }
  }

  /**
   * Predict dispute resolution with ML-powered analysis
   */
  async predictResolution(disputeData, categoryAnalysis, contextAnalysis) {
    try {
      // Mock ML prediction - in production would use trained model
      let resolutionType = 'unknown';
      let confidence = 0.5;
      let estimatedTime = 48;
      
      // Rule-based prediction for demo
      const category = categoryAnalysis.category;
      const riskScore = contextAnalysis.overallRiskScore;
      
      if (category === 'product_not_received') {
        if (riskScore < 0.3) {
          resolutionType = 'full_refund';
          confidence = 0.9;
          estimatedTime = 24;
        } else {
          resolutionType = 'investigation_required';
          confidence = 0.7;
          estimatedTime = 72;
        }
      } else if (category === 'damaged_product') {
        resolutionType = 'replacement_or_refund';
        confidence = 0.85;
        estimatedTime = 36;
      } else if (category === 'billing_issue') {
        resolutionType = 'billing_correction';
        confidence = 0.95;
        estimatedTime = 12;
      }
      
      return {
        predictedResolution: resolutionType,
        confidence,
        estimatedTimeHours: estimatedTime,
        alternativeResolutions: this.getAlternativeResolutions(category),
        factors: {
          categoryWeight: 0.4,
          historyWeight: 0.3,
          contextWeight: 0.3
        },
        modelVersion: '1.0.0',
        predictionTime: new Date().toISOString()
      };
      
    } catch (error) {
      return {
        predictedResolution: 'manual_review',
        confidence: 0,
        estimatedTimeHours: 72,
        alternativeResolutions: [],
        error: error.message
      };
    }
  }

  /**
   * Attempt automatic resolution based on AI analysis
   */
  async attemptAutoResolution(disputeData, categoryAnalysis, resolutionPrediction) {
    try {
      // Check if auto-resolution is possible
      const canAutoResolve = 
        categoryAnalysis.autoResolutionRate > 0.8 &&
        resolutionPrediction.confidence > 0.85 &&
        categoryAnalysis.category !== 'seller_communication';
      
      if (!canAutoResolve) {
        return {
          possible: false,
          reason: 'Insufficient confidence for auto-resolution',
          confidence: resolutionPrediction.confidence,
          requiresHuman: true
        };
      }
      
      // Generate resolution based on prediction
      const resolution = await this.generateAutoResolution(
        disputeData,
        categoryAnalysis,
        resolutionPrediction
      );
      
      return {
        possible: true,
        resolution,
        confidence: resolutionPrediction.confidence,
        estimatedSatisfaction: this.estimateResolutionSatisfaction(resolution),
        autoResolutionTime: Date.now()
      };
      
    } catch (error) {
      return {
        possible: false,
        reason: 'Auto-resolution failed',
        error: error.message,
        requiresHuman: true
      };
    }
  }

  /**
   * Generate automatic resolution
   */
  async generateAutoResolution(disputeData, categoryAnalysis, resolutionPrediction) {
    const category = categoryAnalysis.category;
    const prediction = resolutionPrediction.predictedResolution;
    
    let resolution = {
      type: prediction,
      description: '',
      actions: [],
      compensation: null,
      timeline: '24-48 hours'
    };
    
    switch (category) {
      case 'product_not_received':
        resolution = {
          type: 'full_refund',
          description: 'Full refund issued due to undelivered product',
          actions: [
            'Issue full refund to original payment method',
            'Cancel order and update inventory',
            'Send confirmation email to customer'
          ],
          compensation: {
            type: 'refund',
            amount: disputeData.orderValue || 0,
            currency: 'USD'
          },
          timeline: '24 hours'
        };
        break;
        
      case 'damaged_product':
        resolution = {
          type: 'replacement_or_refund',
          description: 'Customer choice of replacement or full refund',
          actions: [
            'Offer customer choice of replacement or refund',
            'Arrange return shipping if refund chosen',
            'Process replacement order if replacement chosen'
          ],
          compensation: {
            type: 'choice',
            options: ['replacement', 'full_refund'],
            amount: disputeData.orderValue || 0
          },
          timeline: '48 hours'
        };
        break;
        
      case 'billing_issue':
        resolution = {
          type: 'billing_correction',
          description: 'Billing error corrected and refund issued',
          actions: [
            'Review billing records',
            'Correct billing error',
            'Issue refund for overcharge',
            'Update payment records'
          ],
          compensation: {
            type: 'refund',
            amount: disputeData.disputedAmount || 0,
            currency: 'USD'
          },
          timeline: '12 hours'
        };
        break;
    }
    
    return resolution;
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  validateDisputeData(disputeData) {
    const required = ['orderId', 'sellerId', 'title', 'description'];
    for (const field of required) {
      if (!disputeData[field]) {
        throw new Error(`Missing required field: ${field}`);
      }
    }
    
    if (disputeData.description.length < 20) {
      throw new Error('Dispute description must be at least 20 characters');
    }
    
    if (disputeData.description.length > 5000) {
      throw new Error('Dispute description must be less than 5000 characters');
    }
  }

  determineSubcategory(category, text) {
    const subcategories = {
      'product_not_received': ['never_shipped', 'lost_in_transit', 'wrong_address'],
      'product_not_as_described': ['wrong_item', 'poor_quality', 'missing_features'],
      'damaged_product': ['shipping_damage', 'manufacturing_defect', 'packaging_issue'],
      'billing_issue': ['overcharged', 'duplicate_charge', 'unauthorized_charge'],
      'seller_communication': ['no_response', 'rude_behavior', 'misleading_info']
    };
    
    const categorySubcategories = subcategories[category] || ['general'];
    return categorySubcategories[0]; // Return first subcategory for demo
  }

  extractKeywords(text) {
    const words = text.toLowerCase().split(/\s+/);
    const stopWords = ['the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'];
    return words.filter(word => word.length > 3 && !stopWords.includes(word)).slice(0, 10);
  }

  calculateDueDate(priority) {
    const hours = priority === 'high' ? 24 : priority === 'medium' ? 48 : 72;
    return new Date(Date.now() + hours * 60 * 60 * 1000).toISOString();
  }

  // Mock database operations
  async getUserDisputeHistory(userId) {
    return {
      totalDisputes: 2,
      resolutionRate: 0.9,
      averageRating: 4.2,
      accountAge: 365, // days
      lastDisputeDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()
    };
  }

  async getSellerDisputeHistory(sellerId) {
    return {
      totalDisputes: 5,
      resolutionRate: 0.85,
      averageRating: 4.0,
      averageResponseTime: 12, // hours
      lastDisputeDate: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()
    };
  }

  async getOrderDetails(orderId) {
    return {
      id: orderId,
      total: 99.99,
      createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
      deliveryStatus: 'delivered',
      paymentMethod: 'credit_card',
      isFirstOrder: false
    };
  }

  calculateRiskFactors(userHistory, sellerHistory, orderDetails) {
    const factors = [];
    
    if (userHistory.totalDisputes > 5) {
      factors.push({ type: 'high_user_disputes', weight: 0.3 });
    }
    
    if (sellerHistory.resolutionRate < 0.8) {
      factors.push({ type: 'low_seller_resolution', weight: 0.4 });
    }
    
    if (orderDetails.orderValue > 500) {
      factors.push({ type: 'high_value_order', weight: 0.2 });
    }
    
    return factors;
  }

  calculateUserRiskLevel(userHistory) {
    if (userHistory.totalDisputes > 10) return 'high';
    if (userHistory.totalDisputes > 3) return 'medium';
    return 'low';
  }

  calculateSellerRiskLevel(sellerHistory) {
    if (sellerHistory.resolutionRate < 0.7) return 'high';
    if (sellerHistory.resolutionRate < 0.9) return 'medium';
    return 'low';
  }

  calculateOrderAge(createdAt) {
    return Math.floor((Date.now() - new Date(createdAt).getTime()) / (24 * 60 * 60 * 1000));
  }

  calculateOverallRiskScore(riskFactors) {
    return riskFactors.reduce((sum, factor) => sum + factor.weight, 0) / Math.max(riskFactors.length, 1);
  }

  getAlternativeResolutions(category) {
    const alternatives = {
      'product_not_received': ['partial_refund', 'store_credit', 'replacement'],
      'product_not_as_described': ['return_refund', 'partial_refund', 'exchange'],
      'damaged_product': ['replacement', 'repair', 'full_refund'],
      'billing_issue': ['refund', 'credit', 'billing_adjustment'],
      'seller_communication': ['mediation', 'seller_training', 'warning']
    };
    
    return alternatives[category] || ['manual_review'];
  }

  estimateResolutionSatisfaction(resolution) {
    const satisfactionRates = {
      'full_refund': 0.9,
      'replacement': 0.85,
      'partial_refund': 0.7,
      'store_credit': 0.6,
      'billing_correction': 0.95
    };
    
    return satisfactionRates[resolution.type] || 0.5;
  }

  // Mock async operations
  async storeDispute(dispute) {
    structuredLogger.logInfo('DISPUTE_STORED', { disputeId: dispute.id });
  }

  async sendDisputeNotifications(dispute) {
    structuredLogger.logInfo('DISPUTE_NOTIFICATIONS_SENT', { disputeId: dispute.id });
  }

  async assignDispute(dispute) {
    structuredLogger.logInfo('DISPUTE_ASSIGNED', { disputeId: dispute.id });
  }

  async executeResolution(dispute) {
    structuredLogger.logInfo('DISPUTE_RESOLUTION_EXECUTED', { disputeId: dispute.id });
  }

  // Utility methods
  generateDisputeId() {
    return `dispute_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  updateDisputeMetrics(dispute) {
    this.disputeMetrics.totalDisputes++;
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
      structuredLogger.logError('DISPUTE_CACHE_ERROR', { error: error.message });
    }
  }
}

module.exports = new DisputeService();