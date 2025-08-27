const Joi = require('joi');
const structuredLogger = require('./structured-logger.service');

// SOLID: Single Responsibility - One validator per domain
class SecurityValidatorService {
  constructor(sanitizer, logger) {
    this.sanitizer = sanitizer || this._createSanitizer();
    this.logger = logger || structuredLogger;
    
    // Initialize validation schemas
    this._initializeSchemas();
  }

  // MANDATORY: Comprehensive input validation
  validateUserRegistration(data) {
    const schema = this.schemas.userRegistration;
    
    const { error, value } = schema.validate(data, {
      abortEarly: false,
      stripUnknown: true,
      convert: true
    });

    if (error) {
      this.logger.warn('User registration validation failed', {
        errors: error.details.map(d => ({
          field: d.path.join('.'),
          message: d.message,
          value: d.context?.value
        }))
      });
      throw new ValidationError('Input validation failed', error.details);
    }

    // MANDATORY: Sanitization after validation
    const sanitizedValue = {
      ...value,
      email: value.email.toLowerCase().trim(),
      firstName: this.sanitizer.sanitizeText(value.firstName),
      lastName: this.sanitizer.sanitizeText(value.lastName),
      username: this.sanitizer.sanitizeText(value.username)
    };

    // Additional security checks
    this._performSecurityChecks(sanitizedValue);

    return sanitizedValue;
  }

  validateUserLogin(data) {
    const schema = this.schemas.userLogin;
    
    const { error, value } = schema.validate(data, {
      abortEarly: false,
      stripUnknown: true
    });

    if (error) {
      this.logger.warn('User login validation failed', {
        errors: error.details.map(d => d.message),
        ip: data._clientIP // If available
      });
      throw new ValidationError('Login validation failed', error.details);
    }

    return {
      ...value,
      email: value.email.toLowerCase().trim()
    };
  }

  // MANDATORY: Product validation with security focus
  validateProductData(data) {
    const schema = this.schemas.productData;
    
    const { error, value } = schema.validate(data, {
      abortEarly: false,
      stripUnknown: true
    });

    if (error) {
      this.logger.warn('Product validation failed', {
        errors: error.details.map(d => d.message)
      });
      throw new ValidationError('Product validation failed', error.details);
    }

    // MANDATORY: Content safety check
    this.checkContentSafety(value);

    // Sanitize text fields
    const sanitizedValue = {
      ...value,
      title: this.sanitizer.sanitizeText(value.title),
      description: this.sanitizer.sanitizeHTML(value.description),
      tags: value.tags?.map(tag => this.sanitizer.sanitizeText(tag)) || []
    };

    return sanitizedValue;
  }

  validateShopData(data) {
    const schema = this.schemas.shopData;
    
    const { error, value } = schema.validate(data, {
      abortEarly: false,
      stripUnknown: true
    });

    if (error) {
      throw new ValidationError('Shop validation failed', error.details);
    }

    this.checkContentSafety(value);

    return {
      ...value,
      name: this.sanitizer.sanitizeText(value.name),
      description: this.sanitizer.sanitizeHTML(value.description),
      tags: value.tags?.map(tag => this.sanitizer.sanitizeText(tag)) || []
    };
  }

  validateFileUpload(file, options = {}) {
    const schema = Joi.object({
      originalname: Joi.string().required().max(255),
      mimetype: Joi.string().required().valid(
        ...(options.allowedMimeTypes || [
          'image/jpeg',
          'image/png',
          'image/gif',
          'image/webp'
        ])
      ),
      size: Joi.number().required().max(options.maxSize || 5 * 1024 * 1024), // 5MB default
      buffer: Joi.binary().required()
    });

    const { error, value } = schema.validate(file);

    if (error) {
      throw new ValidationError('File validation failed', error.details);
    }

    // Additional file security checks
    this._validateFileContent(value, options);

    return value;
  }

  // MANDATORY: Content safety validation
  checkContentSafety(data) {
    const forbiddenPatterns = [
      // XSS patterns
      /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi,
      /javascript:/gi,
      /on\w+\s*=/gi,
      /data:text\/html/gi,
      /<iframe\b[^>]*>/gi,
      /<object\b[^>]*>/gi,
      /<embed\b[^>]*>/gi,
      
      // SQL injection patterns
      /(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION)\b)/gi,
      /(--|\/\*|\*\/|;)/g,
      
      // Command injection patterns
      /(\||&|;|`|\$\(|\${)/g,
      
      // Path traversal
      /(\.\.\/|\.\.\\)/g,
      
      // Suspicious URLs
      /(https?:\/\/[^\s]+\.(tk|ml|ga|cf|bit\.ly|tinyurl))/gi
    ];

    const textFields = [
      data.title,
      data.description,
      data.name,
      data.content,
      data.message,
      data.comment
    ].filter(Boolean);

    for (const field of textFields) {
      if (!field) continue;
      
      for (const pattern of forbiddenPatterns) {
        if (pattern.test(field)) {
          this.logger.error('Malicious content detected', {
            pattern: pattern.toString(),
            field: field.substring(0, 100) + '...',
            timestamp: new Date().toISOString()
          });
          throw new SecurityError('Content contains forbidden patterns');
        }
      }
    }

    // Check for suspicious file extensions in text
    const suspiciousExtensions = /\.(exe|bat|cmd|scr|pif|com|vbs|js|jar|php|asp|jsp)$/gi;
    for (const field of textFields) {
      if (suspiciousExtensions.test(field)) {
        throw new SecurityError('Content contains suspicious file references');
      }
    }
  }

  // Rate limiting validation
  validateRateLimit(identifier, action, windowMs = 15 * 60 * 1000, maxAttempts = 5) {
    // This would integrate with Redis in production
    const key = `rate_limit:${action}:${identifier}`;
    
    // For now, return validation result
    // In production, this would check Redis
    return {
      allowed: true,
      remaining: maxAttempts - 1,
      resetTime: Date.now() + windowMs
    };
  }

  // Initialize validation schemas
  _initializeSchemas() {
    this.schemas = {
      userRegistration: Joi.object({
        firstName: Joi.string()
          .trim()
          .min(2)
          .max(50)
          .pattern(/^[a-zA-ZÀ-ÿ\s\-']+$/)
          .required()
          .messages({
            'string.pattern.base': 'First name contains invalid characters',
            'string.min': 'First name must be at least 2 characters',
            'string.max': 'First name cannot exceed 50 characters'
          }),
        
        lastName: Joi.string()
          .trim()
          .min(2)
          .max(50)
          .pattern(/^[a-zA-ZÀ-ÿ\s\-']+$/)
          .required(),
        
        username: Joi.string()
          .trim()
          .min(3)
          .max(30)
          .pattern(/^[a-zA-Z0-9_]+$/)
          .required()
          .messages({
            'string.pattern.base': 'Username can only contain letters, numbers, and underscores'
          }),
        
        email: Joi.string()
          .email({ minDomainSegments: 2, tlds: { allow: true } })
          .max(100)
          .required(),
        
        password: Joi.string()
          .min(8)
          .max(128)
          .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
          .required()
          .messages({
            'string.pattern.base': 'Password must contain uppercase, lowercase, number, and special character'
          })
      }),

      userLogin: Joi.object({
        email: Joi.string()
          .email()
          .required(),
        password: Joi.string()
          .min(1)
          .required()
      }),

      productData: Joi.object({
        title: Joi.string()
          .trim()
          .min(3)
          .max(200)
          .required(),
        
        description: Joi.string()
          .trim()
          .min(10)
          .max(5000)
          .required(),
        
        price: Joi.number()
          .positive()
          .precision(2)
          .max(999999.99)
          .required(),
        
        category: Joi.string()
          .valid('electronics', 'clothing', 'books', 'home', 'sports', 'beauty', 'toys', 'other')
          .required(),
        
        tags: Joi.array()
          .items(Joi.string().max(30).pattern(/^[a-zA-Z0-9\s\-_]+$/))
          .max(10)
          .optional(),
        
        images: Joi.array()
          .items(Joi.string().uri())
          .max(5)
          .optional(),
        
        stock: Joi.number()
          .integer()
          .min(0)
          .max(999999)
          .optional(),
        
        weight: Joi.number()
          .positive()
          .max(1000)
          .optional(),
        
        dimensions: Joi.object({
          length: Joi.number().positive().max(1000),
          width: Joi.number().positive().max(1000),
          height: Joi.number().positive().max(1000)
        }).optional()
      }),

      shopData: Joi.object({
        name: Joi.string()
          .trim()
          .min(3)
          .max(100)
          .required(),
        
        description: Joi.string()
          .trim()
          .min(10)
          .max(2000)
          .required(),
        
        category: Joi.string()
          .valid('electronics', 'fashion', 'home', 'books', 'sports', 'beauty', 'food', 'other')
          .required(),
        
        tags: Joi.array()
          .items(Joi.string().max(30))
          .max(10)
          .optional(),
        
        address: Joi.string()
          .max(200)
          .optional(),
        
        phone: Joi.string()
          .pattern(/^[\+]?[1-9][\d]{0,15}$/)
          .optional(),
        
        email: Joi.string()
          .email()
          .optional(),
        
        website: Joi.string()
          .uri()
          .optional()
      })
    };
  }

  _performSecurityChecks(data) {
    // Check for common attack patterns in usernames
    const suspiciousPatterns = [
      /admin/i,
      /root/i,
      /system/i,
      /test/i,
      /null/i,
      /undefined/i,
      /<script/i,
      /javascript/i
    ];

    if (data.username) {
      for (const pattern of suspiciousPatterns) {
        if (pattern.test(data.username)) {
          throw new SecurityError('Username contains suspicious patterns');
        }
      }
    }

    // Check for disposable email domains
    if (data.email) {
      const disposableEmailDomains = [
        '10minutemail.com',
        'tempmail.org',
        'guerrillamail.com',
        'mailinator.com'
      ];
      
      const emailDomain = data.email.split('@')[1]?.toLowerCase();
      if (disposableEmailDomains.includes(emailDomain)) {
        this.logger.warn('Disposable email detected', { email: data.email });
        // Don't throw error, just log for monitoring
      }
    }
  }

  _validateFileContent(file, options) {
    // Check file signature (magic bytes)
    const buffer = file.buffer;
    const signatures = {
      'image/jpeg': [0xFF, 0xD8, 0xFF],
      'image/png': [0x89, 0x50, 0x4E, 0x47],
      'image/gif': [0x47, 0x49, 0x46],
      'image/webp': [0x52, 0x49, 0x46, 0x46]
    };

    const signature = signatures[file.mimetype];
    if (signature) {
      const fileSignature = Array.from(buffer.slice(0, signature.length));
      if (!signature.every((byte, index) => byte === fileSignature[index])) {
        throw new SecurityError('File signature does not match declared type');
      }
    }

    // Check for embedded scripts in images
    const suspiciousContent = [
      '<script',
      'javascript:',
      'data:text/html',
      '<?php'
    ];

    const fileContent = buffer.toString('utf8', 0, Math.min(1024, buffer.length));
    for (const content of suspiciousContent) {
      if (fileContent.toLowerCase().includes(content)) {
        throw new SecurityError('File contains suspicious content');
      }
    }
  }

  _createSanitizer() {
    return {
      sanitizeText: (text) => {
        if (!text) return text;
        // Simple text sanitization - remove HTML tags and dangerous characters
        return text
          .replace(/<[^>]*>/g, '') // Remove HTML tags
          .replace(/[<>'"&]/g, '') // Remove dangerous characters
          .trim();
      },
      
      sanitizeHTML: (html) => {
        if (!html) return html;
        // Simple HTML sanitization - allow only basic formatting
        return html
          .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
          .replace(/<iframe\b[^>]*>/gi, '')
          .replace(/<object\b[^>]*>/gi, '')
          .replace(/<embed\b[^>]*>/gi, '')
          .replace(/javascript:/gi, '')
          .replace(/on\w+\s*=/gi, '')
          .trim();
      }
    };
  }
}

// Custom error classes
class ValidationError extends Error {
  constructor(message, details) {
    super(message);
    this.name = 'ValidationError';
    this.details = details;
    this.statusCode = 400;
  }
}

class SecurityError extends Error {
  constructor(message) {
    super(message);
    this.name = 'SecurityError';
    this.statusCode = 403;
  }
}

module.exports = {
  SecurityValidatorService,
  ValidationError,
  SecurityError
};