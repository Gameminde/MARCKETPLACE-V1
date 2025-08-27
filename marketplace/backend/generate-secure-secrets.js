const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

console.log('🔐 GÉNÉRATEUR DE SECRETS SÉCURISÉS - MARKETPLACE EMERGENCY PROTOCOL');
console.log('=================================================================\n');

/**
 * PHASE 1: CRITICAL SECURITY EMERGENCY - CREDENTIAL GENERATION
 * Generates cryptographically secure secrets with entropy ≥ 256 bits
 */

function generateSecureSecret(length = 64) {
  return crypto.randomBytes(length).toString('hex');
}

function generateJWTSecret() {
  // Generate 512-bit (64 bytes) secret for maximum security
  return crypto.randomBytes(64).toString('base64url');
}

function generateEncryptionKey() {
  // Generate AES-256 compatible key
  return crypto.randomBytes(32).toString('hex');
}

function generateAPISigningSecret() {
  // Generate HMAC-SHA256 compatible secret
  return crypto.randomBytes(64).toString('hex');
}

console.log('🔒 GÉNÉRATION DES SECRETS CRYPTOGRAPHIQUES...\n');

const secrets = {
  // JWT Secrets - Separate for access and refresh tokens
  JWT_SECRET: generateJWTSecret(),
  JWT_REFRESH_SECRET: generateJWTSecret(),
  
  // Session and encryption
  SESSION_SECRET: generateSecureSecret(32),
  ENCRYPTION_KEY: generateEncryptionKey(),
  
  // API Security
  API_SIGNING_SECRET: generateAPISigningSecret(),
  
  // Database encryption key
  DB_ENCRYPTION_KEY: generateSecureSecret(32),
  
  // Rate limiting key
  RATE_LIMIT_SECRET: generateSecureSecret(16),
  
  // CSRF protection
  CSRF_SECRET: generateSecureSecret(32)
};

console.log('✅ Secrets générés avec succès:');
Object.keys(secrets).forEach(key => {
  const secretLength = secrets[key].length;
  const entropy = secretLength * 4; // Approximate entropy in bits
  console.log(`   ${key}: ${secretLength} caractères (${entropy} bits d'entropie)`);
});

// Create .env.example template
const envTemplate = `# ===================================================
# MARKETPLACE - ENVIRONMENT CONFIGURATION TEMPLATE
# ===================================================
# CRITICAL: NEVER commit real values to version control
# Copy this file to .env and replace with actual values

# ===================================================
# DATABASE CONFIGURATION
# ===================================================
MONGODB_URI=mongodb://localhost:27017/marketplace_dev
POSTGRES_URI=your-postgresql-connection-string-here

# ===================================================
# JWT SECURITY (GENERATED AUTOMATICALLY)
# ===================================================
JWT_SECRET=${secrets.JWT_SECRET}
JWT_REFRESH_SECRET=${secrets.JWT_REFRESH_SECRET}
JWT_EXPIRE=15m
JWT_REFRESH_EXPIRE=7d

# ===================================================
# SESSION & ENCRYPTION
# ===================================================
SESSION_SECRET=${secrets.SESSION_SECRET}
ENCRYPTION_KEY=${secrets.ENCRYPTION_KEY}
DB_ENCRYPTION_KEY=${secrets.DB_ENCRYPTION_KEY}

# ===================================================
# API SECURITY
# ===================================================
API_SIGNING_SECRET=${secrets.API_SIGNING_SECRET}
RATE_LIMIT_SECRET=${secrets.RATE_LIMIT_SECRET}
CSRF_SECRET=${secrets.CSRF_SECRET}

# ===================================================
# EXTERNAL SERVICES (REPLACE WITH REAL VALUES)
# ===================================================
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

GEMINI_API_KEY=your-gemini-api-key
GOOGLE_VISION_PROJECT_ID=your-project-id
GOOGLE_APPLICATION_CREDENTIALS=path/to/your/credentials.json

STRIPE_SECRET_KEY=your-stripe-secret-key-here

# ===================================================
# APPLICATION CONFIGURATION
# ===================================================
PORT=3001
NODE_ENV=development
AI_VALIDATION_ENABLED=true
AI_TIMEOUT=30000

# ===================================================
# SECURITY HEADERS
# ===================================================
CORS_ORIGIN=http://localhost:3000
ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# ===================================================
# LOGGING & MONITORING
# ===================================================
LOG_LEVEL=info
LOG_FILE=logs/app.log
ENABLE_REQUEST_LOGGING=true
`;

// Write .env.example
try {
  fs.writeFileSync('.env.example', envTemplate);
  console.log('\n✅ Fichier .env.example créé avec succès');
} catch (error) {
  console.error('❌ Erreur lors de la création de .env.example:', error.message);
}

// Create .env.development for local development
const envDevelopment = envTemplate.replace(/your-/g, 'dev-placeholder-');

try {
  fs.writeFileSync('.env.development', envDevelopment);
  console.log('✅ Fichier .env.development créé avec succès');
} catch (error) {
  console.error('❌ Erreur lors de la création de .env.development:', error.message);
}

// Update .gitignore to ensure security
const gitignorePath = path.join(__dirname, '.gitignore');
try {
  let gitignoreContent = '';
  if (fs.existsSync(gitignorePath)) {
    gitignoreContent = fs.readFileSync(gitignorePath, 'utf8');
  }
  
  const securityPatterns = [
    '# Environment secrets - CRITICAL SECURITY',
    '.env',
    '.env.*',
    '!.env.example',
    '',
    '# Google Cloud credentials - CRITICAL SECURITY',
    '*.json',
    '!package.json',
    '!package-lock.json',
    '!**/templates.json',
    '',
    '# API Keys and secrets',
    'secrets/',
    'credentials/',
    '*.key',
    '*.pem',
    '*.p12',
    '*.pfx',
    '',
    '# Backup files that might contain secrets',
    '*.backup',
    '*.bak',
    '*.old',
    '*.tmp'
  ];
  
  let updated = false;
  securityPatterns.forEach(pattern => {
    if (!gitignoreContent.includes(pattern)) {
      gitignoreContent += `\n${pattern}`;
      updated = true;
    }
  });
  
  if (updated) {
    fs.writeFileSync(gitignorePath, gitignoreContent);
    console.log('✅ .gitignore mis à jour avec les règles de sécurité');
  } else {
    console.log('✅ .gitignore déjà configuré correctement');
  }
} catch (gitignoreError) {
  console.warn('⚠️ Erreur lors de la mise à jour de .gitignore:', gitignoreError.message);
}

// Create security validation script
const securityValidationScript = `#!/usr/bin/env node
/**
 * SECURITY VALIDATION SCRIPT
 * Validates that no secrets are exposed in the codebase
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

console.log('🔍 VALIDATION DE SÉCURITÉ - MARKETPLACE');
console.log('=====================================\\n');

const DANGEROUS_PATTERNS = [
  /mongodb\+srv:\/\/[^\\s]+/gi,
  /postgresql:\/\/[^\\s]+/gi,
  /sk_test_[a-zA-Z0-9]+/gi,
  /sk_live_[a-zA-Z0-9]+/gi,
  /AIzaSy[a-zA-Z0-9_-]+/gi,
  /AKIA[0-9A-Z]{16}/gi,
  /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi
];

function scanFile(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const violations = [];
    
    DANGEROUS_PATTERNS.forEach((pattern, index) => {
      const matches = content.match(pattern);
      if (matches) {
        violations.push({
          pattern: index,
          matches: matches.length,
          file: filePath
        });
      }
    });
    
    return violations;
  } catch (error) {
    return [];
  }
}

function scanDirectory(dir, violations = []) {
  const files = fs.readdirSync(dir);
  
  files.forEach(file => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    
    if (stat.isDirectory() && !file.startsWith('.') && file !== 'node_modules') {
      scanDirectory(filePath, violations);
    } else if (stat.isFile() && (file.endsWith('.js') || file.endsWith('.json') || file.endsWith('.env'))) {
      const fileViolations = scanFile(filePath);
      violations.push(...fileViolations);
    }
  });
  
  return violations;
}

const violations = scanDirectory('.');

if (violations.length === 0) {
  console.log('✅ AUCUNE VIOLATION DE SÉCURITÉ DÉTECTÉE');
  console.log('✅ Tous les secrets semblent être correctement protégés');
} else {
  console.log('❌ VIOLATIONS DE SÉCURITÉ DÉTECTÉES:');
  violations.forEach(violation => {
    console.log(\`   📁 \${violation.file}: \${violation.matches} pattern(s) dangereux\`);
  });
  console.log('\\n🚨 ACTION REQUISE: Supprimez immédiatement les secrets exposés!');
  process.exit(1);
}

console.log('\\n🔒 VALIDATION TERMINÉE');
`;

try {
  fs.writeFileSync('security-scan.js', securityValidationScript);
  console.log('✅ Script de validation de sécurité créé');
} catch (error) {
  console.error('❌ Erreur lors de la création du script de sécurité:', error.message);
}

console.log('\n🔒 PHASE 1 - SÉCURITÉ CRITIQUE TERMINÉE');
console.log('=====================================');
console.log('✅ Secrets cryptographiques générés');
console.log('✅ Fichiers de configuration créés');
console.log('✅ .gitignore sécurisé');
console.log('✅ Script de validation créé');

console.log('\n📋 ACTIONS MANUELLES REQUISES:');
console.log('==============================');
console.log('1. 🔄 Copiez .env.development vers .env');
console.log('2. 🔑 Remplacez les placeholders par les vraies valeurs');
console.log('3. 🧪 Testez: node security-scan.js');
console.log('4. 🚀 Démarrez: npm run dev');

console.log('\n⚠️ RAPPEL CRITIQUE:');
console.log('===================');
console.log('• JAMAIS commiter de fichiers .env');
console.log('• JAMAIS commiter de credentials JSON');
console.log('• TOUJOURS utiliser des secrets différents en production');
console.log('• TOUJOURS faire tourner security-scan.js avant commit');

console.log('\n🚀 MARKETPLACE - SÉCURITÉ RENFORCÉE ACTIVÉE !');