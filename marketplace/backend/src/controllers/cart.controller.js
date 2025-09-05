const BaseController = require('./BaseController');
const cartService = require('../services/cart.service');
const structuredLogger = require('../services/structured-logger.service');
const Joi = require('joi');

class CartController extends BaseController {
  constructor() {
    super('CART');
  }

  /**
   * Obtenir le panier de l'utilisateur
   */
  getCart = this.asyncHandler(async (req, res) => {
    try {
      const userId = req.user.sub;
      const cart = await cartService.getCart(userId);

      res.json({
        success: true,
        data: cart
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Ajouter un produit au panier
   */
  addItem = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      productId: Joi.string().required(),
      variantId: Joi.string().optional(),
      name: Joi.string().required(),
      description: Joi.string().optional(),
      price: Joi.number().positive().precision(2).required(),
      quantity: Joi.number().integer().positive().max(99).required(),
      image: Joi.string().uri().optional(),
      shopId: Joi.string().required(),
      shopName: Joi.string().required(),
      category: Joi.string().optional(),
      attributes: Joi.object().optional()
    });

    const validatedData = this.validateRequest(schema, req.body);
    
    try {
      const userId = req.user.sub;
      const cart = await cartService.addItem(userId, validatedData);

      structuredLogger.logInfo('CART_ITEM_ADDED_SUCCESS', {
        userId,
        productId: validatedData.productId,
        quantity: validatedData.quantity,
        cartTotal: cart.total
      });

      res.json({
        success: true,
        data: cart,
        message: 'Item added to cart successfully'
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Supprimer un produit du panier
   */
  removeItem = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      productId: Joi.string().required(),
      variantId: Joi.string().optional()
    });

    const validatedData = this.validateRequest(schema, req.body);
    
    try {
      const userId = req.user.sub;
      const cart = await cartService.removeItem(
        userId, 
        validatedData.productId, 
        validatedData.variantId
      );

      structuredLogger.logInfo('CART_ITEM_REMOVED_SUCCESS', {
        userId,
        productId: validatedData.productId,
        cartTotal: cart.total
      });

      res.json({
        success: true,
        data: cart,
        message: 'Item removed from cart successfully'
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Mettre à jour la quantité d'un produit
   */
  updateItemQuantity = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      productId: Joi.string().required(),
      variantId: Joi.string().optional(),
      quantity: Joi.number().integer().min(0).max(99).required()
    });

    const validatedData = this.validateRequest(schema, req.body);
    
    try {
      const userId = req.user.sub;
      const cart = await cartService.updateItemQuantity(
        userId,
        validatedData.productId,
        validatedData.variantId,
        validatedData.quantity
      );

      structuredLogger.logInfo('CART_ITEM_QUANTITY_UPDATED', {
        userId,
        productId: validatedData.productId,
        newQuantity: validatedData.quantity,
        cartTotal: cart.total
      });

      res.json({
        success: true,
        data: cart,
        message: 'Item quantity updated successfully'
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Vider le panier
   */
  clearCart = this.asyncHandler(async (req, res) => {
    try {
      const userId = req.user.sub;
      const cart = await cartService.clearCart(userId);

      structuredLogger.logInfo('CART_CLEARED_SUCCESS', {
        userId
      });

      res.json({
        success: true,
        data: cart,
        message: 'Cart cleared successfully'
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Appliquer un code promo
   */
  applyPromoCode = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      promoCode: Joi.string().alphanum().min(3).max(20).required()
    });

    const validatedData = this.validateRequest(schema, req.body);
    
    try {
      const userId = req.user.sub;
      const cart = await cartService.applyPromoCode(userId, validatedData.promoCode);

      structuredLogger.logInfo('PROMO_CODE_APPLIED_SUCCESS', {
        userId,
        promoCode: validatedData.promoCode,
        discount: cart.discount,
        newTotal: cart.total
      });

      res.json({
        success: true,
        data: cart,
        message: 'Promo code applied successfully'
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Supprimer le code promo
   */
  removePromoCode = this.asyncHandler(async (req, res) => {
    try {
      const userId = req.user.sub;
      const cart = await cartService.removePromoCode(userId);

      structuredLogger.logInfo('PROMO_CODE_REMOVED_SUCCESS', {
        userId,
        newTotal: cart.total
      });

      res.json({
        success: true,
        data: cart,
        message: 'Promo code removed successfully'
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Obtenir les statistiques du panier
   */
  getCartStats = this.asyncHandler(async (req, res) => {
    try {
      const userId = req.user.sub;
      const stats = await cartService.getCartStats(userId);

      res.json({
        success: true,
        data: stats
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Synchroniser le panier avec la base de données
   */
  syncCart = this.asyncHandler(async (req, res) => {
    try {
      const userId = req.user.sub;
      const cart = await cartService.syncCartToDatabase(userId);

      structuredLogger.logInfo('CART_SYNCED_SUCCESS', {
        userId,
        itemCount: cart.items.length
      });

      res.json({
        success: true,
        data: cart,
        message: 'Cart synchronized successfully'
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Valider le panier avant checkout
   */
  validateCart = this.asyncHandler(async (req, res) => {
    try {
      const userId = req.user.sub;
      const cart = await cartService.getCart(userId);

      // Validations du panier
      const validationErrors = [];

      if (cart.items.length === 0) {
        validationErrors.push('Cart is empty');
      }

      // Vérifier que tous les produits sont encore disponibles
      // TODO: Implémenter la vérification de stock en temps réel
      
      // Vérifier les prix (protection contre les modifications)
      // TODO: Implémenter la vérification des prix

      const isValid = validationErrors.length === 0;

      structuredLogger.logInfo('CART_VALIDATION', {
        userId,
        isValid,
        errors: validationErrors,
        itemCount: cart.items.length,
        total: cart.total
      });

      res.json({
        success: true,
        data: {
          isValid,
          errors: validationErrors,
          cart: isValid ? cart : null
        }
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });

  /**
   * Créer une commande à partir du panier
   */
  createOrderFromCart = this.asyncHandler(async (req, res) => {
    const schema = Joi.object({
      shippingAddress: Joi.object({
        firstName: Joi.string().required(),
        lastName: Joi.string().required(),
        address: Joi.string().required(),
        city: Joi.string().required(),
        postalCode: Joi.string().required(),
        country: Joi.string().required(),
        phone: Joi.string().optional()
      }).required(),
      billingAddress: Joi.object({
        firstName: Joi.string().required(),
        lastName: Joi.string().required(),
        address: Joi.string().required(),
        city: Joi.string().required(),
        postalCode: Joi.string().required(),
        country: Joi.string().required(),
        phone: Joi.string().optional()
      }).optional(),
      paymentMethod: Joi.string().valid('stripe', 'paypal').default('stripe'),
      notes: Joi.string().max(500).optional()
    });

    const validatedData = this.validateRequest(schema, req.body);
    
    try {
      const userId = req.user.sub;
      const cart = await cartService.getCart(userId);

      if (cart.items.length === 0) {
        return res.status(400).json({
          success: false,
          error: 'Cannot create order from empty cart'
        });
      }

      // TODO: Implémenter la création de commande
      // Pour l'instant, on retourne les données nécessaires pour le paiement
      
      const orderData = {
        userId,
        items: cart.items,
        subtotal: cart.subtotal,
        shipping: cart.shipping,
        tax: cart.tax,
        discount: cart.discount,
        total: cart.total,
        currency: cart.currency,
        shippingAddress: validatedData.shippingAddress,
        billingAddress: validatedData.billingAddress || validatedData.shippingAddress,
        paymentMethod: validatedData.paymentMethod,
        notes: validatedData.notes,
        promoCode: cart.promoCode,
        createdAt: new Date().toISOString()
      };

      structuredLogger.logInfo('ORDER_PREPARED_FROM_CART', {
        userId,
        itemCount: cart.items.length,
        total: cart.total,
        paymentMethod: validatedData.paymentMethod
      });

      res.json({
        success: true,
        data: {
          order: orderData,
          cart: cart
        },
        message: 'Order prepared successfully'
      });
    } catch (error) {
      this.handleError(error, req, res);
    }
  });
}

module.exports = new CartController();