const express = require('express');
const router = express.Router();
const { optionalAuth, authMiddleware, requireRole } = require('../middleware/auth.middleware');
const xpRoutes = require('./xp.routes');

// Sample products data for testing
const sampleProducts = [
  {
    id: '1',
    name: 'Premium Wireless Headphones',
    description: 'High-quality wireless headphones with noise cancellation',
    price: 199.99,
    category: 'Electronics',
    image: '/public/products/headphones.jpg',
    rating: 4.5,
    reviews: 128
  },
  {
    id: '2',
    name: 'Smart Fitness Watch',
    description: 'Advanced fitness tracking with heart rate monitor',
    price: 299.99,
    category: 'Wearables',
    image: '/public/products/smartwatch.jpg',
    rating: 4.7,
    reviews: 89
  },
  {
    id: '3',
    name: 'Organic Coffee Beans',
    description: 'Premium organic coffee beans from Colombia',
    price: 24.99,
    category: 'Food & Beverage',
    image: '/public/products/coffee.jpg',
    rating: 4.8,
    reviews: 256
  },
  {
    id: '4',
    name: 'Minimalist Backpack',
    description: 'Sleek and functional backpack for daily use',
    price: 79.99,
    category: 'Fashion',
    image: '/public/products/backpack.jpg',
    rating: 4.3,
    reviews: 67
  },
  {
    id: '5',
    name: 'Wireless Charging Pad',
    description: 'Fast wireless charging for all compatible devices',
    price: 39.99,
    category: 'Electronics',
    image: '/public/products/charger.jpg',
    rating: 4.4,
    reviews: 143
  }
];

/**
 * @route GET /api/v1/products
 * @desc Get all products
 * @access Public
 */
router.get('/', (req, res) => {
  const { category, search, limit = 20, page = 1 } = req.query;
  
  let filteredProducts = [...sampleProducts];
  
  // Filter by category
  if (category) {
    filteredProducts = filteredProducts.filter(p => 
      p.category.toLowerCase().includes(category.toLowerCase())
    );
  }
  
  // Filter by search term
  if (search) {
    filteredProducts = filteredProducts.filter(p => 
      p.name.toLowerCase().includes(search.toLowerCase()) ||
      p.description.toLowerCase().includes(search.toLowerCase())
    );
  }
  
  // Pagination
  const startIndex = (page - 1) * limit;
  const endIndex = startIndex + parseInt(limit);
  const paginatedProducts = filteredProducts.slice(startIndex, endIndex);
  
  res.json({
    success: true,
    data: paginatedProducts,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total: filteredProducts.length,
      pages: Math.ceil(filteredProducts.length / limit)
    }
  });
});

/**
 * @route GET /api/v1/products/:productId
 * @desc Get single product by ID
 * @access Public
 * @middleware Automatically tracks product view XP if user is authenticated
 */
router.get('/:productId', 
  optionalAuth, // Optional auth - works for both logged in and guest users
  xpRoutes.trackProductView,   // Track XP for product view
  (req, res) => {
    const { productId } = req.params;
    
    const product = sampleProducts.find(p => p.id === productId);
    
    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }
    
    // Add view tracking metadata
    const productWithMetadata = {
      ...product,
      viewedAt: new Date().toISOString(),
      viewerId: req.user?.id || null
    };
    
    res.json({
      success: true,
      data: productWithMetadata,
      message: req.user ? 'Product viewed - XP awarded!' : 'Product viewed'
    });
  }
);

/**
 * @route POST /api/v1/products/:productId/purchase
 * @desc Purchase a product
 * @access Private
 * @middleware Automatically tracks purchase XP
 */
router.post('/:productId/purchase',
  authMiddleware,
  xpRoutes.trackPurchase,
  (req, res) => {
    const { productId } = req.params;
    const { quantity = 1, paymentMethod } = req.body;
    
    const product = sampleProducts.find(p => p.id === productId);
    
    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }
    
    // Simulate purchase processing
    const orderId = `order_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const totalAmount = product.price * quantity;
    
    const order = {
      orderId,
      productId,
      product: product.name,
      quantity,
      unitPrice: product.price,
      totalAmount,
      paymentMethod,
      status: 'completed',
      purchasedAt: new Date().toISOString(),
      userId: req.user.id
    };
    
    // Add orderId to request body for XP tracking
    req.body.orderId = orderId;
    
    res.json({
      success: true,
      data: order,
      message: 'Purchase completed successfully! XP awarded!'
    });
  }
);

/**
 * @route POST /api/v1/products/:productId/share
 * @desc Share a product
 * @access Private
 * @middleware Automatically tracks share XP
 */
router.post('/:productId/share',
  authMiddleware,
  xpRoutes.trackShare,
  (req, res) => {
    const { productId } = req.params;
    const { platform, message } = req.body;
    
    const product = sampleProducts.find(p => p.id === productId);
    
    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }
    
    // Add productId to request body for XP tracking
    req.body.productId = productId;
    
    const shareData = {
      productId,
      productName: product.name,
      platform,
      message,
      sharedAt: new Date().toISOString(),
      userId: req.user.id,
      shareUrl: `${process.env.BASE_URL || 'http://localhost:3001'}/products/${productId}`
    };
    
    res.json({
      success: true,
      data: shareData,
      message: 'Product shared successfully! XP awarded!'
    });
  }
);

/**
 * @route GET /api/v1/products/categories
 * @desc Get all product categories
 * @access Public
 */
router.get('/categories', (req, res) => {
  const categories = [...new Set(sampleProducts.map(p => p.category))];
  
  res.json({
    success: true,
    data: categories
  });
});

/**
 * @route GET /api/v1/products/featured
 * @desc Get featured products (highest rated)
 * @access Public
 */
router.get('/featured', (req, res) => {
  const featuredProducts = sampleProducts
    .sort((a, b) => b.rating - a.rating)
    .slice(0, 3);
  
  res.json({
    success: true,
    data: featuredProducts
  });
});

module.exports = router;



