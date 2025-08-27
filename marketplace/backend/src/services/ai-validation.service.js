// ========================================
// AI VALIDATION SERVICE - PHASE 4
// Validation IA <30 secondes garantie
// ========================================

const { ImageAnnotatorClient } = require('@google-cloud/vision');
const productionConfig = require('../../config/production.config');
const structuredLogger = require('./structured-logger.service');
const databaseHybridService = require('./database-hybrid.service');

class AIValidationService {
  constructor() {
    this.visionClient = null;
    this.isInitialized = false;
    this.validationQueue = new Map();
    this.processingTimes = {
      image: 0,
      description: 0,
      category: 0,
      quality: 0,
      moderation: 0
    };
    
    this.init();
  }

  // ========================================
  // INITIALIZATION
  // ========================================
  
  async init() {
    try {
      if (productionConfig.ai.vision.apiKey) {
        this.visionClient = new ImageAnnotatorClient({
          keyFilename: productionConfig.ai.vision.apiKey
        });
        this.isInitialized = true;
        console.log('✅ Google Vision AI initialized');
      } else {
        console.warn('⚠️ Google Vision API key not configured, using fallback validation');
      }
    } catch (error) {
      console.error('❌ Error initializing AI validation service:', error);
      structuredLogger.logError('AI_VALIDATION_INIT_FAILED', { error: error.message });
    }
  }

  // ========================================
  // MAIN VALIDATION PIPELINE
  // ========================================
  
  async validateProduct(productData) {
    const startTime = Date.now();
    const validationId = this.generateValidationId();
    
    try {
      console.log(`🚀 Starting AI validation for product: ${productData.title || 'Unknown'}`);
      
      // Initialize validation result
      const validationResult = {
        id: validationId,
        productId: productData.id,
        timestamp: new Date().toISOString(),
        status: 'processing',
        scores: {},
        recommendations: [],
        errors: [],
        processingTime: 0
      };

      // Add to processing queue
      this.validationQueue.set(validationId, validationResult);

      // Execute validation pipeline in parallel for speed
      const [
        imageValidation,
        descriptionValidation,
        categoryValidation,
        qualityValidation,
        moderationValidation
      ] = await Promise.allSettled([
        this.validateImages(productData.images, validationId),
        this.validateDescription(productData.description, validationId),
        this.validateCategory(productData.category, productData.tags, validationId),
        this.validateQuality(productData, validationId),
        this.validateModeration(productData, validationId)
      ]);

      // Process results
      const results = [imageValidation, descriptionValidation, categoryValidation, qualityValidation, moderationValidation];
      
      results.forEach((result, index) => {
        if (result.status === 'fulfilled') {
          const key = Object.keys(this.processingTimes)[index];
          validationResult.scores[key] = result.value.score;
          validationResult.recommendations.push(...result.value.recommendations);
        } else {
          validationResult.errors.push({
            type: Object.keys(this.processingTimes)[index],
            error: result.reason.message
          });
        }
      });

      // Calculate overall score
      validationResult.overallScore = this.calculateOverallScore(validationResult.scores);
      validationResult.status = validationResult.overallScore >= 70 ? 'approved' : 'needs_review';
      validationResult.processingTime = Date.now() - startTime;

      // Log validation result
      structuredLogger.logInfo('AI_VALIDATION_COMPLETED', {
        validationId,
        productId: productData.id,
        overallScore: validationResult.overallScore,
        processingTime: validationResult.processingTime,
        status: validationResult.status
      });

      // Remove from queue
      this.validationQueue.delete(validationId);

      // Store validation result in database
      await this.storeValidationResult(validationResult);

      return validationResult;

    } catch (error) {
      console.error('❌ AI validation failed:', error);
      structuredLogger.logError('AI_VALIDATION_FAILED', {
        validationId,
        productId: productData.id,
        error: error.message
      });

      // Remove from queue
      this.validationQueue.delete(validationId);

      throw new Error(`AI validation failed: ${error.message}`);
    }
  }

  // ========================================
  // IMAGE VALIDATION (8 secondes max)
  // ========================================
  
  async validateImages(images, validationId) {
    const startTime = Date.now();
    const timeout = productionConfig.ai.validation.imageTimeout;
    
    try {
      if (!images || images.length === 0) {
        return { score: 0, recommendations: ['Aucune image fournie'] };
      }

      const imageResults = [];
      
      for (const image of images) {
        const imageResult = await Promise.race([
          this.analyzeImageWithAI(image),
          new Promise((_, reject) => 
            setTimeout(() => reject(new Error('Image analysis timeout')), timeout)
          )
        ]);
        
        imageResults.push(imageResult);
      }

      const averageScore = imageResults.reduce((sum, result) => sum + result.score, 0) / imageResults.length;
      const recommendations = imageResults.flatMap(result => result.recommendations);

      this.processingTimes.image = Date.now() - startTime;
      
      return {
        score: Math.round(averageScore),
        recommendations,
        processingTime: this.processingTimes.image
      };

    } catch (error) {
      console.warn(`⚠️ Image validation failed for ${validationId}:`, error.message);
      return { score: 50, recommendations: ['Erreur lors de l\'analyse des images'] };
    }
  }

  async analyzeImageWithAI(imageUrl) {
    if (!this.isInitialized || !this.visionClient) {
      // Fallback validation
      return this.fallbackImageValidation(imageUrl);
    }

    try {
      const [result] = await this.visionClient.annotateImage({
        image: { source: { imageUri: imageUrl } },
        features: productionConfig.ai.vision.features.map(feature => ({ type: feature }))
      });

      const annotations = result.fullTextAnnotation || result.labelAnnotations || [];
      const safeSearch = result.safeSearchAnnotation;

      // Analyze content
      let score = 80; // Base score
      const recommendations = [];

      // Check for inappropriate content
      if (safeSearch) {
        if (safeSearch.adult === 'LIKELY' || safeSearch.adult === 'VERY_LIKELY') {
          score -= 50;
          recommendations.push('Contenu inapproprié détecté');
        }
        if (safeSearch.violence === 'LIKELY' || safeSearch.violence === 'VERY_LIKELY') {
          score -= 30;
          recommendations.push('Contenu violent détecté');
        }
      }

      // Check image quality
      if (annotations.length === 0) {
        score -= 20;
        recommendations.push('Image de faible qualité ou floue');
      }

      // Check for text content
      if (result.textAnnotations && result.textAnnotations.length > 0) {
        score += 10;
        recommendations.push('Texte détecté dans l\'image');
      }

      return {
        score: Math.max(0, Math.min(100, score)),
        recommendations
      };

    } catch (error) {
      console.warn('⚠️ Google Vision API failed, using fallback:', error.message);
      return this.fallbackImageValidation(imageUrl);
    }
  }

  fallbackImageValidation(imageUrl) {
    // Basic validation without AI
    const score = 70;
    const recommendations = ['Validation basique (IA non disponible)'];
    
    return { score, recommendations };
  }

  // ========================================
  // DESCRIPTION VALIDATION (5 secondes max)
  // ========================================
  
  async validateDescription(description, validationId) {
    const startTime = Date.now();
    const timeout = productionConfig.ai.validation.descriptionTimeout;
    
    try {
      if (!description || description.length < 10) {
        return { score: 0, recommendations: ['Description trop courte (minimum 10 caractères)'] };
      }

      const result = await Promise.race([
        this.analyzeDescriptionWithAI(description),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error('Description analysis timeout')), timeout)
        )
      ]);

      this.processingTimes.description = Date.now() - startTime;
      
      return {
        score: result.score,
        recommendations: result.recommendations,
        processingTime: this.processingTimes.description
      };

    } catch (error) {
      console.warn(`⚠️ Description validation failed for ${validationId}:`, error.message);
      return { score: 60, recommendations: ['Erreur lors de l\'analyse de la description'] };
    }
  }

  async analyzeDescriptionWithAI(description) {
    // Basic NLP analysis (in production, use OpenAI or similar)
    let score = 80;
    const recommendations = [];

    // Check length
    if (description.length < 50) {
      score -= 20;
      recommendations.push('Description trop courte pour être optimale');
    } else if (description.length > 500) {
      score -= 10;
      recommendations.push('Description très longue, considérez la raccourcir');
    }

    // Check for keywords
    const keywords = ['qualité', 'premium', 'exclusif', 'unique', 'professionnel'];
    const hasKeywords = keywords.some(keyword => 
      description.toLowerCase().includes(keyword)
    );
    
    if (hasKeywords) {
      score += 10;
      recommendations.push('Mots-clés attractifs détectés');
    }

    // Check for spam indicators
    const spamIndicators = ['!!!', '$$$', 'URGENT', 'LIMITÉ', 'OFFRE EXCEPTIONNELLE'];
    const hasSpam = spamIndicators.some(indicator => 
      description.toUpperCase().includes(indicator)
    );
    
    if (hasSpam) {
      score -= 30;
      recommendations.push('Éléments de spam détectés');
    }

    // Check for proper formatting
    if (description.includes('\n') || description.includes('•')) {
      score += 5;
      recommendations.push('Formatage structuré détecté');
    }

    return {
      score: Math.max(0, Math.min(100, score)),
      recommendations
    };
  }

  // ========================================
  // CATEGORY VALIDATION (3 secondes max)
  // ========================================
  
  async validateCategory(category, tags, validationId) {
    const startTime = Date.now();
    const timeout = productionConfig.ai.validation.categoryTimeout;
    
    try {
      if (!category) {
        return { score: 0, recommendations: ['Catégorie requise'] };
      }

      const result = await Promise.race([
        this.analyzeCategoryWithAI(category, tags),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error('Category analysis timeout')), timeout)
        )
      ]);

      this.processingTimes.category = Date.now() - startTime;
      
      return {
        score: result.score,
        recommendations: result.recommendations,
        processingTime: this.processingTimes.category
      };

    } catch (error) {
      console.warn(`⚠️ Category validation failed for ${validationId}:`, error.message);
      return { score: 70, recommendations: ['Erreur lors de l\'analyse de la catégorie'] };
    }
  }

  async analyzeCategoryWithAI(category, tags = []) {
    let score = 80;
    const recommendations = [];

    // Validate category format
    const validCategories = [
      'mode', 'accessoires', 'maison', 'jardin', 'sport', 'loisirs',
      'technologie', 'beaute', 'sante', 'livres', 'musique', 'art'
    ];

    if (!validCategories.includes(category.toLowerCase())) {
      score -= 20;
      recommendations.push('Catégorie non reconnue, utilisez une catégorie standard');
    }

    // Check tags relevance
    if (tags && tags.length > 0) {
      if (tags.length < 3) {
        score -= 10;
        recommendations.push('Ajoutez plus de tags pour améliorer la visibilité');
      } else if (tags.length > 10) {
        score -= 5;
        recommendations.push('Trop de tags peuvent diluer la pertinence');
      }

      // Check for relevant tags
      const relevantTags = tags.filter(tag => 
        tag.length >= 3 && tag.length <= 20
      );
      
      if (relevantTags.length !== tags.length) {
        score -= 15;
        recommendations.push('Certains tags ne respectent pas les bonnes pratiques');
      }
    } else {
      score -= 20;
      recommendations.push('Ajoutez des tags pour améliorer la visibilité');
    }

    return {
      score: Math.max(0, Math.min(100, score)),
      recommendations
    };
  }

  // ========================================
  // QUALITY VALIDATION (2 secondes max)
  // ========================================
  
  async validateQuality(productData, validationId) {
    const startTime = Date.now();
    const timeout = productionConfig.ai.validation.qualityTimeout;
    
    try {
      const result = await Promise.race([
        this.analyzeQualityWithAI(productData),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error('Quality analysis timeout')), timeout)
        )
      ]);

      this.processingTimes.quality = Date.now() - startTime;
      
      return {
        score: result.score,
        recommendations: result.recommendations,
        processingTime: this.processingTimes.quality
      };

    } catch (error) {
      console.warn(`⚠️ Quality validation failed for ${validationId}:`, error.message);
      return { score: 65, recommendations: ['Erreur lors de l\'analyse de la qualité'] };
    }
  }

  async analyzeQualityWithAI(productData) {
    let score = 80;
    const recommendations = [];

    // Check price
    if (productData.price) {
      if (productData.price < 0.01) {
        score -= 30;
        recommendations.push('Prix trop bas, vérifiez la cohérence');
      } else if (productData.price > 10000) {
        score -= 10;
        recommendations.push('Prix élevé, justifiez la valeur');
      }
    }

    // Check title length
    if (productData.title) {
      if (productData.title.length < 5) {
        score -= 25;
        recommendations.push('Titre trop court');
      } else if (productData.title.length > 100) {
        score -= 15;
        recommendations.push('Titre trop long');
      }
    }

    // Check for required fields
    const requiredFields = ['title', 'description', 'price', 'category'];
    const missingFields = requiredFields.filter(field => !productData[field]);
    
    if (missingFields.length > 0) {
      score -= missingFields.length * 15;
      recommendations.push(`Champs manquants: ${missingFields.join(', ')}`);
    }

    // Check for professional presentation
    if (productData.description && productData.description.includes('http')) {
      score += 5;
      recommendations.push('Liens détectés, bonne pratique');
    }

    return {
      score: Math.max(0, Math.min(100, score)),
      recommendations
    };
  }

  // ========================================
  // MODERATION VALIDATION (3 secondes max)
  // ========================================
  
  async validateModeration(productData, validationId) {
    const startTime = Date.now();
    const timeout = productionConfig.ai.validation.moderationTimeout;
    
    try {
      const result = await Promise.race([
        this.analyzeModerationWithAI(productData),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error('Moderation analysis timeout')), timeout)
        )
      ]);

      this.processingTimes.moderation = Date.now() - startTime;
      
      return {
        score: result.score,
        recommendations: result.recommendations,
        processingTime: this.processingTimes.moderation
      };

    } catch (error) {
      console.warn(`⚠️ Moderation validation failed for ${validationId}:`, error.message);
      return { score: 60, recommendations: ['Erreur lors de la modération'] };
    }
  }

  async analyzeModerationWithAI(productData) {
    let score = 80;
    const recommendations = [];

    // Check for prohibited content
    const prohibitedWords = [
      'contrefaçon', 'faux', 'imitation', 'réplique', 'copie',
      'sexe', 'pornographie', 'violence', 'haine', 'discrimination'
    ];

    const content = `${productData.title} ${productData.description}`.toLowerCase();
    const foundProhibited = prohibitedWords.filter(word => content.includes(word));
    
    if (foundProhibited.length > 0) {
      score -= 50;
      recommendations.push(`Contenu interdit détecté: ${foundProhibited.join(', ')}`);
    }

    // Check for suspicious patterns
    const suspiciousPatterns = [
      /\d{4,}/g, // Too many consecutive numbers
      /[A-Z]{5,}/g, // Too many consecutive uppercase letters
      /[!@#$%^&*]{3,}/g // Too many special characters
    ];

    for (const pattern of suspiciousPatterns) {
      if (pattern.test(content)) {
        score -= 20;
        recommendations.push('Pattern suspect détecté');
        break;
      }
    }

    // Check for contact information (should not be in product description)
    const contactPatterns = [
      /\b\d{10}\b/g, // Phone numbers
      /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g, // Emails
      /(www\.|https?:\/\/)[^\s]+/g // URLs
    ];

    for (const pattern of contactPatterns) {
      if (pattern.test(content)) {
        score -= 15;
        recommendations.push('Informations de contact détectées dans la description');
        break;
      }
    }

    return {
      score: Math.max(0, Math.min(100, score)),
      recommendations
    };
  }

  // ========================================
  // UTILITY METHODS
  // ========================================
  
  calculateOverallScore(scores) {
    const weights = {
      image: 0.25,
      description: 0.25,
      category: 0.20,
      quality: 0.15,
      moderation: 0.15
    };

    let totalScore = 0;
    let totalWeight = 0;

    for (const [key, weight] of Object.entries(weights)) {
      if (scores[key] !== undefined) {
        totalScore += scores[key] * weight;
        totalWeight += weight;
      }
    }

    return totalWeight > 0 ? Math.round(totalScore / totalWeight) : 0;
  }

  generateValidationId() {
    return `val_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  async storeValidationResult(validationResult) {
    try {
      // Store in database for analytics
      const redis = await databaseHybridService.getRedis();
      if (redis) {
        const key = `validation:${validationResult.id}`;
        await redis.setex(key, 86400, JSON.stringify(validationResult)); // 24h TTL
      }
    } catch (error) {
      console.warn('⚠️ Could not store validation result:', error.message);
    }
  }

  getValidationStats() {
    return {
      queueSize: this.validationQueue.size,
      processingTimes: this.processingTimes,
      isInitialized: this.isInitialized
    };
  }

  async getValidationHistory(productId, limit = 10) {
    try {
      const redis = await databaseHybridService.getRedis();
      if (!redis) return [];

      const pattern = `validation:*`;
      const keys = await redis.keys(pattern);
      const results = [];

      for (const key of keys.slice(0, limit)) {
        const data = await redis.get(key);
        if (data) {
          const validation = JSON.parse(data);
          if (validation.productId === productId) {
            results.push(validation);
          }
        }
      }

      return results.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    } catch (error) {
      console.warn('⚠️ Could not retrieve validation history:', error.message);
      return [];
    }
  }
}

module.exports = new AIValidationService();
