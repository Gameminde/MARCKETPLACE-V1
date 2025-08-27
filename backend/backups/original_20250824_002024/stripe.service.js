const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const loggerService = require('./logger.service');
const structuredLogger = require('./structured-logger.service');

class StripeService {
  constructor() {
    if (!process.env.STRIPE_SECRET_KEY) {
      throw new Error('STRIPE_SECRET_KEY is required');
    }
    this.stripe = stripe;
  }

  /**
   * Créer un Payment Intent sécurisé
   */
  async createPaymentIntent(amount, currency = 'eur', metadata = {}) {
    try {
      // Validation des entrées
      if (!amount || amount <= 0) {
        throw new Error('Invalid amount');
      }

      const paymentIntent = await this.stripe.paymentIntents.create({
        amount: Math.round(amount * 100), // Convertir en centimes
        currency,
        metadata: {
          ...metadata,
          timestamp: new Date().toISOString()
        },
        payment_method_types: ['card'],
        capture_method: 'automatic',
        confirmation_method: 'automatic',
        statement_descriptor: 'MARKETPLACE',
        statement_descriptor_suffix: 'PURCHASE'
      });

      structuredLogger.logInfo('PAYMENT_INTENT_CREATED', {
        paymentIntentId: paymentIntent.id,
        amount,
        currency,
        metadata
      });

      return paymentIntent;
    } catch (error) {
      structuredLogger.logError('PAYMENT_INTENT_ERROR', {
        error: error.message,
        amount,
        currency
      });
      throw new Error(`Payment intent creation failed: ${error.message}`);
    }
  }

  /**
   * Créer un compte connecté Stripe pour les vendeurs
   */
  async createConnectedAccount(sellerData) {
    try {
      const account = await this.stripe.accounts.create({
        type: 'express',
        country: sellerData.country || 'FR',
        email: sellerData.email,
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true }
        },
        business_type: 'individual',
        metadata: {
          sellerId: sellerData.sellerId,
          shopId: sellerData.shopId
        }
      });

      structuredLogger.logInfo('STRIPE_ACCOUNT_CREATED', {
        accountId: account.id,
        sellerId: sellerData.sellerId
      });

      return account;
    } catch (error) {
      structuredLogger.logError('STRIPE_ACCOUNT_ERROR', {
        error: error.message,
        sellerData
      });
      throw new Error(`Connected account creation failed: ${error.message}`);
    }
  }

  /**
   * Créer un lien d'onboarding pour le vendeur
   */
  async createAccountLink(accountId, returnUrl, refreshUrl) {
    try {
      const accountLink = await this.stripe.accountLinks.create({
        account: accountId,
        refresh_url: refreshUrl,
        return_url: returnUrl,
        type: 'account_onboarding'
      });

      return accountLink;
    } catch (error) {
      throw new Error(`Account link creation failed: ${error.message}`);
    }
  }

  /**
   * Transférer des fonds vers un compte connecté
   */
  async createTransfer(amount, destinationAccountId, metadata = {}) {
    try {
      const transfer = await this.stripe.transfers.create({
        amount: Math.round(amount * 100),
        currency: 'eur',
        destination: destinationAccountId,
        metadata: {
          ...metadata,
          timestamp: new Date().toISOString()
        }
      });

      structuredLogger.logInfo('TRANSFER_CREATED', {
        transferId: transfer.id,
        amount,
        destination: destinationAccountId
      });

      return transfer;
    } catch (error) {
      structuredLogger.logError('TRANSFER_ERROR', {
        error: error.message,
        amount,
        destination: destinationAccountId
      });
      throw new Error(`Transfer failed: ${error.message}`);
    }
  }

  /**
   * Calculer la commission marketplace
   */
  calculateMarketplaceFee(amount, feePercentage = 3) {
    const fee = amount * (feePercentage / 100);
    const sellerAmount = amount - fee;
    
    return {
      totalAmount: amount,
      marketplaceFee: Math.round(fee * 100) / 100,
      sellerAmount: Math.round(sellerAmount * 100) / 100,
      feePercentage
    };
  }

  /**
   * Vérifier la signature du webhook Stripe
   */
  async verifyWebhook(payload, signature) {
    try {
      if (!process.env.STRIPE_WEBHOOK_SECRET) {
        throw new Error('STRIPE_WEBHOOK_SECRET is required');
      }

      const event = this.stripe.webhooks.constructEvent(
        payload,
        signature,
        process.env.STRIPE_WEBHOOK_SECRET
      );

      structuredLogger.logInfo('WEBHOOK_VERIFIED', {
        eventId: event.id,
        type: event.type
      });

      return event;
    } catch (error) {
      structuredLogger.logError('WEBHOOK_VERIFICATION_FAILED', {
        error: error.message
      });
      throw new Error('Invalid webhook signature');
    }
  }

  /**
   * Traiter les événements webhook
   */
  async handleWebhookEvent(event) {
    try {
      switch (event.type) {
        case 'payment_intent.succeeded':
          await this.handlePaymentSuccess(event.data.object);
          break;
        
        case 'payment_intent.payment_failed':
          await this.handlePaymentFailure(event.data.object);
          break;
        
        case 'account.updated':
          await this.handleAccountUpdate(event.data.object);
          break;
        
        case 'transfer.created':
          await this.handleTransferCreated(event.data.object);
          break;
        
        default:
          loggerService.info(`Unhandled webhook event: ${event.type}`);
      }
    } catch (error) {
      structuredLogger.logError('WEBHOOK_PROCESSING_ERROR', {
        eventType: event.type,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Gérer le succès d'un paiement
   */
  async handlePaymentSuccess(paymentIntent) {
    structuredLogger.logInfo('PAYMENT_SUCCESS', {
      paymentIntentId: paymentIntent.id,
      amount: paymentIntent.amount / 100,
      metadata: paymentIntent.metadata
    });

    // TODO: Mettre à jour la commande en base de données
    // TODO: Envoyer email de confirmation
    // TODO: Déclencher le transfert vers le vendeur
  }

  /**
   * Gérer l'échec d'un paiement
   */
  async handlePaymentFailure(paymentIntent) {
    structuredLogger.logError('PAYMENT_FAILED', {
      paymentIntentId: paymentIntent.id,
      amount: paymentIntent.amount / 100,
      error: paymentIntent.last_payment_error?.message
    });

    // TODO: Notifier le client
    // TODO: Mettre à jour le statut de la commande
  }

  /**
   * Gérer la mise à jour d'un compte connecté
   */
  async handleAccountUpdate(account) {
    structuredLogger.logInfo('ACCOUNT_UPDATED', {
      accountId: account.id,
      chargesEnabled: account.charges_enabled,
      payoutsEnabled: account.payouts_enabled
    });

    // TODO: Mettre à jour le statut du vendeur
  }

  /**
   * Gérer la création d'un transfert
   */
  async handleTransferCreated(transfer) {
    structuredLogger.logInfo('TRANSFER_COMPLETED', {
      transferId: transfer.id,
      amount: transfer.amount / 100,
      destination: transfer.destination
    });

    // TODO: Mettre à jour les stats du vendeur
  }

  /**
   * Créer une session de checkout
   */
  async createCheckoutSession(items, successUrl, cancelUrl, metadata = {}) {
    try {
      const session = await this.stripe.checkout.sessions.create({
        payment_method_types: ['card'],
        line_items: items.map(item => ({
          price_data: {
            currency: 'eur',
            product_data: {
              name: item.name,
              description: item.description,
              images: item.images || []
            },
            unit_amount: Math.round(item.price * 100)
          },
          quantity: item.quantity
        })),
        mode: 'payment',
        success_url: successUrl,
        cancel_url: cancelUrl,
        metadata: {
          ...metadata,
          timestamp: new Date().toISOString()
        },
        payment_intent_data: {
          metadata: metadata
        }
      });

      structuredLogger.logInfo('CHECKOUT_SESSION_CREATED', {
        sessionId: session.id,
        items: items.length,
        metadata
      });

      return session;
    } catch (error) {
      structuredLogger.logError('CHECKOUT_SESSION_ERROR', {
        error: error.message,
        items
      });
      throw new Error(`Checkout session creation failed: ${error.message}`);
    }
  }

  /**
   * Récupérer le solde d'un compte connecté
   */
  async getAccountBalance(accountId) {
    try {
      const balance = await this.stripe.balance.retrieve({
        stripeAccount: accountId
      });

      return {
        available: balance.available.map(b => ({
          amount: b.amount / 100,
          currency: b.currency
        })),
        pending: balance.pending.map(b => ({
          amount: b.amount / 100,
          currency: b.currency
        }))
      };
    } catch (error) {
      throw new Error(`Balance retrieval failed: ${error.message}`);
    }
  }

  /**
   * Créer un remboursement
   */
  async createRefund(paymentIntentId, amount = null, reason = 'requested_by_customer') {
    try {
      const refundData = {
        payment_intent: paymentIntentId,
        reason
      };

      if (amount) {
        refundData.amount = Math.round(amount * 100);
      }

      const refund = await this.stripe.refunds.create(refundData);

      structuredLogger.logInfo('REFUND_CREATED', {
        refundId: refund.id,
        paymentIntentId,
        amount: refund.amount / 100,
        reason
      });

      return refund;
    } catch (error) {
      structuredLogger.logError('REFUND_ERROR', {
        error: error.message,
        paymentIntentId,
        amount
      });
      throw new Error(`Refund creation failed: ${error.message}`);
    }
  }
}

module.exports = new StripeService();