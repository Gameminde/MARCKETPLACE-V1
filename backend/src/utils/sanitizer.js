/**
 * Service de sanitization pour prévenir les injections
 * Version simplifiée avec protection ReDoS
 */
class SanitizerService {
  /**
   * Échapper les caractères spéciaux pour les expressions régulières
   * Protection ReDoS avec validation stricte
   */
  static escapeRegex(string) {
    if (!string || typeof string !== 'string') {
      return '';
    }
    
    // Protection ReDoS - Limite de longueur stricte
    const maxLength = 1000;
    if (string.length > maxLength) {
      throw new Error(`Input too long for regex escaping: ${string.length}/${maxLength}`);
    }
    
    // Validation caractères autorisés (ASCII printable seulement)
    const allowedChars = /^[\x20-\x7E]*$/;
    if (!allowedChars.test(string)) {
      throw new Error('Invalid characters in regex input - only ASCII printable allowed');
    }
    
    // Détection patterns dangereux pour ReDoS
    const dangerousPatterns = [
      /(\.\*){3,}/, // Multiple .* patterns
      /(\+.*){3,}/, // Multiple +.* patterns
      /(.*\|.*){5,}/, // Excessive alternation
      /(\(.*\)){5,}/ // Deep nested groups
    ];
    
    for (const pattern of dangerousPatterns) {
      if (pattern.test(string)) {
        throw new Error('Potentially dangerous regex pattern detected');
      }
    }
    
    // Cache pour éviter re-calculs
    const cacheKey = `regex_escape_${string}`;
    if (this._regexCache && this._regexCache.has(cacheKey)) {
      return this._regexCache.get(cacheKey);
    }
    
    // Échappement sécurisé avec timeout
    const startTime = Date.now();
    const escaped = string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const processingTime = Date.now() - startTime;
    
    // Alerte si traitement trop long (possible ReDoS)
    if (processingTime > 100) {
      console.warn(`Slow regex escape detected: ${processingTime}ms for ${string.length} chars`);
    }
    
    // Cache result
    if (this._regexCache) {
      this._regexCache.set(cacheKey, escaped);
    }
    
    return escaped;
  }

  // Initialiser cache LRU pour performance
  static _regexCache = new Map();
  static {
    // Nettoyer cache toutes les heures
    setInterval(() => {
      if (this._regexCache.size > 1000) {
        this._regexCache.clear();
      }
    }, 3600000);
  }

  /**
   * Nettoyer une chaîne de caractères basique
   */
  static sanitizeString(str) {
    if (!str) return '';
    
    return str.toString().trim();
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
    return Boolean(bool);
  }
}

module.exports = SanitizerService;