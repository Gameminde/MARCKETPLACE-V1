const multer = require('multer');
const sharp = require('sharp');
const crypto = require('crypto');
const structuredLogger = require('../services/structured-logger.service');

class FileValidationMiddleware {
  constructor() {
    this.allowedImageTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    this.maxFileSize = 5 * 1024 * 1024; // 5MB
    this.maxFiles = 10;
    
    // Configure multer
    this.storage = multer.memoryStorage();
    this.upload = multer({
      storage: this.storage,
      limits: {
        fileSize: this.maxFileSize,
        files: this.maxFiles
      },
      fileFilter: this.fileFilter.bind(this)
    });
  }

  fileFilter(req, file, cb) {
    // Check MIME type
    if (!this.allowedImageTypes.includes(file.mimetype)) {
      const error = new Error('Invalid file type. Only JPEG, PNG, WebP, and GIF are allowed.');
      error.code = 'INVALID_FILE_TYPE';
      return cb(error, false);
    }
    cb(null, true);
  }

  async validateImage(req, res, next) {
    try {
      if (!req.file) {
        return next();
      }

      const file = req.file;
      
      // Validate file size
      if (file.size > this.maxFileSize) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'FILE_TOO_LARGE',
            message: `File size exceeds maximum allowed size of ${this.maxFileSize / (1024 * 1024)}MB`
          }
        });
      }

      // Validate file type using magic bytes
      const isValidType = await this.validateFileType(file.buffer);
      if (!isValidType) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'INVALID_FILE_TYPE',
            message: 'File type validation failed. File may be corrupted or not a valid image.'
          }
        });
      }

      // Process image with Sharp for optimization and validation
      const processedImage = await this.processImage(file.buffer);
      
      // Replace original buffer with processed image
      req.file.buffer = processedImage.buffer;
      req.file.size = processedImage.buffer.length;
      req.file.processed = true;

      structuredLogger.logInfo('FILE_VALIDATION_SUCCESS', {
        originalSize: file.size,
        processedSize: processedImage.buffer.length,
        compressionRatio: ((file.size - processedImage.buffer.length) / file.size * 100).toFixed(2) + '%',
        dimensions: processedImage.metadata
      });

      next();
    } catch (error) {
      structuredLogger.logError('FILE_VALIDATION_FAILED', {
        error: error.message,
        fileName: req.file?.originalname,
        fileSize: req.file?.size
      });

      res.status(400).json({
        success: false,
        error: {
          code: 'FILE_PROCESSING_ERROR',
          message: 'Failed to process uploaded file'
        }
      });
    }
  }

  async validateFileType(buffer) {
    try {
      // Check magic bytes for common image formats
      const magicBytes = buffer.slice(0, 12);
      
      // JPEG: FF D8 FF
      if (magicBytes[0] === 0xFF && magicBytes[1] === 0xD8 && magicBytes[2] === 0xFF) {
        return true;
      }
      
      // PNG: 89 50 4E 47 0D 0A 1A 0A
      if (magicBytes[0] === 0x89 && magicBytes[1] === 0x50 && magicBytes[2] === 0x4E && magicBytes[3] === 0x47) {
        return true;
      }
      
      // WebP: 52 49 46 46 ?? ?? ?? ?? 57 45 42 50
      if (magicBytes[0] === 0x52 && magicBytes[1] === 0x49 && magicBytes[2] === 0x46 && magicBytes[3] === 0x46 &&
          magicBytes[8] === 0x57 && magicBytes[9] === 0x45 && magicBytes[10] === 0x42 && magicBytes[11] === 0x50) {
        return true;
      }
      
      // GIF: 47 49 46 38
      if (magicBytes[0] === 0x47 && magicBytes[1] === 0x49 && magicBytes[2] === 0x46 && magicBytes[3] === 0x38) {
        return true;
      }
      
      return false;
    } catch (error) {
      structuredLogger.logError('FILE_TYPE_VALIDATION_ERROR', { error: error.message });
      return false;
    }
  }

  async processImage(buffer) {
    try {
      const metadata = await sharp(buffer).metadata();
      
      // Resize if too large (max 2048x2048)
      let sharpInstance = sharp(buffer);
      
      if (metadata.width > 2048 || metadata.height > 2048) {
        sharpInstance = sharpInstance.resize(2048, 2048, {
          fit: 'inside',
          withoutEnlargement: true
        });
      }
      
      // Optimize based on format
      if (metadata.format === 'jpeg') {
        sharpInstance = sharpInstance.jpeg({ quality: 85, progressive: true });
      } else if (metadata.format === 'png') {
        sharpInstance = sharpInstance.png({ compressionLevel: 8 });
      } else if (metadata.format === 'webp') {
        sharpInstance = sharpInstance.webp({ quality: 85 });
      }
      
      const processedBuffer = await sharpInstance.toBuffer();
      const processedMetadata = await sharp(processedBuffer).metadata();
      
      return {
        buffer: processedBuffer,
        metadata: {
          width: processedMetadata.width,
          height: processedMetadata.height,
          format: processedMetadata.format,
          size: processedBuffer.length
        }
      };
    } catch (error) {
      throw new Error(`Image processing failed: ${error.message}`);
    }
  }

  // Middleware for single file upload
  single(fieldName) {
    return [
      this.upload.single(fieldName),
      this.validateImage.bind(this)
    ];
  }

  // Middleware for multiple file upload
  array(fieldName, maxCount) {
    return [
      this.upload.array(fieldName, maxCount || this.maxFiles),
      this.validateMultipleImages.bind(this)
    ];
  }

  async validateMultipleImages(req, res, next) {
    try {
      if (!req.files || req.files.length === 0) {
        return next();
      }

      for (let i = 0; i < req.files.length; i++) {
        const file = req.files[i];
        
        // Validate file size
        if (file.size > this.maxFileSize) {
          return res.status(400).json({
            success: false,
            error: {
              code: 'FILE_TOO_LARGE',
              message: `File ${i + 1} exceeds maximum allowed size of ${this.maxFileSize / (1024 * 1024)}MB`
            }
          });
        }

        // Validate file type
        const isValidType = await this.validateFileType(file.buffer);
        if (!isValidType) {
          return res.status(400).json({
            success: false,
            error: {
              code: 'INVALID_FILE_TYPE',
              message: `File ${i + 1} is not a valid image`
            }
          });
        }

        // Process image
        const processedImage = await this.processImage(file.buffer);
        req.files[i].buffer = processedImage.buffer;
        req.files[i].size = processedImage.buffer.length;
        req.files[i].processed = true;
      }

      next();
    } catch (error) {
      structuredLogger.logError('MULTIPLE_FILE_VALIDATION_FAILED', {
        error: error.message,
        fileCount: req.files?.length
      });

      res.status(400).json({
        success: false,
        error: {
          code: 'FILE_PROCESSING_ERROR',
          message: 'Failed to process uploaded files'
        }
      });
    }
  }
}

module.exports = new FileValidationMiddleware();
