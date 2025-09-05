const BaseController = require('./BaseController');
const stripeService = require('../services/stripe.service');
const structuredLogger = require('../services/structured-logger.service');
const Joi = require('joi');

class PaymentController extends BaseController {
  constructor() {
    super('PAYMENT');
  }

  /**
   * Créer un Payment Intent pour un paiement
   */
  createPaymentIntent = this.asyncHandler(async (req, res) => {
    // Validation des données d'entrée
    const schema = Joi.object({
      amount: Joi.number().positive().precision(2).required(),
      currency: Joi.string().valid('eur', 'usd', 'gbp').default('eur'),
      orderId: Joi.string().required(),
      items: Joi.array().items(Joi.object({
        id: Joi.string().required(),
        name: Joi.string().required(),
        price: Joi.number().positive().required(),
        quantity: Joi.number().integer().positive().required()
      })).required()
    });

    const validatedData = this.validateRequest(schema, req.body);
    
    try {
      // Créer le Payment Intent avec metadata
      const paymentIntent = await stripeService.createPaymentIntent(
        validatedData.amount,
        validatedData.currency,
        {
          orderId: validatedData.orderId,
          userId: req.user?.sub,
          itemCount: validatedData.items.length.toString()
        }
      );

      structuredLogger.logInfo('PAYMENT_INTENT_REQUESTED', {
        userId: req.user?.sub,
        orderId: validatedData.orderId,
        amount: validatedData.amount,
        paymentIntentId: paymentIntent.id
      });

      res.json({
        success: true,
        data: {
          clientSecret: paymentIntent.client_secret,
          paymentIntentId: paymentIntent.id,
          amount: validatedData.amount,
          currency: validatedData.currency
        }
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Créer une session de checkout Stripe
   */
  createCheckoutSession = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      items: Joi.array().items(Joi.object({
        name: Joi.string().required(),
        description: Joi.string().optional(),
        price: Joi.number().positive().required(),
        quantity: Joi.number().integer().positive().required(),
        images: Joi.array().items(Joi.string().uri()).optional()
      })).min(1).required(),
      orderId: Joi.string().required(),
      successUrl: Joi.string().uri().required(),
      cancelUrl: Joi.string().uri().required()
    });

    const validatedData = this.validateRequest(schema, req.body);

    try {
      const session = await stripeService.createCheckoutSession(
        validatedData.items,
        validatedData.successUrl,
        validatedData.cancelUrl,
        {
          orderId: validatedData.orderId,
          userId: req.user?.sub
        }
      );

      structuredLogger.logInfo('CHECKOUT_SESSION_CREATED', {
        userId: req.user?.sub,
        orderId: validatedData.orderId,
        sessionId: session.id,
        itemCount: validatedData.items.length
      });

      res.json({
        success: true,
        data: {
          sessionId: session.id,
          url: session.url
        }
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Webhook Stripe pour traiter les événements
   */
  handleWebhook = this.asyncHandler(async (req, res) => {
    const signature = req.headers['stripe-signature'];
    
    if (!signature) {
      return res.status(400).json({
        success: false,
        error: 'Missing stripe-signature header'
      });
    }

    try {
      // Vérifier la signature du webhook
      const event = await stripeService.verifyWebhook(req.body, signature);
      
      // Traiter l'événement
      await stripeService.handleWebhookEvent(event);

      structuredLogger.logInfo('WEBHOOK_PROCESSED', {
        eventId: event.id,
        eventType: event.type
      });

      res.json({ received: true });
    } catch (error) {
      structuredLogger.logError('WEBHOOK_ERROR', {
        error: error.message,
        signature: signature?.substring(0, 20) + '...'
      });
      
      res.status(400).json({
        success: false,
        error: 'Webhook signature verification failed'
      });
    }
  });

  /**
   * Créer un compte connecté pour un vendeur
   */
  createSellerAccount = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      email: Joi.string().email().required(),
      country: Joi.string().length(2).uppercase().default('FR'),
      sellerId: Joi.string().required(),
      shopId: Joi.string().required(),
      returnUrl: Joi.string().uri().required(),
      refreshUrl: Joi.string().uri().required()
    });

    const validatedData = this.validateRequest(schema, req.body);

    try {
      // Créer le compte connecté
      const account = await stripeService.createConnectedAccount({
        email: validatedData.email,
        country: validatedData.country,
        sellerId: validatedData.sellerId,
        shopId: validatedData.shopId
      });

      // Créer le lien d'onboarding
      const accountLink = await stripeService.createAccountLink(
        account.id,
        validatedData.returnUrl,
        validatedData.refreshUrl
      );

      structuredLogger.logInfo('SELLER_ACCOUNT_CREATED', {
        userId: req.user?.sub,
        sellerId: validatedData.sellerId,
        accountId: account.id
      });

      res.json({
        success: true,
        data: {
          accountId: account.id,
          onboardingUrl: accountLink.url
        }
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Créer un transfert vers un vendeur
   */
  createTransfer = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      amount: Joi.number().positive().precision(2).required(),
      destinationAccountId: Joi.string().required(),
      orderId: Joi.string().required(),
      description: Joi.string().optional()
    });

    const validatedData = this.validateRequest(schema, req.body);

    try {
      // Calculer les frais marketplace
      const feeCalculation = stripeService.calculateMarketplaceFee(validatedData.amount);
      
      // Créer le transfert pour le montant vendeur
      const transfer = await stripeService.createTransfer(
        feeCalculation.sellerAmount,
        validatedData.destinationAccountId,
        {
          orderId: validatedData.orderId,
          originalAmount: validatedData.amount.toString(),
          marketplaceFee: feeCalculation.marketplaceFee.toString(),
          description: validatedData.description
        }
      );

      structuredLogger.logInfo('TRANSFER_INITIATED', {
        userId: req.user?.sub,
        orderId: validatedData.orderId,
        transferId: transfer.id,
        sellerAmount: feeCalculation.sellerAmount,
        marketplaceFee: feeCalculation.marketplaceFee
      });

      res.json({
        success: true,
        data: {
          transferId: transfer.id,
          ...feeCalculation
        }
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Créer un remboursement
   */
  createRefund = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      paymentIntentId: Joi.string().required(),
      amount: Joi.number().positive().precision(2).optional(),
      reason: Joi.string().valid(
        'duplicate',
        'fraudulent',
        'requested_by_customer'
      ).default('requested_by_customer')
    });

    const validatedData = this.validateRequest(schema, req.body);

    try {
      const refund = await stripeService.createRefund(
        validatedData.paymentIntentId,
        validatedData.amount,
        validatedData.reason
      );

      structuredLogger.logInfo('REFUND_CREATED', {
        userId: req.user?.sub,
        paymentIntentId: validatedData.paymentIntentId,
        refundId: refund.id,
        amount: refund.amount / 100,
        reason: validatedData.reason
      });

      res.json({
        success: true,
        data: {
          refundId: refund.id,
          amount: refund.amount / 100,
          status: refund.status,
          reason: refund.reason
        }
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Obtenir le solde d'un compte vendeur
   */
  getAccountBalance = this.asyncHandler(async (req, res) => {
    const { accountId } = req.params;

    if (!accountId) {
      return res.status(400).json({
        success: false,
        error: 'Account ID is required'
      });
    }

    try {
      const balance = await stripeService.getAccountBalance(accountId);

      res.json({
        success: true,
        data: balance
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Calculer les frais marketplace
   */
  calculateFees = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      amount: Joi.number().positive().precision(2).required(),
      feePercentage: Joi.number().min(0).max(10).default(3)
    });

    const validatedData = this.validateRequest(schema, req.body);

    try {
      const calculation = stripeService.calculateMarketplaceFee(
        validatedData.amount,
        validatedData.feePercentage
      );

      res.json({
        success: true,
        data: calculation
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Obtenir le statut d'un paiement
   */
  getPaymentStatus = this.asyncHandler(async (req, res) => {
    const { paymentIntentId } = req.params;

    if (!paymentIntentId) {
      return res.status(400).json({
        success: false,
        error: 'Payment Intent ID is required'
      });
    }

    try {
      const paymentIntent = await stripeService.stripe.paymentIntents.retrieve(paymentIntentId);

      res.json({
        success: true,
        data: {
          id: paymentIntent.id,
          status: paymentIntent.status,
          amount: paymentIntent.amount / 100,
          currency: paymentIntent.currency,
          created: new Date(paymentIntent.created * 1000),
          metadata: paymentIntent.metadata
        }
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });
}

module.exports = new PaymentController();