const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const { advancedRateLimit } = require('../middleware/advanced-rate-limiter');
const { shopValidationSchema } = require('../models/Shop');

// Validation schemas (utilisent le model)
const createShopSchema = shopValidationSchema;
const updateShopSchema = shopValidationSchema.fork(['name', 'description', 'customizations'], (schema) => schema.optional());

// Validation middleware
const validateCreateShop = (req, res, next) => {
  const { error, value } = createShopSchema.validate(req.body);
  if (error) {
    return res.status(400).json({
      success: false,
      code: 'VALIDATION_ERROR',
      message: error.details[0].message
    });
  }
  req.validatedData = value;
  next();
};

const validateUpdateShop = (req, res, next) => {
  const { error, value } = updateShopSchema.validate(req.body);
  if (error) {
    return res.status(400).json({
      success: false,
      code: 'VALIDATION_ERROR',
      message: error.details[0].message
    });
  }
  req.validatedData = value;
  next();
};

// Shop endpoints
router.post('/create', authMiddleware, advancedRateLimit, validateCreateShop, async (req, res) => {
  try {
    // Validation déjà faite par middleware
    const shopData = req.validatedData;
    
    // TODO: Appel service création boutique
    // const shop = await shopService.create(shopData, req.user.sub);
    
    res.status(201).json({
      success: true,
      message: 'Boutique créée avec succès',
      data: { shopId: 'temp-id' } // Remplacer par shop._id
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      code: 'SHOP_CREATION_ERROR',
      message: 'Erreur lors de la création de la boutique'
    });
  }
});

router.get('/list', authMiddleware, (req, res) => {
  // TODO: Implement shop listing
  res.status(501).json({ success: false, message: 'Not implemented yet' });
});

router.get('/:id', authMiddleware, (req, res) => {
  // TODO: Implement shop retrieval
  res.status(501).json({ success: false, message: 'Not implemented yet' });
});

router.put('/:id', authMiddleware, advancedRateLimit, validateUpdateShop, (req, res) => {
  // TODO: Implement shop update
  res.status(501).json({ success: false, message: 'Not implemented yet' });
});

router.delete('/:id', authMiddleware, (req, res) => {
  // TODO: Implement shop deletion
  res.status(501).json({ success: false, message: 'Not implemented yet' });
});

module.exports = router;



