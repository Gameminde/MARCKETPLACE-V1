const BaseController = require('./BaseController');
const disputeService = require('../services/dispute.service');
const structuredLogger = require('../services/structured-logger.service');
const Joi = require('joi');

class DisputeController extends BaseController {
  constructor() {
    super('DISPUTE');
  }

  /**
   * Create a new dispute with AI-powered assessment
   */
  createDispute = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      orderId: Joi.string().required(),
      productId: Joi.string().optional(),
      sellerId: Joi.string().required(),
      shopId: Joi.string().required(),
      title: Joi.string().min(10).max(200).required(),
      description: Joi.string().min(20).max(5000).required(),
      evidence: Joi.array().items(Joi.object({
        type: Joi.string().valid('image', 'video', 'document', 'screenshot').required(),
        url: Joi.string().uri().required(),
        description: Joi.string().max(500).optional()
      })).max(10).default([]),
      orderValue: Joi.number().min(0).optional(),
      disputedAmount: Joi.number().min(0).optional()
    });

    const validatedData = this.validateRequest(schema, req.body);

    try {
      const dispute = await disputeService.createDispute(validatedData, req.user.sub);

      structuredLogger.logInfo('DISPUTE_CREATED_SUCCESS', {
        userId: req.user.sub,
        disputeId: dispute.id,
        orderId: validatedData.orderId,
        category: dispute.category,
        autoResolved: dispute.status === 'auto_resolved'
      });

      const message = dispute.status === 'auto_resolved' 
        ? 'Dispute created and automatically resolved'
        : 'Dispute created successfully and assigned for review';

      res.status(201).json({
        success: true,
        data: dispute,
        message
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Get dispute details
   */
  getDispute = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      disputeId: Joi.string().required()
    });

    const validatedData = this.validateRequest(schema, req.params);

    try {
      const dispute = await disputeService.getDispute(validatedData.disputeId, req.user.sub);

      res.json({
        success: true,
        data: dispute
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Get user's disputes
   */
  getUserDisputes = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      page: Joi.number().integer().min(1).default(1),
      limit: Joi.number().integer().min(1).max(100).default(20),
      status: Joi.string().valid('open', 'in_progress', 'resolved', 'closed', 'auto_resolved').optional(),
      category: Joi.string().optional(),
      sort: Joi.string().valid('newest', 'oldest', 'priority', 'status').default('newest')
    });

    const validatedData = this.validateRequest(schema, req.query);

    try {
      // Mock user disputes
      const disputes = {
        disputes: [
          {
            id: 'dispute_1',
            orderId: 'order_123',
            title: 'Product never arrived',
            category: 'product_not_received',
            status: 'resolved',
            priority: 'high',
            createdAt: new Date(Date.now() - 86400000).toISOString(),
            resolvedAt: new Date(Date.now() - 43200000).toISOString(),
            resolution: {
              type: 'full_refund',
              description: 'Full refund issued due to undelivered product'
            }
          },
          {
            id: 'dispute_2',
            orderId: 'order_456',
            title: 'Item damaged during shipping',
            category: 'damaged_product',
            status: 'in_progress',
            priority: 'medium',
            createdAt: new Date(Date.now() - 172800000).toISOString(),
            estimatedResolution: new Date(Date.now() + 86400000).toISOString()
          }
        ],
        pagination: {
          page: validatedData.page,
          limit: validatedData.limit,
          total: 2,
          hasMore: false
        },
        stats: {
          totalDisputes: 2,
          openDisputes: 1,
          resolvedDisputes: 1,
          averageResolutionTime: 36 // hours
        }
      };

      res.json({
        success: true,
        data: disputes
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Add message to dispute
   */
  addDisputeMessage = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      disputeId: Joi.string().required(),
      message: Joi.string().min(10).max(2000).required(),
      attachments: Joi.array().items(Joi.object({
        type: Joi.string().valid('image', 'document').required(),
        url: Joi.string().uri().required(),
        name: Joi.string().required()
      })).max(5).default([])
    });

    const validatedData = this.validateRequest(schema, {
      ...req.params,
      ...req.body
    });

    try {
      // Mock message addition
      const messageId = `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

      structuredLogger.logInfo('DISPUTE_MESSAGE_ADDED', {
        disputeId: validatedData.disputeId,
        messageId,
        userId: req.user.sub,
        hasAttachments: validatedData.attachments.length > 0
      });

      res.status(201).json({
        success: true,
        data: {
          messageId,
          disputeId: validatedData.disputeId,
          message: validatedData.message,
          attachments: validatedData.attachments,
          sentBy: req.user.sub,
          sentAt: new Date().toISOString()
        },
        message: 'Message added to dispute successfully'
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Accept dispute resolution
   */
  acceptResolution = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      disputeId: Joi.string().required(),
      satisfactionRating: Joi.number().integer().min(1).max(5).optional(),
      feedback: Joi.string().max(1000).optional()
    });

    const validatedData = this.validateRequest(schema, {
      ...req.params,
      ...req.body
    });

    try {
      structuredLogger.logInfo('DISPUTE_RESOLUTION_ACCEPTED', {
        disputeId: validatedData.disputeId,
        userId: req.user.sub,
        satisfactionRating: validatedData.satisfactionRating
      });

      res.json({
        success: true,
        data: {
          disputeId: validatedData.disputeId,
          status: 'closed',
          acceptedBy: req.user.sub,
          acceptedAt: new Date().toISOString(),
          satisfactionRating: validatedData.satisfactionRating,
          feedback: validatedData.feedback
        },
        message: 'Resolution accepted successfully'
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Reject dispute resolution
   */
  rejectResolution = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      disputeId: Joi.string().required(),
      reason: Joi.string().min(20).max(1000).required()
    });

    const validatedData = this.validateRequest(schema, {
      ...req.params,
      ...req.body
    });

    try {
      structuredLogger.logInfo('DISPUTE_RESOLUTION_REJECTED', {
        disputeId: validatedData.disputeId,
        userId: req.user.sub,
        reason: validatedData.reason
      });

      res.json({
        success: true,
        data: {
          disputeId: validatedData.disputeId,
          status: 'escalated',
          rejectedBy: req.user.sub,
          rejectedAt: new Date().toISOString(),
          reason: validatedData.reason,
          nextStep: 'Human mediator will review the case'
        },
        message: 'Resolution rejected. Case escalated to human mediator.'
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Get dispute analytics (for sellers and admins)
   */
  getDisputeAnalytics = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      timeframe: Joi.string().valid('7d', '30d', '90d', '1y').default('30d'),
      shopId: Joi.string().optional(),
      sellerId: Joi.string().optional()
    });

    const validatedData = this.validateRequest(schema, req.query);

    try {
      // Mock analytics data
      const analytics = {
        totalDisputes: 45,
        resolvedDisputes: 38,
        resolutionRate: 84.4,
        averageResolutionTime: 42, // hours
        autoResolutionRate: 68.9,
        satisfactionScore: 4.2,
        categoryBreakdown: {
          'product_not_received': 18,
          'damaged_product': 12,
          'product_not_as_described': 8,
          'billing_issue': 5,
          'seller_communication': 2
        },
        resolutionTypes: {
          'full_refund': 20,
          'partial_refund': 8,
          'replacement': 6,
          'store_credit': 3,
          'no_action': 1
        },
        trends: {
          disputesOverTime: [
            { date: '2024-12-01', count: 3, resolved: 2, avgTime: 38 },
            { date: '2024-12-02', count: 2, resolved: 2, avgTime: 45 },
            { date: '2024-12-03', count: 4, resolved: 3, avgTime: 40 }
          ]
        },
        aiPerformance: {
          accuracy: 94.2,
          autoResolutionSuccess: 91.8,
          predictionConfidence: 87.5,
          falsePositives: 2.1,
          falseNegatives: 3.7
        },
        topIssues: [
          { issue: 'Delayed shipping', count: 15, trend: 'increasing' },
          { issue: 'Product quality', count: 12, trend: 'stable' },
          { issue: 'Wrong item sent', count: 8, trend: 'decreasing' }
        ]
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
   * Get dispute queue for mediators (admin only)
   */
  getDisputeQueue = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      page: Joi.number().integer().min(1).default(1),
      limit: Joi.number().integer().min(1).max(100).default(20),
      priority: Joi.string().valid('high', 'medium', 'low').optional(),
      category: Joi.string().optional(),
      assignedTo: Joi.string().optional(),
      status: Joi.string().valid('open', 'in_progress', 'escalated').optional()
    });

    const validatedData = this.validateRequest(schema, req.query);

    try {
      // Mock dispute queue
      const queue = {
        disputes: [
          {
            id: 'dispute_queue_1',
            orderId: 'order_789',
            title: 'Seller not responding to messages',
            category: 'seller_communication',
            priority: 'medium',
            status: 'open',
            userId: 'user_123',
            sellerId: 'seller_456',
            createdAt: new Date(Date.now() - 3600000).toISOString(),
            dueDate: new Date(Date.now() + 68400000).toISOString(),
            aiPrediction: {
              suggestedResolution: 'mediation',
              confidence: 0.78
            }
          }
        ],
        pagination: {
          page: validatedData.page,
          limit: validatedData.limit,
          total: 1,
          hasMore: false
        },
        stats: {
          totalInQueue: 1,
          highPriority: 0,
          mediumPriority: 1,
          lowPriority: 0,
          overdue: 0,
          averageWaitTime: 2.5 // hours
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
   * Assign dispute to mediator (admin only)
   */
  assignDispute = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      disputeId: Joi.string().required(),
      mediatorId: Joi.string().required(),
      priority: Joi.string().valid('high', 'medium', 'low').optional(),
      notes: Joi.string().max(1000).optional()
    });

    const validatedData = this.validateRequest(schema, {
      ...req.params,
      ...req.body
    });

    try {
      structuredLogger.logInfo('DISPUTE_ASSIGNED', {
        disputeId: validatedData.disputeId,
        mediatorId: validatedData.mediatorId,
        assignedBy: req.user.sub,
        priority: validatedData.priority
      });

      res.json({
        success: true,
        data: {
          disputeId: validatedData.disputeId,
          assignedTo: validatedData.mediatorId,
          assignedBy: req.user.sub,
          assignedAt: new Date().toISOString(),
          priority: validatedData.priority,
          notes: validatedData.notes,
          status: 'in_progress'
        },
        message: 'Dispute assigned successfully'
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Resolve dispute (mediator/admin only)
   */
  resolveDispute = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      disputeId: Joi.string().required(),
      resolutionType: Joi.string().valid(
        'full_refund',
        'partial_refund',
        'replacement',
        'store_credit',
        'no_action',
        'custom'
      ).required(),
      description: Joi.string().min(20).max(2000).required(),
      compensationAmount: Joi.number().min(0).optional(),
      actions: Joi.array().items(Joi.string()).optional(),
      timeline: Joi.string().optional(),
      notes: Joi.string().max(1000).optional()
    });

    const validatedData = this.validateRequest(schema, {
      ...req.params,
      ...req.body
    });

    try {
      structuredLogger.logInfo('DISPUTE_RESOLVED_BY_MEDIATOR', {
        disputeId: validatedData.disputeId,
        resolutionType: validatedData.resolutionType,
        resolvedBy: req.user.sub,
        compensationAmount: validatedData.compensationAmount
      });

      res.json({
        success: true,
        data: {
          disputeId: validatedData.disputeId,
          status: 'resolved',
          resolution: {
            type: validatedData.resolutionType,
            description: validatedData.description,
            compensationAmount: validatedData.compensationAmount,
            actions: validatedData.actions || [],
            timeline: validatedData.timeline || '24-48 hours'
          },
          resolvedBy: req.user.sub,
          resolvedAt: new Date().toISOString(),
          notes: validatedData.notes
        },
        message: 'Dispute resolved successfully'
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Get dispute resolution templates (for mediators)
   */
  getResolutionTemplates = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      category: Joi.string().optional(),
      resolutionType: Joi.string().optional()
    });

    const validatedData = this.validateRequest(schema, req.query);

    try {
      // Mock resolution templates
      const templates = [
        {
          id: 'template_1',
          category: 'product_not_received',
          resolutionType: 'full_refund',
          title: 'Full Refund - Product Not Received',
          description: 'Issue full refund due to undelivered product after tracking confirmation',
          actions: [
            'Verify tracking information',
            'Confirm non-delivery with carrier',
            'Process full refund to original payment method',
            'Send confirmation email to customer'
          ],
          timeline: '24 hours',
          compensationRange: { min: 0, max: 1000 },
          satisfactionRate: 0.92
        },
        {
          id: 'template_2',
          category: 'damaged_product',
          resolutionType: 'replacement',
          title: 'Product Replacement - Shipping Damage',
          description: 'Offer replacement product for items damaged during shipping',
          actions: [
            'Review damage evidence',
            'Arrange return shipping label',
            'Process replacement order',
            'Expedite shipping for replacement'
          ],
          timeline: '48-72 hours',
          compensationRange: { min: 0, max: 500 },
          satisfactionRate: 0.88
        }
      ];

      // Filter templates if category or resolutionType specified
      let filteredTemplates = templates;
      if (validatedData.category) {
        filteredTemplates = filteredTemplates.filter(t => t.category === validatedData.category);
      }
      if (validatedData.resolutionType) {
        filteredTemplates = filteredTemplates.filter(t => t.resolutionType === validatedData.resolutionType);
      }

      res.json({
        success: true,
        data: {
          templates: filteredTemplates,
          totalTemplates: filteredTemplates.length
        }
      });

    } catch (error) {
      this.handleError(error, req, res);
    }
  });
}

module.exports = new DisputeController();