import 'dart:convert';

/// Validation service with comprehensive security checks
class ValidationService {
  // Common weak passwords to reject
  static const List<String> _weakPasswords = [
    'password', '123456', 'qwerty', 'abc123', 'password123',
    'admin', 'letmein', 'welcome', 'monkey', 'dragon'
  ];

  // XSS patterns to detect and sanitize
  static const List<String> _xssPatterns = [
    r'<script[^>]*>.*?</script>',
    r'javascript:',
    r'on\w+\s*=',
    r'<iframe[^>]*>.*?</iframe>',
    r'<object[^>]*>.*?</object>',
    r'<embed[^>]*>.*?</embed>',
  ];

  /// Validate registration data
  ValidationResult validateRegistration(Map<String, String> data) {
    final errors = <String>[];

    // First name validation
    final firstName = data['firstName']?.trim() ?? '';
    if (firstName.isEmpty) {
      errors.add('Le prénom est requis');
    } else if (firstName.length < 2) {
      errors.add('Le prénom doit contenir au moins 2 caractères');
    } else if (!RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$").hasMatch(firstName)) {
      errors.add('Le prénom contient des caractères invalides');
    }

    // Last name validation
    final lastName = data['lastName']?.trim() ?? '';
    if (lastName.isEmpty) {
      errors.add('Le nom est requis');
    } else if (lastName.length < 2) {
      errors.add('Le nom doit contenir au moins 2 caractères');
    } else if (!RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+$").hasMatch(lastName)) {
      errors.add('Le nom contient des caractères invalides');
    }

    // Username validation
    final username = data['username']?.trim() ?? '';
    if (username.isEmpty) {
      errors.add('Le nom d\'utilisateur est requis');
    } else if (username.length < 3) {
      errors.add('Le nom d\'utilisateur doit contenir au moins 3 caractères');
    } else if (username.length > 30) {
      errors.add('Le nom d\'utilisateur ne peut pas dépasser 30 caractères');
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      errors.add('Le nom d\'utilisateur ne peut contenir que des lettres, chiffres et underscores');
    }

    // Email validation
    final email = data['email']?.trim().toLowerCase() ?? '';
    if (!isValidEmail(email)) {
      errors.add('Veuillez entrer un email valide');
    }

    // Password validation
    final password = data['password'] ?? '';
    final passwordValidation = validatePassword(password);
    if (!passwordValidation.isValid) {
      errors.addAll(passwordValidation.errors);
    }

    return ValidationResult(errors.isEmpty, errors);
  }

  /// Validate login data
  ValidationResult validateLogin(String email, String password) {
    final errors = <String>[];

    if (!isValidEmail(email)) {
      errors.add('Veuillez entrer un email valide');
    }

    if (password.trim().isEmpty) {
      errors.add('Le mot de passe est requis');
    }

    return ValidationResult(errors.isEmpty, errors);
  }

  /// Comprehensive password validation
  ValidationResult validatePassword(String password) {
    final errors = <String>[];

    if (password.length < 8) {
      errors.add('Le mot de passe doit contenir au moins 8 caractères');
    }

    if (password.length > 128) {
      errors.add('Le mot de passe ne peut pas dépasser 128 caractères');
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('Le mot de passe doit contenir au moins une majuscule');
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('Le mot de passe doit contenir au moins une minuscule');
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('Le mot de passe doit contenir au moins un chiffre');
    }

    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('Le mot de passe doit contenir au moins un caractère spécial');
    }

    // Check for common weak passwords
    if (_weakPasswords.contains(password.toLowerCase())) {
      errors.add('Ce mot de passe est trop commun. Choisissez un mot de passe plus sécurisé');
    }

    // Check for repeated characters
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) {
      errors.add('Le mot de passe ne doit pas contenir plus de 2 caractères identiques consécutifs');
    }

    return ValidationResult(errors.isEmpty, errors);
  }

  /// Validate email format
  bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    // Basic format check
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email)) {
      return false;
    }

    // Additional security checks
    if (email.length > 254) return false; // RFC 5321 limit
    
    final parts = email.split('@');
    if (parts.length != 2) return false;
    
    final localPart = parts[0];
    final domainPart = parts[1];
    
    // Local part validation
    if (localPart.length > 64) return false; // RFC 5321 limit
    if (localPart.startsWith('.') || localPart.endsWith('.')) return false;
    if (localPart.contains('..')) return false;
    
    // Domain part validation
    if (domainPart.length > 253) return false;
    if (domainPart.startsWith('-') || domainPart.endsWith('-')) return false;
    
    return true;
  }

  /// Sanitize registration data to prevent XSS and injection attacks
  Map<String, String> sanitizeRegistrationData(Map<String, String> data) {
    return data.map((key, value) => MapEntry(key, sanitizeInput(value)));
  }

  /// Sanitize email input
  String sanitizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  /// Sanitize general text input
  String sanitizeInput(String input) {
    if (input.isEmpty) return input;
    
    String sanitized = input.trim();
    
    // Remove potential XSS patterns
    for (final pattern in _xssPatterns) {
      sanitized = sanitized.replaceAll(RegExp(pattern, caseSensitive: false), '');
    }
    
    // Remove null bytes and control characters
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    
    // Limit length to prevent DoS
    if (sanitized.length > 1000) {
      sanitized = sanitized.substring(0, 1000);
    }
    
    return sanitized;
  }

  /// Validate and sanitize profile update data
  ValidationResult validateProfileUpdate(Map<String, dynamic> data) {
    final errors = <String>[];
    final sanitizedData = <String, dynamic>{};

    data.forEach((key, value) {
      if (value is String) {
        final sanitized = sanitizeInput(value);
        sanitizedData[key] = sanitized;
        
        // Validate specific fields
        switch (key) {
          case 'firstName':
          case 'lastName':
            if (sanitized.isNotEmpty && sanitized.length < 2) {
              errors.add('$key doit contenir au moins 2 caractères');
            }
            break;
          case 'bio':
            if (sanitized.length > 500) {
              errors.add('La biographie ne peut pas dépasser 500 caractères');
            }
            break;
        }
      } else {
        sanitizedData[key] = value;
      }
    });

    return ValidationResult(errors.isEmpty, errors, sanitizedData);
  }
}

/// Validation result wrapper
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final Map<String, dynamic>? sanitizedData;

  ValidationResult(this.isValid, this.errors, [this.sanitizedData]);
}