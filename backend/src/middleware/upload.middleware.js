const multer = require('multer');
const path = require('path');
const crypto = require('crypto');
const fs = require('fs').promises;
const sharp = require('sharp');
const structuredLogger = require('../services/structured-logger.service');

// Configuration de stockage sécurisé
const storage = multer.diskStorage({
  destination: async (req, file, cb) => {
    const uploadPath = path.join(__dirname, '../../uploads/temp/');
    
    // Créer le dossier s'il n'existe pas
    try {
      await fs.mkdir(uploadPath, { recursive: true });
      cb(null, uploadPath);
    } catch (error) {
      cb(error);
    }
  },
  filename: (req, file, cb) => {
    // Générer un nom unique cryptographiquement sécurisé
    const uniqueName = crypto.randomBytes(32).toString('hex');
    const ext = path.extname(file.originalname).toLowerCase();
    const sanitizedExt = ext.replace(/[^a-z0-9.]/gi, '');
    cb(null, `${uniqueName}${sanitizedExt}`);
  }
});

// Validation stricte des types de fichiers avec protection MIME spoofing
const fileFilter = async (req, file, cb) => {
  try {
    // 1. Vérifier extension
    const allowedExtensions = /\.(jpeg|jpg|png|webp|gif)$/i;
    if (!allowedExtensions.test(path.extname(file.originalname))) {
      return cb(new Error('Invalid file extension'));
    }
    
    // 2. Vérifier magic numbers (file signature) pour détecter MIME spoofing
    let buffer;
    if (file.buffer) {
      buffer = file.buffer;
    } else if (file.path) {
      buffer = await fs.readFile(file.path);
    } else {
      return cb(new Error('File data not available'));
    }
    
    // Magic numbers complets pour les formats d'image (signatures complètes)
    const magicNumbers = {
      jpeg: [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00],
      png: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52],
      webp: [0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50, 0x56, 0x50, 0x38],
      gif: [0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
    };
    
    let detectedFormat = null;
    for (const [format, signature] of Object.entries(magicNumbers)) {
      if (signature.every((byte, index) => buffer[index] === byte)) {
        detectedFormat = format;
        break;
      }
    }
    
    if (!detectedFormat) {
      return cb(new Error('File content does not match expected image format'));
    }
    
    // 3. Vérifier MIME type vs contenu réel
    const allowedMimes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    const expectedMime = `image/${detectedFormat === 'jpeg' ? 'jpeg' : detectedFormat}`;
    
    if (!allowedMimes.includes(file.mimetype) || file.mimetype !== expectedMime) {
      return cb(new Error('MIME type does not match file content'));
    }
    
    // 4. Vérifier le nom de fichier pour les caractères dangereux et path traversal
    const dangerousChars = /[<>:"|?*\x00-\x1f]/g;
    if (dangerousChars.test(file.originalname)) {
      return cb(new Error('Filename contains invalid characters'));
    }
    
    // Protection path traversal stricte
    if (file.originalname.includes('..') || file.originalname.includes('/') || file.originalname.includes('\\')) {
      return cb(new Error('Path traversal attack detected'));
    }
    
    // Bloquer les extensions dangereuses
    const dangerousExtensions = ['.exe', '.bat', '.cmd', '.com', '.pif', '.scr', '.vbs', '.js', '.php', '.asp'];
    const fileExt = path.extname(file.originalname).toLowerCase();
    if (dangerousExtensions.includes(fileExt)) {
      return cb(new Error('Dangerous file extension not allowed'));
    }
    
    // 5. Log de l'upload pour audit
    structuredLogger.logInfo('FILE_UPLOAD_ATTEMPT', {
      userId: req.user?.sub,
      originalName: file.originalname,
      mimeType: file.mimetype,
      detectedFormat,
      size: file.size
    });
    
    cb(null, true);
  } catch (error) {
    cb(new Error('File validation failed: ' + error.message));
  }
};

// Configuration Multer avec limites strictes
const upload = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB max
    files: 5, // Maximum 5 fichiers par requête
    fields: 10, // Maximum 10 champs
    parts: 20 // Maximum 20 parties (fields + files)
  },
  fileFilter
});

// Middleware de validation post-upload
const validateUploadedFile = async (req, res, next) => {
  if (!req.file && !req.files) {
    return next();
  }
  
  const files = req.files || [req.file];
  
  try {
    for (const file of files) {
      // Vérifier la taille réelle du fichier
      const stats = await fs.stat(file.path);
      if (stats.size > 5 * 1024 * 1024) {
        await fs.unlink(file.path);
        return res.status(400).json({
          success: false,
          message: 'File size exceeds maximum allowed size'
        });
      }
      
      // Vérifier le contenu réel du fichier avec Sharp
      try {
        const metadata = await sharp(file.path).metadata();
        
        // Vérifier les dimensions
        if (metadata.width > 4096 || metadata.height > 4096) {
          await fs.unlink(file.path);
          return res.status(400).json({
            success: false,
            message: 'Image dimensions exceed maximum allowed (4096x4096)'
          });
        }
        
        // Ajouter les métadonnées au fichier
        file.metadata = {
          width: metadata.width,
          height: metadata.height,
          format: metadata.format,
          space: metadata.space,
          channels: metadata.channels,
          hasAlpha: metadata.hasAlpha
        };
        
      } catch (sharpError) {
        // Le fichier n'est pas une image valide
        await fs.unlink(file.path);
        structuredLogger.logError('INVALID_IMAGE_UPLOAD', {
          userId: req.user?.sub,
          filename: file.filename,
          error: sharpError.message
        });
        return res.status(400).json({
          success: false,
          message: 'Invalid image file'
        });
      }
    }
    
    next();
  } catch (error) {
    structuredLogger.logError('FILE_VALIDATION_ERROR', {
      userId: req.user?.sub,
      error: error.message
    });
    
    // Nettoyer les fichiers en cas d'erreur
    for (const file of files) {
      try {
        await fs.unlink(file.path);
      } catch (unlinkError) {
        // Ignorer les erreurs de suppression
      }
    }
    
    return res.status(500).json({
      success: false,
      message: 'File validation failed'
    });
  }
};

// Service de traitement d'images sécurisé
class ImageProcessingService {
  /**
   * Optimiser et sécuriser une image
   */
  static async processImage(inputPath, outputPath, options = {}) {
    try {
      const {
        width = 1200,
        height = 1200,
        quality = 85,
        format = 'webp'
      } = options;
      
      // Créer le dossier de sortie si nécessaire
      const outputDir = path.dirname(outputPath);
      await fs.mkdir(outputDir, { recursive: true });
      
      // Traiter l'image
      await sharp(inputPath)
        .resize(width, height, {
          fit: 'inside',
          withoutEnlargement: true
        })
        .toFormat(format, { quality })
        .toFile(outputPath);
      
      // Supprimer le fichier temporaire
      await fs.unlink(inputPath);
      
      structuredLogger.logInfo('IMAGE_PROCESSED', {
        inputPath,
        outputPath,
        format,
        dimensions: `${width}x${height}`
      });
      
      return outputPath;
    } catch (error) {
      structuredLogger.logError('IMAGE_PROCESSING_ERROR', {
        inputPath,
        error: error.message
      });
      throw error;
    }
  }
  
  /**
   * Générer des miniatures
   */
  static async generateThumbnails(imagePath, sizes = []) {
    // Valider le chemin d'entrée contre path traversal
    const normalizedPath = path.normalize(imagePath);
    if (normalizedPath.includes('..') || !normalizedPath.startsWith(path.resolve('./uploads'))) {
      throw new Error('Invalid image path - potential path traversal attack');
    }
    
    const thumbnails = [];
    const defaultSizes = sizes.length > 0 ? sizes : [
      { name: 'thumb', width: 150, height: 150 },
      { name: 'small', width: 300, height: 300 },
      { name: 'medium', width: 600, height: 600 }
    ];
    
    try {
      for (const size of defaultSizes) {
        // Sécuriser le nom de taille
        const safeSizeName = size.name.replace(/[^a-zA-Z0-9]/g, '');
        if (!safeSizeName || safeSizeName.length === 0) {
          throw new Error('Invalid size name');
        }
        
        const ext = path.extname(imagePath);
        const basename = path.basename(imagePath, ext);
        const dirname = path.dirname(imagePath);
        
        // Construire le chemin sécurisé
        const thumbPath = path.join(dirname, `${basename}_${safeSizeName}${ext}`);
        
        // Vérifier que le chemin de sortie est valide
        const normalizedThumbPath = path.normalize(thumbPath);
        if (!normalizedThumbPath.startsWith(path.resolve('./uploads'))) {
          throw new Error('Invalid thumbnail path');
        }
        
        await sharp(imagePath)
          .resize(size.width, size.height, {
            fit: 'cover',
            position: 'center'
          })
          .toFile(thumbPath);
        
        thumbnails.push({
          name: safeSizeName,
          path: thumbPath,
          width: size.width,
          height: size.height
        });
      }
      
      return thumbnails;
    } catch (error) {
      // Nettoyer les thumbnails partiels en cas d'erreur
      for (const thumb of thumbnails) {
        try {
          await fs.unlink(thumb.path);
        } catch {}
      }
      throw error;
    }
  }
  
  /**
   * Scanner une image pour du contenu inapproprié (placeholder)
   */
  static async scanForInappropriateContent(imagePath) {
    // TODO: Intégrer avec Google Vision API ou autre service
    // Pour l'instant, retourner toujours true
    return {
      safe: true,
      confidence: 1.0,
      labels: []
    };
  }
}

// Middleware de nettoyage automatique
const cleanupOldFiles = async () => {
  const tempDir = path.join(__dirname, '../../uploads/temp/');
  const maxAge = 24 * 60 * 60 * 1000; // 24 heures
  
  try {
    const files = await fs.readdir(tempDir);
    const now = Date.now();
    
    for (const file of files) {
      const filePath = path.join(tempDir, file);
      const stats = await fs.stat(filePath);
      
      if (now - stats.mtimeMs > maxAge) {
        await fs.unlink(filePath);
        structuredLogger.logInfo('OLD_FILE_CLEANED', {
          filename: file,
          age: Math.floor((now - stats.mtimeMs) / 1000 / 60 / 60) + ' hours'
        });
      }
    }
  } catch (error) {
    structuredLogger.logError('CLEANUP_ERROR', {
      error: error.message
    });
  }
};

// Lancer le nettoyage toutes les heures
setInterval(cleanupOldFiles, 60 * 60 * 1000);

// Middleware de limitation de débit pour uploads
const uploadRateLimiter = require('express-rate-limit')({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // Maximum 10 uploads par fenêtre
  message: 'Too many uploads from this IP, please try again later',
  standardHeaders: true,
  legacyHeaders: false
});

module.exports = {
  upload,
  validateUploadedFile,
  ImageProcessingService,
  uploadRateLimiter,
  
  // Middlewares pré-configurés
  uploadSingle: (fieldName) => upload.single(fieldName),
  uploadMultiple: (fieldName, maxCount = 5) => upload.array(fieldName, maxCount),
  uploadFields: (fields) => upload.fields(fields),
  
  // Middleware combiné sécurisé
  secureUpload: (fieldName, options = {}) => {
    return [
      uploadRateLimiter,
      upload.single(fieldName),
      validateUploadedFile
    ];
  },
  
  secureMultiUpload: (fieldName, maxCount = 5) => {
    return [
      uploadRateLimiter,
      upload.array(fieldName, maxCount),
      validateUploadedFile
    ];
  }
};