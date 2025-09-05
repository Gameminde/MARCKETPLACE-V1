const express = require('express');
const router = express.Router();
const cartController = require('../controllers/cart.controller');
const authMiddleware = require('../middleware/auth.middleware');

// Toutes les routes du panier nécessitent une authentification
router.use(authMiddleware);

// Routes principales du panier
router.get('/', cartController.getCart);
router.post('/add', cartController.addItem);
router.post('/remove', cartController.removeItem);
router.put('/update-quantity', cartController.updateItemQuantity);
router.delete('/clear', cartController.clearCart);

// Gestion des codes promo
router.post('/promo/apply', cartController.applyPromoCode);
router.delete('/promo/remove', cartController.removePromoCode);

// Utilitaires
router.get('/stats', cartController.getCartStats);
router.post('/sync', cartController.syncCart);
router.post('/validate', cartController.validateCart);

// Création de commande
router.post('/create-order', cartController.createOrderFromCart);

module.exports = router;