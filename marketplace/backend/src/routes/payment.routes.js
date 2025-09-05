const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/payment.controller');
const authMiddleware = require('../middleware/auth.middleware');

// Routes publiques
router.post('/webhook', express.raw({ type: 'application/json' }), paymentController.handleWebhook);
router.get('/status', (req, res) => {
  res.json({ success: true, status: 'ok', service: 'payment' });
});

// Routes protégées par authentification
router.use(authMiddleware);

// Paiements
router.post('/create-payment-intent', paymentController.createPaymentIntent);
router.post('/create-checkout-session', paymentController.createCheckoutSession);
router.get('/payment-status/:paymentIntentId', paymentController.getPaymentStatus);

// Remboursements
router.post('/refund', paymentController.createRefund);

// Calculs
router.post('/calculate-fees', paymentController.calculateFees);

// Comptes vendeurs (nécessite rôle vendeur ou admin)
router.post('/create-seller-account', authMiddleware.requireRole('seller'), paymentController.createSellerAccount);
router.post('/transfer', authMiddleware.requireRole('admin'), paymentController.createTransfer);
router.get('/account-balance/:accountId', authMiddleware.requireRole('seller'), paymentController.getAccountBalance);

module.exports = router;



