const mongoSanitize = require('express-mongo-sanitize');
const validator = require('validator');
const DOMPurify = require('isomorphic-dompurify');

/**
 * Service de sanitization pour prévenir les injections
 */
class SanitizerService {
  /**
   * Nettoyer les entrées pour MongoDB (prévenir NoSQL injection)
   */
  static sanitizeMongoInput(input) {
    if (input === null || input === undefined) {
      return input;
    }

    if (typeof input === 'string') {
      // Supprimer les opérateurs MongoDB dangereux
      return input
        .replace(/[$]/g, '')
        .replace(/\./g, '')
        .replace(/[{}]/g, '');
    }

    if (Array.isArray(input)) {
      return input.map(item => this.sanitizeMongoInput(item));
    }

    if (typeof input === 'object') {
      const sanitized = {};
      for (const key in input) {
        // Supprimer les clés commençant par $ ou contenant .
        if (!key.startsWith('$') && !key.includes('.')) {
          sanitized[key] = this.sanitizeMongoInput(input[key]);
        }
      }
      return sanitized;
    }

    return input;
  }

  /**
   * Nettoyer les entrées HTML (prévenir XSS)
   */
  static sanitizeHTML(input) {
    if (!input) return '';
    
    // Configuration DOMPurify stricte
    const config = {
      ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'p', 'br'],
      ALLOWED_ATTR: [],
      ALLOW_DATA_ATTR: false,
      FORBID_TAGS: ['script', 'style', 'iframe', 'object', 'embed', 'link'],
      FORBID_ATTR: ['onerror', 'onload', 'onclick', 'onmouseover']
    };
    
    return DOMPurify.sanitize(input, config);
  }

  /**
   * Valider et nettoyer un email
   */
  static sanitizeEmail(email) {
    if (!email) return null;
    
    const trimmed = email.trim().toLowerCase();
    
    if (!validator.isEmail(trimmed)) {
      throw new Error('Invalid email format');
    }
    
    return validator.normalizeEmail(trimmed, {
      gmail_remove_dots: false,
      gmail_remove_subaddress: false,
      outlookdotcom_remove_subaddress: false,
      yahoo_remove_subaddress: false,
      icloud_remove_subaddress: false
    });
  }

  /**
   * Valider et nettoyer une URL
   */
  static sanitizeURL(url) {
    if (!url) return null;
    
    const trimmed = url.trim();
    
    if (!validator.isURL(trimmed, {
      protocols: ['http', 'https'],
      require_protocol: true,
      require_valid_protocol: true,
      require_host: true,
      require_port: false,
      allow_query_components: true,
      allow_fragments: true,
      allow_protocol_relative_urls: false
    })) {
      throw new Error('Invalid URL format');
    }
    
    return trimmed;
  }

  /**
   * Valider et nettoyer un numéro de téléphone
   */
  static sanitizePhone(phone) {
    if (!phone) return null;
    
    // Supprimer tous les caractères non numériques sauf +
    const cleaned = phone.replace(/[^\d+]/g, '');
    
    if (!validator.isMobilePhone(cleaned, 'any')) {
      throw new Error('Invalid phone number');
    }
    
    return cleaned;
  }

  /**
   * Échapper les caractères spéciaux pour regex
   */
  static escapeRegex(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  /**
   * Valider et nettoyer un nom d'utilisateur
   */
  static sanitizeUsername(username) {
    if (!username) return null;
    
    // Autoriser uniquement lettres, chiffres, underscore et tiret
    const cleaned = username.trim().replace(/[^a-zA-Z0-9_-]/g, '');
    
    if (cleaned.length < 3 || cleaned.length > 30) {
      throw new Error('Username must be between 3 and 30 characters');
    }
    
    return cleaned;
  }

  /**
   * Nettoyer un objet complet
   */
  static sanitizeObject(obj, schema = {}) {
    const sanitized = {};
    
    for (const key in schema) {
      if (obj.hasOwnProperty(key)) {
        const value = obj[key];
        const type = schema[key];
        
        switch (type) {
          case 'string':
            sanitized[key] = this.sanitizeString(value);
            break;
          case 'email':
            sanitized[key] = this.sanitizeEmail(value);
            break;
          case 'url':
            sanitized[key] = this.sanitizeURL(value);
            break;
          case 'phone':
            sanitized[key] = this.sanitizePhone(value);
            break;
          case 'html':
            sanitized[key] = this.sanitizeHTML(value);
            break;
          case 'username':
            sanitized[key] = this.sanitizeUsername(value);
            break;
          case 'number':
            sanitized[key] = this.sanitizeNumber(value);
            break;
          case 'boolean':
            sanitized[key] = this.sanitizeBoolean(value);
            break;
          case 'array':
            sanitized[key] = Array.isArray(value) ? value : [];
            break;
          case 'object':
            sanitized[key] = typeof value === 'object' ? this.sanitizeMongoInput(value) : {};
            break;
          default:
            sanitized[key] = value;
        }
      }
    }
    
    return sanitized;
  }

  /**
   * Nettoyer une chaîne de caractères basique
   */
  static sanitizeString(str) {
    if (!str) return '';
    
    return validator.escape(str.toString().trim());
  }

  /**
   * Valider et nettoyer un nombre
   */
  static sanitizeNumber(num) {
    const parsed = parseFloat(num);
    
    if (isNaN(parsed)) {
      throw new Error('Invalid number');
    }
    
    return parsed;
  }

  /**
   * Valider et nettoyer un booléen
   */
  static sanitizeBoolean(bool) {
    return validator.toBoolean(bool.toString());
  }

  /**
   * Nettoyer les paramètres de requête
   */
  static sanitizeQuery(query) {
    const sanitized = {};
    
    for (const key in query) {
      // Supprimer les clés dangereuses
      if (!key.startsWith('$') && !key.includes('.')) {
        const value = query[key];
        
        // Nettoyer les valeurs
        if (typeof value === 'string') {
          sanitized[key] = this.sanitizeString(value);
        } else if (Array.isArray(value)) {
          sanitized[key] = value.map(v => 
            typeof v === 'string' ? this.sanitizeString(v) : v
          );
        } else {
          sanitized[key] = value;
        }
      }
    }
    
    return sanitized;
  }

  /**
   * Valider un UUID
   */
  static validateUUID(uuid) {
    if (!validator.isUUID(uuid)) {
      throw new Error('Invalid UUID format');
    }
    return uuid;
  }

  /**
   * Valider une date
   */
  static validateDate(date) {
    const parsed = new Date(date);
    
    if (isNaN(parsed.getTime())) {
      throw new Error('Invalid date format');
    }
    
    return parsed.toISOString();
  }

  /**
   * Nettoyer les chemins de fichiers
   */
  static sanitizePath(filePath) {
    if (!filePath) return '';
    
    // Supprimer les caractères dangereux
    return filePath
      .replace(/\.\./g, '') // Prévenir directory traversal
      .replace(/[<>:"|?*]/g, '') // Caractères Windows interdits
      .replace(/\x00-\x1f/g, ''); // Caractères de contrôle
  }
}

/**
 * Middleware Express pour sanitization automatique
 */
const sanitizationMiddleware = (options = {}) => {
  const {
    sanitizeBody = true,
    sanitizeQuery = true,
    sanitizeParams = true,
    removeKeys = ['$where', '__proto__', 'constructor', 'prototype']
  } = options;

  return (req, res, next) => {
    try {
      // Sanitizer le body
      if (sanitizeBody && req.body) {
        req.body = SanitizerService.sanitizeMongoInput(req.body);
        
        // Supprimer les clés dangereuses
        removeKeys.forEach(key => {
          delete req.body[key];
        });
      }

      // Sanitizer les query params
      if (sanitizeQuery && req.query) {
        req.query = SanitizerService.sanitizeQuery(req.query);
      }

      // Sanitizer les params
      if (sanitizeParams && req.params) {
        for (const key in req.params) {
          if (typeof req.params[key] === 'string') {
            req.params[key] = SanitizerService.sanitizeString(req.params[key]);
          }
        }
      }

      next();
    } catch (error) {
      return res.status(400).json({
        success: false,
        message: 'Invalid input data',
        error: error.message
      });
    }
  };
};

/**
 * Middleware MongoDB Sanitize configuré
 */
const mongoSanitizeMiddleware = mongoSanitize({
  replaceWith: '_',
  onSanitize: ({ req, key }) => {
    console.warn(`[SECURITY] Attempted NoSQL injection detected: ${key} from IP: ${req.ip}`);
  }
});

module.exports = {
  SanitizerService,
  sanitizationMiddleware,
  mongoSanitizeMiddleware
};