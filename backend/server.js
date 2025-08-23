const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');
const morgan = require('morgan');
const hpp = require('hpp');
const xssClean = require('xss-clean');
const path = require('path');
console.log('🔍 Loading .env file...');
const result = require('dotenv').config({ path: './.env' });
console.log('📁 .env file result:', result);
console.log('📊 Current env vars:', {
  MONGODB_URI: process.env.MONGODB_URI,
  JWT_SECRET: process.env.JWT_SECRET,
  STRIPE_SECRET_KEY: process.env.STRIPE_SECRET_KEY
});

// Import des routes et services
const authRoutes = require('./src/routes/auth.routes');
const shopRoutes = require('./src/routes/shop.routes');
const productRoutes = require('./src/routes/product.routes');
const templateRoutes = require('./src/routes/template.routes');
const paymentRoutes = require('./src/routes/payment.routes');
const userRoutes = require('./src/routes/user.routes');

// Import des middlewares
const { 
  handleError, 
  handleNotFound, 
  handleValidationError,
  handleRateLimitError,
  handleAuthError,
  setupGlobalHandlers
} = require('./src/middleware/error.middleware');

// Import des services
const databaseService = require('./src/services/database.service');
const loggerService = require('./src/services/logger.service');
const redisClientService = require('./src/services/redis-client.service');

const app = express();
const tracingMiddleware = require('./src/middleware/tracing.middleware');
const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';
let server; // global server reference for graceful shutdown

// ========================================
// SECURITY MIDDLEWARE (OBLIGATOIRE)
// ========================================

// Helmet - Sécurité des headers HTTP
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      imgSrc: ["'self'", "data:", "https:"],
      scriptSrc: ["'self'"],
      connectSrc: ["'self'", "https://api.stripe.com"]
    }
  },
  crossOriginEmbedderPolicy: false,
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));

// CORS - Configuration sécurisée
const corsOptions = {
  origin: process.env.CORS_ORIGIN 
    ? process.env.CORS_ORIGIN.split(',') 
    : ['http://localhost:3000', 'http://localhost:8080'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  exposedHeaders: ['X-Total-Count', 'X-Page-Count']
};
app.use(cors(corsOptions));

// Rate Limiting - Protection contre DDoS
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // 100 requests per window
  message: {
    success: false,
    message: 'Too many requests from this IP, please try again later.',
    retryAfter: Math.ceil(parseInt(process.env.RATE_LIMIT_WINDOW_MS) / 1000 / 60)
  },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      success: false,
      message: 'Too many requests from this IP, please try again later.',
      retryAfter: Math.ceil(parseInt(process.env.RATE_LIMIT_WINDOW_MS) / 1000 / 60)
    });
  }
});

// Slow Down - Protection contre brute force
const speedLimiter = slowDown({
  windowMs: 15 * 60 * 1000, // 15 minutes
  delayAfter: 50, // allow 50 requests per 15 minutes, then...
  delayMs: parseInt(process.env.SLOW_DOWN_DELAY_MS) || 1000 // begin adding 1000ms delay per request
});

// Apply rate limiting to all routes
app.use('/api/', limiter);
app.use('/api/', speedLimiter);

// ========================================
// GENERAL MIDDLEWARE
// ========================================

// Compression - Optimisation des réponses
app.use(compression({
  level: 6,
  threshold: 1024,
  filter: (req, res) => {
    if (req.headers['x-no-compression']) {
      return false;
    }
    return compression.filter(req, res);
  }
}));

// Logging - Monitoring des requêtes
if (process.env.ENABLE_REQUEST_LOGGING === 'true') {
  app.use(morgan('combined', {
    stream: {
      write: (message) => loggerService.info(message.trim())
    }
  }));
}

// Body parsing - Sécurisé
app.use(express.json({ 
  limit: process.env.MAX_FILE_SIZE || '5mb',
  verify: (req, res, buf) => {
    try {
      JSON.parse(buf);
    } catch (e) {
      res.status(400).json({
        success: false,
        message: 'Invalid JSON payload'
      });
      throw new Error('Invalid JSON');
    }
  }
}));

app.use(express.urlencoded({ 
  extended: true, 
  limit: process.env.MAX_FILE_SIZE || '5mb' 
}));

// Security middleware
app.use(hpp()); // Protection contre HTTP Parameter Pollution
app.use(xssClean()); // Protection contre XSS

// Tracing middleware
app.use(tracingMiddleware.createTraceMiddleware());

// ========================================
// STATIC FILES
// ========================================

// Uploads directory
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Public assets
app.use('/public', express.static(path.join(__dirname, 'public')));

// ========================================
// HEALTH CHECK & MONITORING
// ========================================

app.get('/health', (req, res) => {
  res.json({
    success: true,
    status: 'OK',
    timestamp: new Date().toISOString(),
    environment: NODE_ENV,
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    version: process.env.npm_package_version || '1.0.0'
  });
});

app.get('/status', (req, res) => {
  res.json({
    success: true,
    message: 'Marketplace API is running',
    timestamp: new Date().toISOString(),
    environment: NODE_ENV,
    database: databaseService.getStatus()
  });
});

// ========================================
// API ROUTES
// ========================================

// API versioning
const API_VERSION = process.env.API_VERSION || 'v1';
const API_PREFIX = `/api/${API_VERSION}`;

// Authentication routes
app.use(`${API_PREFIX}/auth`, authRoutes);

// User management routes
app.use(`${API_PREFIX}/users`, userRoutes);

// Shop management routes
app.use(`${API_PREFIX}/shops`, shopRoutes);

// Product management routes
app.use(`${API_PREFIX}/products`, productRoutes);

// Template system routes
app.use(`${API_PREFIX}/templates`, templateRoutes);

// Payment processing routes
app.use(`${API_PREFIX}/payments`, paymentRoutes);

// Monitoring routes
app.use(`${API_PREFIX}/monitoring`, require('./src/routes/monitoring.routes'));

// ========================================
// ERROR HANDLING MIDDLEWARE
// ========================================

// Validation error handler
app.use(handleValidationError);

// Rate limit error handler
app.use(handleRateLimitError);

// Authentication error handler
app.use(handleAuthError);

// 404 handler
app.use(handleNotFound);

// Global error handler
app.use(handleError);

// Setup global handlers
setupGlobalHandlers();

// ========================================
// GRACEFUL SHUTDOWN
// ========================================

const gracefulShutdown = (signal) => {
	loggerService.info(`${signal} received, shutting down gracefully`);
	if (server) {
		server.close(async () => {
			loggerService.info('HTTP server closed');
			if (typeof databaseService.disconnect === 'function') {
				await databaseService.disconnect();
			}
			try { await redisClientService.disconnect(); } catch (_) {}
			loggerService.info('Process terminated');
			process.exit(0);
		});
	} else {
		process.exit(0);
	}
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// ========================================
// ENV VALIDATION
// ========================================

// Validate essential environment variables early
const validateEnv = () => {
  const required = ['MONGODB_URI', 'POSTGRES_URI', 'JWT_SECRET', 'STRIPE_SECRET_KEY'];
  const missing = required.filter((env) => !process.env[env]);
  if (missing.length > 0) {
    // eslint-disable-next-line no-console
    console.error('❌ Missing required environment variables:');
    missing.forEach((env) => console.error(`   - ${env}`));
    console.error('\n📝 Please configure your .env file');
    process.exit(1);
  }
  loggerService.info('✅ Environment variables validated');
};

// ========================================
// SERVER STARTUP
// ========================================

const startServer = async () => {
	try {
		// Additional mandatory check (defense-in-depth)
		const requiredEnvVars = ['MONGODB_URI', 'POSTGRES_URI', 'JWT_SECRET'];
		for (const envVar of requiredEnvVars) {
			if (!process.env[envVar]) {
				console.error(`❌ Missing required environment variable: ${envVar}`);
				process.exit(1);
			}
		}

		// Connect to databases
		await databaseService.connect();
		// Skip Redis for now (development mode)
		loggerService.info('🔄 Skipping Redis connection for development...');
		
		// Start server
		server = app.listen(PORT, () => {
			loggerService.info(`🚀 Marketplace API Server running on port ${PORT}`);
			loggerService.info(`📍 Environment: ${NODE_ENV}`);
			loggerService.info(`🌐 Health check: http://localhost:${PORT}/health`);
			loggerService.info(`📊 Status: http://localhost:${PORT}/status`);
			loggerService.info(`🔒 Security: Helmet, CORS, Rate Limiting, XSS Protection`);
			loggerService.info(`⚡ Performance: Compression, Slow Down Protection`);
		});

		// Handle server errors
		server.on('error', (error) => {
			if (error.syscall !== 'listen') {
				throw error;
			}

			const bind = typeof PORT === 'string' ? 'Pipe ' + PORT : 'Port ' + PORT;

			switch (error.code) {
				case 'EACCES':
					loggerService.error(`${bind} requires elevated privileges`);
					process.exit(1);
					break;
				case 'EADDRINUSE':
					loggerService.error(`${bind} is already in use`);
					process.exit(1);
					break;
				default:
					throw error;
			}
		});

	} catch (error) {
		loggerService.error('Failed to start server:', error);
		process.exit(1);
	}
};

// Start server if this file is run directly
if (require.main === module) {
  validateEnv();
  startServer();
}

module.exports = app;
