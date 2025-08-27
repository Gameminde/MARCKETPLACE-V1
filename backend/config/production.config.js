// ========================================
// MARKETPLACE PRODUCTION CONFIGURATION
// Phase 4 - Foundation API
// ========================================

const productionConfig = {
  // ========================================
  // DATABASE CONFIGURATION - PRODUCTION
  // ========================================
  databases: {
    // MongoDB Atlas - Production database
    mongodb: {
      uri: process.env.MONGODB_URI,
      options: {
        maxPoolSize: 10,
        serverSelectionTimeoutMS: 5000,
        socketTimeoutMS: 45000,
        bufferMaxEntries: 0,
        retryWrites: true,
        w: 'majority'
      }
    },
    
    // PostgreSQL - Production database
    postgresql: {
      uri: process.env.POSTGRES_URI,
      options: {
        max: 20,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 2000,
        ssl: {
          rejectUnauthorized: false
        }
      }
    },
    
    // Redis - Cache et sessions
    redis: {
      url: process.env.REDIS_URL || 'redis://localhost:6379',
      options: {
        retryDelayOnFailover: 100,
        enableReadyCheck: false,
        maxRetriesPerRequest: 3
      }
    }
  },

  // ========================================
  // JWT AUTHENTICATION - PRODUCTION
  // ========================================
  jwt: {
    secret: process.env.JWT_SECRET,
    refreshSecret: process.env.JWT_REFRESH_SECRET,
    accessTokenExpiry: '15m',
    refreshTokenExpiry: '7d',
    issuer: 'marketplace-api',
    audience: 'marketplace-app'
  },

  // ========================================
  // STRIPE CONNECT - MARKETPLACE
  // ========================================
  stripe: {
    secretKey: process.env.STRIPE_SECRET_KEY,
    publishableKey: process.env.STRIPE_PUBLISHABLE_KEY,
    webhookSecret: process.env.STRIPE_WEBHOOK_SECRET,
    connectClientId: process.env.STRIPE_CONNECT_CLIENT_ID,
    marketplace: {
      applicationFeePercent: 3.5, // Commission 3.5%
      minimumFee: 0.50, // Frais minimum 50 centimes
      currency: 'eur'
    }
  },

  // ========================================
  // FILE STORAGE - CLOUDINARY
  // ========================================
  storage: {
    provider: 'cloudinary', // Alternative gratuite à AWS S3
    cloudinary: {
      cloudName: process.env.CLOUDINARY_CLOUD_NAME,
      apiKey: process.env.CLOUDINARY_API_KEY,
      apiSecret: process.env.CLOUDINARY_API_SECRET,
      folder: 'marketplace'
    }
  },

  // ========================================
  // AI VALIDATION - GOOGLE VISION
  // ========================================
  ai: {
    vision: {
      apiKey: process.env.GOOGLE_VISION_API_KEY,
      maxRetries: 3,
      timeout: 30000,
      features: ['SAFE_SEARCH_DETECTION', 'LABEL_DETECTION', 'TEXT_DETECTION']
    },
    validation: {
      imageTimeout: 8000, // 8s pour validation image
      descriptionTimeout: 5000, // 5s pour description
      categoryTimeout: 3000, // 3s pour catégorie
      qualityTimeout: 2000, // 2s pour qualité
      moderationTimeout: 3000 // 3s pour modération
    }
  },

  // ========================================
  // RATE LIMITING - PRODUCTION
  // ========================================
  rateLimit: {
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Limite générale
    auth: {
      max: 5, // 5 tentatives auth par 15min
      blockDuration: 30 * 60 * 1000 // Blocage 30min
    },
    upload: {
      max: 10, // 10 uploads par 15min
      blockDuration: 60 * 60 * 1000 // Blocage 1h
    }
  },

  // ========================================
  // SECURITY - PRODUCTION
  // ========================================
  security: {
    bcryptRounds: 12,
    cors: {
      origin: process.env.CORS_ORIGIN?.split(',') || ['https://marketplace.com'],
      credentials: true
    },
    helmet: {
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          styleSrc: ["'self'", "'unsafe-inline'"],
          scriptSrc: ["'self'"],
          imgSrc: ["'self'", "data:", "https:"],
          connectSrc: ["'self'", "https:"]
        }
      }
    }
  },

  // ========================================
  // MONITORING - PRODUCTION
  // ========================================
  monitoring: {
    sentry: {
      dsn: process.env.SENTRY_DSN,
      environment: 'production',
      tracesSampleRate: 0.1
    },
    logging: {
      level: 'info',
      format: 'json',
      transports: ['file', 'console']
    }
  }
};

module.exports = productionConfig;
