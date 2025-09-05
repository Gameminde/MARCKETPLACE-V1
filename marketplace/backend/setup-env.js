const fs = require('fs');
const path = require('path');

// Configuration pour l'environnement de développement
const envConfig = `# ========================================
# MARKETPLACE BACKEND ENVIRONMENT VARIABLES
# ========================================

# ========================================
# DATABASE CONFIGURATION
# ========================================
MONGODB_URI=mongodb://localhost:27017/marketplace
POSTGRES_URI=postgresql://username:password@host:port/marketplace
REDIS_URL=redis://localhost:6379

# ========================================
# JWT AUTHENTICATION
# ========================================
JWT_SECRET=your-64-character-cryptographically-secure-jwt-secret-key-here-change-in-production
JWT_EXPIRE=7d
JWT_REFRESH_SECRET=your-64-character-cryptographically-secure-refresh-secret-key-here
JWT_REFRESH_EXPIRE=30d

# ========================================
# STRIPE PAYMENTS
# ========================================
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here

# ========================================
# GOOGLE CLOUD SERVICES
# ========================================
GOOGLE_CLOUD_PROJECT_ID=your-project-id-here
GOOGLE_VISION_API_KEY=your-vision-api-key-here

# ========================================
# APP CONFIGURATION
# ========================================
PORT=3001
NODE_ENV=development
BASE_URL=http://localhost:3001
API_VERSION=v1
CORS_ORIGIN=http://localhost:8080,http://localhost:3000

# ========================================
# SECURITY SETTINGS
# ========================================
BCRYPT_ROUNDS=12
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# ========================================
# FILE UPLOAD LIMITS
# ========================================
MAX_FILE_SIZE=5242880
MAX_FILES_PER_UPLOAD=10
UPLOAD_PATH=uploads/
ALLOWED_IMAGE_TYPES=jpg,jpeg,png,webp

# ========================================
# AI VALIDATION SETTINGS
# ========================================
AI_VALIDATION_TIMEOUT=30000
AI_MAX_RETRIES=3
AI_FALLBACK_ENABLED=true

# ========================================
# MONITORING & LOGGING
# ========================================
LOG_LEVEL=info
ENABLE_REQUEST_LOGGING=true

# ========================================
# GAMIFICATION SETTINGS
# ========================================
XP_PER_PRODUCT=10
XP_PER_SALE=50
LEVEL_UP_THRESHOLD=100
BADGE_UNLOCK_ENABLED=true

# ========================================
# TEMPLATE SYSTEM
# ========================================
DEFAULT_TEMPLATE_ID=neutral
TEMPLATE_CUSTOMIZATION_ENABLED=true
PREVIEW_MODE_ENABLED=true
`;

// Créer le fichier .env
const envPath = path.join(__dirname, '.env');
fs.writeFileSync(envPath, envConfig);

console.log('✅ Fichier .env créé avec succès !');
console.log('📝 Configuration MongoDB: mongodb://localhost:27017/marketplace');
console.log('🚀 Vous pouvez maintenant exécuter: npm run create-indexes');
