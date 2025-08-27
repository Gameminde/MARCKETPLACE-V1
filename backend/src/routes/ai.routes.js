const express = require('express');
const multer = require('multer');
const AIUnifiedService = require('../services/ai-unified.service');

const router = express.Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (file.mimetype && file.mimetype.startsWith('image/')) return cb(null, true);
    cb(new Error('Only image files allowed'));
  }
});

// POST /api/v1/ai/validate
router.post('/validate', upload.array('images', 5), async (req, res) => {
  const start = Date.now();
  try {
    const { title = '', description = '', category = 'general', price = '0' } = req.body || {};

    // Build image sources: prefer uploaded buffers; fallback to URLs if provided
    let imageInputs = [];
    if (req.files && req.files.length > 0) {
      // Vision client can accept Buffer via content field; our service expects URLs
      // For now, skip buffer handling and just run fallback if no URLs
      // In production, AIUnifiedService can be extended to accept buffers
      imageInputs = []; // no URLs from upload; service will fallback
    } else if (req.body.images && Array.isArray(req.body.images)) {
      imageInputs = req.body.images;
    }

    const [imagesAnalysis, contentAnalysis, marketAnalysis] = await Promise.all([
      AIUnifiedService.analyzeImages(imageInputs),
      AIUnifiedService.analyzeContent(description, title),
      AIUnifiedService.analyzeMarket(category, parseFloat(price) || 0)
    ]);

    const qualityScore = Math.round(
      (imagesAnalysis.score * 0.35) + (contentAnalysis.score * 0.4) + (marketAnalysis.score * 0.25)
    );

    res.json({
      success: true,
      data: {
        validation_score: qualityScore,
        image_analysis: imagesAnalysis,
        content_analysis: contentAnalysis,
        market_analysis: marketAnalysis,
        processing_time: Date.now() - start
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'AI validation failed', error: error.message });
  }
});

module.exports = router;


