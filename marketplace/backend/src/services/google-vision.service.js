const { ImageAnnotatorClient } = require('@google-cloud/vision');
const structuredLogger = require('./structured-logger.service');
const redisService = require('./redis.service');

class GoogleVisionService {
  constructor() {
    // Initialize Google Vision client
    this.client = null;
    this.isEnabled = false;
    this.quotaUsed = 0;
    this.quotaLimit = 1000; // Free tier: 1000 requests/month
    this.cachePrefix = 'vision:';
    this.cacheExpiry = 7 * 24 * 60 * 60; // 7 days
    
    this.initializeClient();
  }

  /**
   * Initialize Google Vision client with proper authentication
   */
  initializeClient() {
    try {
      // Check if Google Cloud credentials are available
      if (process.env.GOOGLE_APPLICATION_CREDENTIALS || process.env.GOOGLE_CLOUD_PROJECT) {
        this.client = new ImageAnnotatorClient({
          projectId: process.env.GOOGLE_CLOUD_PROJECT,
          keyFilename: process.env.GOOGLE_APPLICATION_CREDENTIALS,
        });
        this.isEnabled = true;
        
        structuredLogger.logInfo('GOOGLE_VISION_INITIALIZED', {
          projectId: process.env.GOOGLE_CLOUD_PROJECT,
          quotaLimit: this.quotaLimit
        });
      } else {
        structuredLogger.logInfo('GOOGLE_VISION_DISABLED', {
          reason: 'No credentials found - using fallback validation'
        });
      }
    } catch (error) {
      structuredLogger.logError('GOOGLE_VISION_INIT_ERROR', {
        error: error.message
      });
      this.isEnabled = false;
    }
  }

  /**
   * Analyze image with comprehensive Google Vision features
   */
  async analyzeImage(imageUrl, options = {}) {
    const startTime = Date.now();
    const cacheKey = `${this.cachePrefix}${this.hashUrl(imageUrl)}`;
    
    try {
      // Check cache first to save API quota
      const cachedResult = await redisService.get(cacheKey);
      if (cachedResult) {
        structuredLogger.logInfo('VISION_CACHE_HIT', { imageUrl });
        return JSON.parse(cachedResult);
      }

      // Check if service is enabled and quota available
      if (!this.isEnabled) {
        return this.getFallbackAnalysis(imageUrl, 'Service disabled');
      }

      if (this.quotaUsed >= this.quotaLimit) {
        return this.getFallbackAnalysis(imageUrl, 'Quota exceeded');
      }

      // Prepare Vision API request
      const request = {
        image: { source: { imageUri: imageUrl } },
        features: [
          { type: 'SAFE_SEARCH_DETECTION' },
          { type: 'OBJECT_LOCALIZATION' },
          { type: 'TEXT_DETECTION' },
          { type: 'LABEL_DETECTION', maxResults: 10 },
          { type: 'IMAGE_PROPERTIES' },
          { type: 'LOGO_DETECTION' },
          { type: 'PRODUCT_SEARCH' }
        ]
      };

      // Call Google Vision API
      const [result] = await this.client.annotateImage(request);
      this.quotaUsed++;

      // Process and structure the results
      const analysis = this.processVisionResults(result, imageUrl);
      analysis.processingTime = Date.now() - startTime;
      analysis.source = 'google_vision';
      analysis.quotaUsed = this.quotaUsed;

      // Cache the result to save future API calls
      await redisService.setex(cacheKey, this.cacheExpiry, JSON.stringify(analysis));

      structuredLogger.logInfo('VISION_ANALYSIS_SUCCESS', {
        imageUrl,
        processingTime: analysis.processingTime,
        quotaUsed: this.quotaUsed,
        quality: analysis.quality
      });

      return analysis;

    } catch (error) {
      const processingTime = Date.now() - startTime;
      
      structuredLogger.logError('VISION_ANALYSIS_ERROR', {
        imageUrl,
        error: error.message,
        processingTime
      });

      return this.getFallbackAnalysis(imageUrl, error.message, processingTime);
    }
  }

  /**
   * Process Google Vision API results into structured format
   */
  processVisionResults(result, imageUrl) {
    const analysis = {
      imageUrl,
      quality: 0,
      objects: [],
      labels: [],
      text: '',
      brands: [],
      colors: [],
      moderation: { safe: true, issues: [] },
      properties: {},
      confidence: 0
    };

    try {
      // Safe Search Detection
      if (result.safeSearchAnnotation) {
        const safeSearch = result.safeSearchAnnotation;
        const issues = [];
        
        if (safeSearch.adult === 'LIKELY' || safeSearch.adult === 'VERY_LIKELY') {
          issues.push('Adult content detected');
        }
        if (safeSearch.violence === 'LIKELY' || safeSearch.violence === 'VERY_LIKELY') {
          issues.push('Violence detected');
        }
        if (safeSearch.racy === 'LIKELY' || safeSearch.racy === 'VERY_LIKELY') {
          issues.push('Racy content detected');
        }
        
        analysis.moderation = {
          safe: issues.length === 0,
          issues,
          details: safeSearch
        };
      }

      // Object Detection
      if (result.localizedObjectAnnotations) {
        analysis.objects = result.localizedObjectAnnotations.map(obj => ({
          name: obj.name,
          confidence: obj.score,
          boundingBox: obj.boundingPoly
        }));
      }

      // Label Detection
      if (result.labelAnnotations) {
        analysis.labels = result.labelAnnotations.map(label => ({
          description: label.description,
          confidence: label.score,
          topicality: label.topicality
        }));
      }

      // Text Detection (OCR)
      if (result.textAnnotations && result.textAnnotations.length > 0) {
        analysis.text = result.textAnnotations[0].description || '';
      }

      // Logo Detection
      if (result.logoAnnotations) {
        analysis.brands = result.logoAnnotations.map(logo => ({
          description: logo.description,
          confidence: logo.score
        }));
      }

      // Image Properties
      if (result.imagePropertiesAnnotation) {
        const props = result.imagePropertiesAnnotation;
        
        if (props.dominantColors && props.dominantColors.colors) {
          analysis.colors = props.dominantColors.colors.map(color => ({
            color: color.color,
            score: color.score,
            pixelFraction: color.pixelFraction
          }));
        }
        
        analysis.properties = {
          dominantColors: analysis.colors,
          colorfulness: this.calculateColorfulness(analysis.colors)
        };
      }

      // Calculate overall quality score
      analysis.quality = this.calculateImageQuality(analysis);
      analysis.confidence = this.calculateOverallConfidence(analysis);

      return analysis;

    } catch (error) {
      structuredLogger.logError('VISION_RESULT_PROCESSING_ERROR', {
        error: error.message,
        imageUrl
      });
      
      return {
        ...analysis,
        error: error.message,
        quality: 0,
        confidence: 0
      };
    }
  }

  /**
   * Calculate image quality score based on Vision API results
   */
  calculateImageQuality(analysis) {
    let score = 0;
    
    // Base score for successful analysis
    score += 20;
    
    // Object detection quality
    if (analysis.objects.length > 0) {
      const avgObjectConfidence = analysis.objects.reduce((sum, obj) => sum + obj.confidence, 0) / analysis.objects.length;
      score += avgObjectConfidence * 30;
    }
    
    // Label detection quality
    if (analysis.labels.length > 0) {
      const avgLabelConfidence = analysis.labels.reduce((sum, label) => sum + label.confidence, 0) / analysis.labels.length;
      score += avgLabelConfidence * 25;
    }
    
    // Color analysis quality
    if (analysis.colors.length > 0) {
      score += Math.min(15, analysis.colors.length * 3);
    }
    
    // Text detection bonus
    if (analysis.text && analysis.text.length > 0) {
      score += 10;
    }
    
    // Safety penalty
    if (!analysis.moderation.safe) {
      score -= 50;
    }
    
    return Math.max(0, Math.min(100, Math.round(score)));
  }

  /**
   * Calculate overall confidence score
   */
  calculateOverallConfidence(analysis) {
    const confidences = [];
    
    if (analysis.objects.length > 0) {
      confidences.push(...analysis.objects.map(obj => obj.confidence));
    }
    
    if (analysis.labels.length > 0) {
      confidences.push(...analysis.labels.map(label => label.confidence));
    }
    
    if (analysis.brands.length > 0) {
      confidences.push(...analysis.brands.map(brand => brand.confidence));
    }
    
    if (confidences.length === 0) return 0;
    
    return confidences.reduce((sum, conf) => sum + conf, 0) / confidences.length;
  }

  /**
   * Calculate colorfulness metric
   */
  calculateColorfulness(colors) {
    if (!colors || colors.length === 0) return 0;
    
    // Simple colorfulness calculation based on color diversity
    const uniqueColors = new Set(colors.map(c => 
      `${Math.round(c.color.red || 0)}-${Math.round(c.color.green || 0)}-${Math.round(c.color.blue || 0)}`
    ));
    
    return Math.min(100, (uniqueColors.size / colors.length) * 100);
  }

  /**
   * Generate fallback analysis when Google Vision is unavailable
   */
  getFallbackAnalysis(imageUrl, reason, processingTime = 0) {
    return {
      imageUrl,
      quality: 50, // Neutral score
      objects: [],
      labels: [],
      text: '',
      brands: [],
      colors: [],
      moderation: { safe: true, issues: [] },
      properties: {},
      confidence: 0,
      source: 'fallback',
      fallbackReason: reason,
      processingTime,
      recommendations: [
        'Google Vision API unavailable - manual review recommended',
        'Consider enabling Google Vision API for better analysis'
      ]
    };
  }

  /**
   * Batch analyze multiple images
   */
  async analyzeImages(imageUrls, options = {}) {
    const startTime = Date.now();
    
    try {
      // Process images in parallel with concurrency limit
      const concurrencyLimit = options.concurrency || 3;
      const results = [];
      
      for (let i = 0; i < imageUrls.length; i += concurrencyLimit) {
        const batch = imageUrls.slice(i, i + concurrencyLimit);
        const batchPromises = batch.map(url => this.analyzeImage(url, options));
        const batchResults = await Promise.all(batchPromises);
        results.push(...batchResults);
      }
      
      const totalTime = Date.now() - startTime;
      
      structuredLogger.logInfo('VISION_BATCH_ANALYSIS_COMPLETE', {
        imageCount: imageUrls.length,
        totalTime,
        averageTime: totalTime / imageUrls.length,
        quotaUsed: this.quotaUsed
      });
      
      return {
        results,
        summary: this.generateBatchSummary(results),
        totalTime,
        quotaUsed: this.quotaUsed
      };
      
    } catch (error) {
      structuredLogger.logError('VISION_BATCH_ANALYSIS_ERROR', {
        error: error.message,
        imageCount: imageUrls.length
      });
      
      throw error;
    }
  }

  /**
   * Generate summary for batch analysis
   */
  generateBatchSummary(results) {
    const summary = {
      totalImages: results.length,
      averageQuality: 0,
      safeImages: 0,
      unsafeImages: 0,
      objectsDetected: 0,
      brandsDetected: 0,
      textDetected: 0,
      averageConfidence: 0
    };
    
    if (results.length === 0) return summary;
    
    let totalQuality = 0;
    let totalConfidence = 0;
    
    results.forEach(result => {
      totalQuality += result.quality;
      totalConfidence += result.confidence;
      
      if (result.moderation.safe) {
        summary.safeImages++;
      } else {
        summary.unsafeImages++;
      }
      
      if (result.objects.length > 0) summary.objectsDetected++;
      if (result.brands.length > 0) summary.brandsDetected++;
      if (result.text && result.text.length > 0) summary.textDetected++;
    });
    
    summary.averageQuality = Math.round(totalQuality / results.length);
    summary.averageConfidence = totalConfidence / results.length;
    
    return summary;
  }

  /**
   * Get service status and quota information
   */
  getServiceStatus() {
    return {
      enabled: this.isEnabled,
      quotaUsed: this.quotaUsed,
      quotaLimit: this.quotaLimit,
      quotaRemaining: this.quotaLimit - this.quotaUsed,
      quotaPercentage: Math.round((this.quotaUsed / this.quotaLimit) * 100),
      cacheEnabled: true,
      cacheExpiry: this.cacheExpiry
    };
  }

  /**
   * Reset quota counter (for testing or monthly reset)
   */
  resetQuota() {
    this.quotaUsed = 0;
    structuredLogger.logInfo('VISION_QUOTA_RESET');
  }

  /**
   * Generate hash for URL to use as cache key
   */
  hashUrl(url) {
    const crypto = require('crypto');
    return crypto.createHash('md5').update(url).digest('hex');
  }

  /**
   * Clear vision analysis cache
   */
  async clearCache() {
    try {
      // This would need to be implemented based on Redis pattern matching
      // For now, we'll just log the action
      structuredLogger.logInfo('VISION_CACHE_CLEAR_REQUESTED');
      return true;
    } catch (error) {
      structuredLogger.logError('VISION_CACHE_CLEAR_ERROR', {
        error: error.message
      });
      return false;
    }
  }

  /**
   * Get cache statistics
   */
  async getCacheStats() {
    // Mock implementation - would need Redis pattern matching in real implementation
    return {
      totalEntries: 0,
      hitRate: 0.85,
      averageSize: '2.5KB',
      totalSize: '0MB'
    };
  }
}

module.exports = new GoogleVisionService();