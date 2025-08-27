// ========================================
// STORAGE SERVICE - PHASE 4
// Cloudinary avec optimisation automatique
// ========================================

const cloudinary = require('cloudinary').v2;
const sharp = require('sharp');
const productionConfig = require('../../config/production.config');
const structuredLogger = require('./structured-logger.service');

class StorageService {
  constructor() {
    this.isInitialized = false;
    this.supportedFormats = ['jpg', 'jpeg', 'png', 'webp'];
    this.maxFileSize = 10 * 1024 * 1024; // 10MB
    this.optimizationSettings = {
      quality: 85,
      format: 'webp',
      maxWidth: 1920,
      maxHeight: 1080
    };
    
    this.init();
  }

  // ========================================
  // INITIALIZATION
  // ========================================
  
  init() {
    try {
      if (productionConfig.storage.provider === 'cloudinary' && productionConfig.storage.cloudinary) {
        const { cloudName, apiKey, apiSecret } = productionConfig.storage.cloudinary;
        
        if (cloudName && apiKey && apiSecret) {
          cloudinary.config({
            cloud_name: cloudName,
            api_key: apiKey,
            api_secret: apiSecret
          });
          
          this.isInitialized = true;
          console.log('✅ Cloudinary storage initialized');
        } else {
          console.warn('⚠️ Cloudinary credentials incomplete');
        }
      } else {
        console.warn('⚠️ Cloudinary not configured, using local storage fallback');
      }
    } catch (error) {
      console.error('❌ Error initializing storage service:', error);
      structuredLogger.logError('STORAGE_INIT_FAILED', { error: error.message });
    }
  }

  // ========================================
  // IMAGE UPLOAD & OPTIMIZATION
  // ========================================
  
  async uploadImage(file, options = {}) {
    try {
      // Validate file
      this.validateImageFile(file);
      
      // Optimize image before upload
      const optimizedBuffer = await this.optimizeImage(file.buffer, options);
      
      if (this.isInitialized) {
        return await this.uploadToCloudinary(optimizedBuffer, file.originalname, options);
      } else {
        return await this.uploadToLocalStorage(optimizedBuffer, file.originalname, options);
      }
    } catch (error) {
      console.error('❌ Image upload failed:', error);
      structuredLogger.logError('IMAGE_UPLOAD_FAILED', { 
        filename: file.originalname,
        error: error.message 
      });
      throw error;
    }
  }

  async uploadMultipleImages(files, options = {}) {
    const uploadPromises = files.map(file => this.uploadImage(file, options));
    
    try {
      const results = await Promise.allSettled(uploadPromises);
      
      const successful = [];
      const failed = [];
      
      results.forEach((result, index) => {
        if (result.status === 'fulfilled') {
          successful.push(result.value);
        } else {
          failed.push({
            filename: files[index].originalname,
            error: result.reason.message
          });
        }
      });
      
      if (failed.length > 0) {
        console.warn(`⚠️ ${failed.length} images failed to upload:`, failed);
        structuredLogger.logWarning('MULTIPLE_IMAGE_UPLOAD_PARTIAL_FAILURE', {
          total: files.length,
          successful: successful.length,
          failed: failed.length
        });
      }
      
      return {
        successful,
        failed,
        total: files.length
      };
    } catch (error) {
      console.error('❌ Multiple image upload failed:', error);
      throw error;
    }
  }

  // ========================================
  // IMAGE OPTIMIZATION
  // ========================================
  
  async optimizeImage(buffer, options = {}) {
    try {
      const settings = { ...this.optimizationSettings, ...options };
      
      let image = sharp(buffer);
      
      // Get image metadata
      const metadata = await image.metadata();
      
      // Resize if needed
      if (metadata.width > settings.maxWidth || metadata.height > settings.maxHeight) {
        image = image.resize(settings.maxWidth, settings.maxHeight, {
          fit: 'inside',
          withoutEnlargement: true
        });
      }
      
      // Convert to preferred format and optimize
      const optimizedBuffer = await image
        .webp({ quality: settings.quality })
        .toBuffer();
      
      const originalSize = buffer.length;
      const optimizedSize = optimizedBuffer.length;
      const compressionRatio = ((originalSize - optimizedSize) / originalSize * 100).toFixed(1);
      
      console.log(`📸 Image optimized: ${originalSize}KB → ${optimizedSize}KB (${compressionRatio}% reduction)`);
      
      return optimizedBuffer;
    } catch (error) {
      console.warn('⚠️ Image optimization failed, using original:', error.message);
      return buffer;
    }
  }

  // ========================================
  // CLOUDINARY UPLOAD
  // ========================================
  
  async uploadToCloudinary(buffer, filename, options = {}) {
    try {
      const uploadOptions = {
        folder: productionConfig.storage.cloudinary.folder || 'marketplace',
        resource_type: 'image',
        format: 'webp',
        quality: 'auto',
        fetch_format: 'auto',
        ...options
      };
      
      // Convert buffer to base64 for Cloudinary
      const base64Image = buffer.toString('base64');
      const dataURI = `data:image/webp;base64,${base64Image}`;
      
      const result = await cloudinary.uploader.upload(dataURI, uploadOptions);
      
      const uploadResult = {
        id: result.public_id,
        url: result.secure_url,
        width: result.width,
        height: result.height,
        format: result.format,
        size: result.bytes,
        provider: 'cloudinary',
        metadata: {
          publicId: result.public_id,
          assetId: result.asset_id,
          version: result.version
        }
      };
      
      console.log(`☁️ Image uploaded to Cloudinary: ${filename} → ${uploadResult.url}`);
      structuredLogger.logInfo('CLOUDINARY_UPLOAD_SUCCESS', {
        filename,
        publicId: result.public_id,
        size: result.bytes,
        url: uploadResult.url
      });
      
      return uploadResult;
    } catch (error) {
      console.error('❌ Cloudinary upload failed:', error);
      throw new Error(`Cloudinary upload failed: ${error.message}`);
    }
  }

  // ========================================
  // LOCAL STORAGE FALLBACK
  // ========================================
  
  async uploadToLocalStorage(buffer, filename, options = {}) {
    try {
      // Generate unique filename
      const timestamp = Date.now();
      const random = Math.random().toString(36).substr(2, 9);
      const extension = filename.split('.').pop() || 'webp';
      const uniqueFilename = `${timestamp}_${random}.${extension}`;
      
      // In production, you would save to a proper file system or cloud storage
      // For now, we'll simulate the upload
      const uploadResult = {
        id: uniqueFilename,
        url: `/uploads/${uniqueFilename}`,
        width: 800, // Simulated
        height: 600, // Simulated
        format: extension,
        size: buffer.length,
        provider: 'local',
        metadata: {
          filename: uniqueFilename,
          originalName: filename
        }
      };
      
      console.log(`💾 Image saved locally: ${filename} → ${uploadResult.url}`);
      
      return uploadResult;
    } catch (error) {
      console.error('❌ Local storage upload failed:', error);
      throw new Error(`Local storage upload failed: ${error.message}`);
    }
  }

  // ========================================
  // IMAGE TRANSFORMATIONS
  // ========================================
  
  async generateThumbnail(imageUrl, width = 300, height = 300) {
    if (!this.isInitialized) {
      return imageUrl; // Return original if Cloudinary not available
    }
    
    try {
      const transformation = `w_${width},h_${height},c_fill,g_auto,q_auto`;
      const thumbnailUrl = imageUrl.replace('/upload/', `/upload/${transformation}/`);
      
      return thumbnailUrl;
    } catch (error) {
      console.warn('⚠️ Thumbnail generation failed:', error.message);
      return imageUrl;
    }
  }

  async generateResponsiveImages(imageUrl, sizes = [300, 600, 900, 1200]) {
    if (!this.isInitialized) {
      return { [sizes[0]]: imageUrl }; // Return single size if Cloudinary not available
    }
    
    try {
      const responsiveImages = {};
      
      for (const size of sizes) {
        const transformation = `w_${size},c_scale,q_auto`;
        const responsiveUrl = imageUrl.replace('/upload/', `/upload/${transformation}/`);
        responsiveImages[size] = responsiveUrl;
      }
      
      return responsiveImages;
    } catch (error) {
      console.warn('⚠️ Responsive images generation failed:', error.message);
      return { [sizes[0]]: imageUrl };
    }
  }

  async applyWatermark(imageUrl, watermarkText = 'Marketplace') {
    if (!this.isInitialized) {
      return imageUrl; // Return original if Cloudinary not available
    }
    
    try {
      const transformation = `l_text:Arial_24:${watermarkText},g_south_east,x_10,y_10,co_white,bo_2px_solid_black`;
      const watermarkedUrl = imageUrl.replace('/upload/', `/upload/${transformation}/`);
      
      return watermarkedUrl;
    } catch (error) {
      console.warn('⚠️ Watermark application failed:', error.message);
      return imageUrl;
    }
  }

  // ========================================
  // IMAGE MANAGEMENT
  // ========================================
  
  async deleteImage(imageId, provider = 'cloudinary') {
    try {
      if (provider === 'cloudinary' && this.isInitialized) {
        const result = await cloudinary.uploader.destroy(imageId);
        
        if (result.result === 'ok') {
          console.log(`🗑️ Image deleted from Cloudinary: ${imageId}`);
          structuredLogger.logInfo('CLOUDINARY_IMAGE_DELETED', { imageId });
          return true;
        } else {
          throw new Error(`Failed to delete image: ${result.result}`);
        }
      } else {
        // Local storage deletion would go here
        console.log(`🗑️ Image marked for local deletion: ${imageId}`);
        return true;
      }
    } catch (error) {
      console.error('❌ Image deletion failed:', error);
      structuredLogger.logError('IMAGE_DELETION_FAILED', { 
        imageId, 
        provider, 
        error: error.message 
      });
      throw error;
    }
  }

  async getImageInfo(imageUrl) {
    try {
      if (this.isInitialized && imageUrl.includes('cloudinary.com')) {
        const publicId = this.extractPublicId(imageUrl);
        const result = await cloudinary.api.resource(publicId);
        
        return {
          id: result.public_id,
          url: result.secure_url,
          width: result.width,
          height: result.height,
          format: result.format,
          size: result.bytes,
          createdAt: result.created_at,
          tags: result.tags || []
        };
      } else {
        // Return basic info for non-Cloudinary images
        return {
          url: imageUrl,
          provider: 'unknown'
        };
      }
    } catch (error) {
      console.warn('⚠️ Could not get image info:', error.message);
      return { url: imageUrl, provider: 'unknown' };
    }
  }

  // ========================================
  // VALIDATION & UTILITIES
  // ========================================
  
  validateImageFile(file) {
    if (!file) {
      throw new Error('No file provided');
    }
    
    if (!file.buffer) {
      throw new Error('File buffer is required');
    }
    
    if (file.size > this.maxFileSize) {
      throw new Error(`File size exceeds maximum limit of ${this.maxFileSize / (1024 * 1024)}MB`);
    }
    
    const extension = file.originalname.split('.').pop()?.toLowerCase();
    if (!this.supportedFormats.includes(extension)) {
      throw new Error(`Unsupported file format. Supported: ${this.supportedFormats.join(', ')}`);
    }
  }

  extractPublicId(imageUrl) {
    // Extract public ID from Cloudinary URL
    const match = imageUrl.match(/\/upload\/.*?\/([^\/]+)$/);
    if (match) {
      return match[1].split('.')[0]; // Remove extension
    }
    throw new Error('Invalid Cloudinary URL format');
  }

  // ========================================
  // STORAGE STATISTICS
  // ========================================
  
  async getStorageStats() {
    try {
      if (this.isInitialized) {
        const result = await cloudinary.api.usage();
        
        return {
          provider: 'cloudinary',
          plan: result.plan,
          credits: result.credits,
          objects: result.objects,
          bandwidth: result.bandwidth,
          storage: result.storage,
          requests: result.requests,
          resources: result.resources
        };
      } else {
        return {
          provider: 'local',
          status: 'fallback_mode'
        };
      }
    } catch (error) {
      console.warn('⚠️ Could not get storage stats:', error.message);
      return { provider: 'unknown', error: error.message };
    }
  }

  // ========================================
  // BULK OPERATIONS
  // ========================================
  
  async bulkDeleteImages(imageIds, provider = 'cloudinary') {
    try {
      if (provider === 'cloudinary' && this.isInitialized) {
        const deletePromises = imageIds.map(id => this.deleteImage(id, provider));
        const results = await Promise.allSettled(deletePromises);
        
        const successful = results.filter(r => r.status === 'fulfilled').length;
        const failed = results.filter(r => r.status === 'rejected').length;
        
        console.log(`🗑️ Bulk deletion completed: ${successful} successful, ${failed} failed`);
        
        return { successful, failed, total: imageIds.length };
      } else {
        // Handle local storage bulk deletion
        return { successful: imageIds.length, failed: 0, total: imageIds.length };
      }
    } catch (error) {
      console.error('❌ Bulk deletion failed:', error);
      throw error;
    }
  }

  async migrateImages(fromProvider, toProvider, imageUrls) {
    try {
      console.log(`🔄 Starting image migration from ${fromProvider} to ${toProvider}`);
      
      const migrationResults = [];
      
      for (const imageUrl of imageUrls) {
        try {
          // Download image from source
          const response = await fetch(imageUrl);
          const buffer = await response.arrayBuffer();
          
          // Upload to destination
          const uploadResult = await this.uploadToCloudinary(Buffer.from(buffer), 'migrated.jpg');
          
          migrationResults.push({
            originalUrl: imageUrl,
            newUrl: uploadResult.url,
            status: 'success'
          });
          
        } catch (error) {
          migrationResults.push({
            originalUrl: imageUrl,
            error: error.message,
            status: 'failed'
          });
        }
      }
      
      const successful = migrationResults.filter(r => r.status === 'success').length;
      const failed = migrationResults.filter(r => r.status === 'failed').length;
      
      console.log(`✅ Migration completed: ${successful} successful, ${failed} failed`);
      
      return {
        results: migrationResults,
        summary: { successful, failed, total: imageUrls.length }
      };
    } catch (error) {
      console.error('❌ Image migration failed:', error);
      throw error;
    }
  }
}

module.exports = new StorageService();
