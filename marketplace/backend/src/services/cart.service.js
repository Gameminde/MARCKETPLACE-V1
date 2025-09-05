const redisService = require('./redis.service');
const structuredLogger = require('./structured-logger.service');

class CartService {
  constructor() {
    this.CART_PREFIX = 'cart:';
    this.CART_EXPIRY = 7 * 24 * 60 * 60; // 7 days in seconds
  }

  /**
   * Générer la clé Redis pour le panier d'un utilisateur
   */
  getCartKey(userId) {
    return `${this.CART_PREFIX}${userId}`;
  }

  /**
   * Ajouter un produit au panier
   */
  async addItem(userId, item) {
    try {
      // Validation de l'item
      this.validateCartItem(item);

      const cartKey = this.getCartKey(userId);
      const cart = await this.getCart(userId);
      
      // Vérifier si l'item existe déjà
      const existingItemIndex = cart.items.findIndex(
        cartItem => cartItem.productId === item.productId && 
                   cartItem.variantId === item.variantId
      );

      if (existingItemIndex >= 0) {
        // Mettre à jour la quantité
        cart.items[existingItemIndex].quantity += item.quantity;
        cart.items[existingItemIndex].updatedAt = new Date().toISOString();
      } else {
        // Ajouter nouvel item
        cart.items.push({
          ...item,
          addedAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        });
      }

      // Recalculer les totaux
      this.calculateCartTotals(cart);
      cart.updatedAt = new Date().toISOString();

      // Sauvegarder dans Redis
      await redisService.setex(cartKey, this.CART_EXPIRY, JSON.stringify(cart));

      structuredLogger.logInfo('CART_ITEM_ADDED', {
        userId,
        productId: item.productId,
        quantity: item.quantity,
        cartTotal: cart.total
      });

      return cart;
    } catch (error) {
      structuredLogger.logError('CART_ADD_ITEM_ERROR', {
        userId,
        error: error.message,
        item
      });
      throw error;
    }
  }

  /**
   * Supprimer un produit du panier
   */
  async removeItem(userId, productId, variantId = null) {
    try {
      const cartKey = this.getCartKey(userId);
      const cart = await this.getCart(userId);

      // Filtrer l'item à supprimer
      const initialLength = cart.items.length;
      cart.items = cart.items.filter(
        item => !(item.productId === productId && item.variantId === variantId)
      );

      if (cart.items.length === initialLength) {
        throw new Error('Item not found in cart');
      }

      // Recalculer les totaux
      this.calculateCartTotals(cart);
      cart.updatedAt = new Date().toISOString();

      // Sauvegarder dans Redis
      await redisService.setex(cartKey, this.CART_EXPIRY, JSON.stringify(cart));

      structuredLogger.logInfo('CART_ITEM_REMOVED', {
        userId,
        productId,
        variantId,
        cartTotal: cart.total
      });

      return cart;
    } catch (error) {
      structuredLogger.logError('CART_REMOVE_ITEM_ERROR', {
        userId,
        error: error.message,
        productId,
        variantId
      });
      throw error;
    }
  }

  /**
   * Mettre à jour la quantité d'un produit
   */
  async updateItemQuantity(userId, productId, variantId, quantity) {
    try {
      if (quantity <= 0) {
        return await this.removeItem(userId, productId, variantId);
      }

      const cartKey = this.getCartKey(userId);
      const cart = await this.getCart(userId);

      // Trouver l'item à mettre à jour
      const itemIndex = cart.items.findIndex(
        item => item.productId === productId && item.variantId === variantId
      );

      if (itemIndex === -1) {
        throw new Error('Item not found in cart');
      }

      // Mettre à jour la quantité
      cart.items[itemIndex].quantity = quantity;
      cart.items[itemIndex].updatedAt = new Date().toISOString();

      // Recalculer les totaux
      this.calculateCartTotals(cart);
      cart.updatedAt = new Date().toISOString();

      // Sauvegarder dans Redis
      await redisService.setex(cartKey, this.CART_EXPIRY, JSON.stringify(cart));

      structuredLogger.logInfo('CART_ITEM_UPDATED', {
        userId,
        productId,
        variantId,
        newQuantity: quantity,
        cartTotal: cart.total
      });

      return cart;
    } catch (error) {
      structuredLogger.logError('CART_UPDATE_ITEM_ERROR', {
        userId,
        error: error.message,
        productId,
        variantId,
        quantity
      });
      throw error;
    }
  }

  /**
   * Obtenir le panier d'un utilisateur
   */
  async getCart(userId) {
    try {
      const cartKey = this.getCartKey(userId);
      const cartData = await redisService.get(cartKey);

      if (!cartData) {
        // Créer un nouveau panier vide
        const newCart = this.createEmptyCart(userId);
        await redisService.setex(cartKey, this.CART_EXPIRY, JSON.stringify(newCart));
        return newCart;
      }

      const cart = JSON.parse(cartData);
      
      // Vérifier et nettoyer les items expirés
      const now = new Date();
      const validItems = cart.items.filter(item => {
        const addedAt = new Date(item.addedAt);
        const daysSinceAdded = (now - addedAt) / (1000 * 60 * 60 * 24);
        return daysSinceAdded <= 7; // Garder les items pendant 7 jours max
      });

      if (validItems.length !== cart.items.length) {
        cart.items = validItems;
        this.calculateCartTotals(cart);
        await redisService.setex(cartKey, this.CART_EXPIRY, JSON.stringify(cart));
      }

      return cart;
    } catch (error) {
      structuredLogger.logError('CART_GET_ERROR', {
        userId,
        error: error.message
      });
      
      // En cas d'erreur, retourner un panier vide
      return this.createEmptyCart(userId);
    }
  }

  /**
   * Vider le panier
   */
  async clearCart(userId) {
    try {
      const cartKey = this.getCartKey(userId);
      const emptyCart = this.createEmptyCart(userId);
      
      await redisService.setex(cartKey, this.CART_EXPIRY, JSON.stringify(emptyCart));

      structuredLogger.logInfo('CART_CLEARED', { userId });

      return emptyCart;
    } catch (error) {
      structuredLogger.logError('CART_CLEAR_ERROR', {
        userId,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Appliquer un code promo
   */
  async applyPromoCode(userId, promoCode) {
    try {
      const cart = await this.getCart(userId);
      
      // TODO: Implémenter la logique de validation des codes promo
      // Pour l'instant, codes promo hardcodés pour demo
      const promoCodes = {
        'WELCOME10': { type: 'percentage', value: 10, description: 'Welcome 10% off' },
        'SAVE5': { type: 'fixed', value: 5, description: '5€ off' },
        'FREESHIP': { type: 'shipping', value: 0, description: 'Free shipping' }
      };

      const promo = promoCodes[promoCode.toUpperCase()];
      if (!promo) {
        throw new Error('Invalid promo code');
      }

      cart.promoCode = {
        code: promoCode.toUpperCase(),
        ...promo,
        appliedAt: new Date().toISOString()
      };

      // Recalculer les totaux avec la promo
      this.calculateCartTotals(cart);
      cart.updatedAt = new Date().toISOString();

      const cartKey = this.getCartKey(userId);
      await redisService.setex(cartKey, this.CART_EXPIRY, JSON.stringify(cart));

      structuredLogger.logInfo('PROMO_CODE_APPLIED', {
        userId,
        promoCode: promoCode.toUpperCase(),
        discount: cart.discount,
        newTotal: cart.total
      });

      return cart;
    } catch (error) {
      structuredLogger.logError('PROMO_CODE_ERROR', {
        userId,
        promoCode,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Supprimer le code promo
   */
  async removePromoCode(userId) {
    try {
      const cart = await this.getCart(userId);
      
      delete cart.promoCode;
      this.calculateCartTotals(cart);
      cart.updatedAt = new Date().toISOString();

      const cartKey = this.getCartKey(userId);
      await redisService.setex(cartKey, this.CART_EXPIRY, JSON.stringify(cart));

      structuredLogger.logInfo('PROMO_CODE_REMOVED', {
        userId,
        newTotal: cart.total
      });

      return cart;
    } catch (error) {
      structuredLogger.logError('PROMO_CODE_REMOVE_ERROR', {
        userId,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Créer un panier vide
   */
  createEmptyCart(userId) {
    return {
      userId,
      items: [],
      subtotal: 0,
      shipping: 0,
      tax: 0,
      discount: 0,
      total: 0,
      currency: 'EUR',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
  }

  /**
   * Calculer les totaux du panier
   */
  calculateCartTotals(cart) {
    // Calculer le sous-total
    cart.subtotal = cart.items.reduce((sum, item) => {
      return sum + (item.price * item.quantity);
    }, 0);

    // Calculer les frais de port (logique simplifiée)
    cart.shipping = cart.subtotal > 50 ? 0 : 5.99;
    
    // Calculer les taxes (TVA 20%)
    cart.tax = cart.subtotal * 0.20;

    // Calculer la remise si code promo
    cart.discount = 0;
    if (cart.promoCode) {
      switch (cart.promoCode.type) {
        case 'percentage':
          cart.discount = cart.subtotal * (cart.promoCode.value / 100);
          break;
        case 'fixed':
          cart.discount = Math.min(cart.promoCode.value, cart.subtotal);
          break;
        case 'shipping':
          cart.shipping = 0;
          break;
      }
    }

    // Calculer le total final
    cart.total = Math.max(0, cart.subtotal + cart.shipping + cart.tax - cart.discount);

    // Arrondir à 2 décimales
    cart.subtotal = Math.round(cart.subtotal * 100) / 100;
    cart.shipping = Math.round(cart.shipping * 100) / 100;
    cart.tax = Math.round(cart.tax * 100) / 100;
    cart.discount = Math.round(cart.discount * 100) / 100;
    cart.total = Math.round(cart.total * 100) / 100;
  }

  /**
   * Valider un item de panier
   */
  validateCartItem(item) {
    const required = ['productId', 'name', 'price', 'quantity'];
    
    for (const field of required) {
      if (!item[field]) {
        throw new Error(`Missing required field: ${field}`);
      }
    }

    if (typeof item.price !== 'number' || item.price <= 0) {
      throw new Error('Price must be a positive number');
    }

    if (typeof item.quantity !== 'number' || item.quantity <= 0 || !Number.isInteger(item.quantity)) {
      throw new Error('Quantity must be a positive integer');
    }

    if (item.quantity > 99) {
      throw new Error('Maximum quantity is 99');
    }
  }

  /**
   * Synchroniser le panier avec la base de données (pour persistance)
   */
  async syncCartToDatabase(userId) {
    try {
      const cart = await this.getCart(userId);
      
      // TODO: Implémenter la sauvegarde en base de données
      // Pour l'instant, on utilise seulement Redis
      
      structuredLogger.logInfo('CART_SYNCED_TO_DB', {
        userId,
        itemCount: cart.items.length,
        total: cart.total
      });

      return cart;
    } catch (error) {
      structuredLogger.logError('CART_SYNC_ERROR', {
        userId,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Obtenir les statistiques du panier
   */
  async getCartStats(userId) {
    try {
      const cart = await this.getCart(userId);
      
      return {
        itemCount: cart.items.length,
        totalQuantity: cart.items.reduce((sum, item) => sum + item.quantity, 0),
        subtotal: cart.subtotal,
        total: cart.total,
        hasPromoCode: !!cart.promoCode,
        currency: cart.currency,
        lastUpdated: cart.updatedAt
      };
    } catch (error) {
      structuredLogger.logError('CART_STATS_ERROR', {
        userId,
        error: error.message
      });
      throw error;
    }
  }
}

module.exports = new CartService();