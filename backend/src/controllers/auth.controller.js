const bcrypt = require('bcryptjs');
const Joi = require('joi');
const { UserMongo } = require('../models/User');
const { signAccessToken, signRefreshToken } = require('../utils/tokens');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

// Hash dummy optimal pré-calculé pour protection timing attack
// Utilise un hash fixe pour éviter la régénération à chaque démarrage
const DUMMY_HASH = '$2b$12$ZpZyHzTmPbDdLwJvAeE3GuJlw/7mXlZBtQb7lqfhGJbZqTJlqvZ7e';

// Service de blacklist sécurisé externe
const tokenBlacklistService = require('../services/token-blacklist.service');

const passwordSchema = Joi.string()
  .min(8)
  .max(128)
  .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])/)
  .message('Password must contain uppercase, lowercase, digit and special character')
  .required();

const registerSchema = Joi.object({
  email: Joi.string().email().required(),
  password: passwordSchema,
  firstName: Joi.string().max(100).allow('', null),
  lastName: Joi.string().max(100).allow('', null),
});

const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required(),
});

const structuredLogger = require('../services/structured-logger.service');
const passwordCache = require('../services/password-cache.service');

const register = async (req, res) => {
  try {
    // Vérifier cache
    const cached = passwordCache.getValidationResult(req.body?.password);
    if (cached && cached.isValid) {
      console.log('✅ Password validation from cache');
    }
    
    const { error, value } = registerSchema.validate(req.body);
    if (error) return res.status(400).json({ success: false, message: error.details[0].message });

    const existing = await UserMongo.findOne({ email: value.email });
    if (existing) return res.status(409).json({ success: false, code: 'EMAIL_EXISTS' });

    const saltRounds = parseInt(process.env.BCRYPT_ROUNDS || '12', 10);
    const passwordHash = await bcrypt.hash(value.password, saltRounds);
    
    // Cache successful password validation
    passwordCache.cacheValidationResult(value.password, true);
    const user = await UserMongo.create({
      email: value.email,
      password: passwordHash,
      firstName: value.firstName || '',
      lastName: value.lastName || '',
    });

    const accessToken = signAccessToken({ sub: user.id, role: user.role, email: user.email });
    const refreshToken = signRefreshToken({ sub: user.id });
    structuredLogger.logAuthEvent('REGISTER_SUCCESS', { userId: user.id, email: user.email, ip: req.ip, userAgent: req.headers['user-agent'] });
    return res.status(201).json({ success: true, data: { user: { id: user.id, email: user.email }, accessToken, refreshToken } });
  } catch (err) {
    structuredLogger.logAuthEvent('REGISTER_FAILED', { email: req.body?.email, ip: req.ip, userAgent: req.headers['user-agent'], reason: err.message });
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

const login = async (req, res) => {
  const startTime = Date.now();
  try {
    const { error, value } = loginSchema.validate(req.body);
    if (error) return res.status(400).json({ success: false, message: error.details[0].message });

    // Protection timing attack: recherche utilisateur avec délai constant
    let user = null;
    let hashToCompare = null;
    
    try {
      user = await UserMongo.findOne({ email: value.email });
      if (user) {
        hashToCompare = user.password;
      }
    } catch (err) {
      // Continue sans user en cas d'erreur
    }
    
    // Si pas d'utilisateur, utiliser le hash dummy pré-calculé pour timing constant
    if (!hashToCompare) {
      hashToCompare = DUMMY_HASH;
    }
    
    const match = await bcrypt.compare(value.password, hashToCompare);
    
    // Force minimum 200ms delay pour protection timing attack
    const elapsed = Date.now() - startTime;
    const minDelay = 200;
    if (elapsed < minDelay) {
      await new Promise(resolve => setTimeout(resolve, minDelay - elapsed));
    }
    
    if (!user || !match) return res.status(401).json({ success: false, code: 'INVALID_CREDENTIALS' });

    user.lastLoginAt = new Date();
    await user.save();

    const accessToken = signAccessToken({ sub: user.id, role: user.role, email: user.email });
    const refreshToken = signRefreshToken({ sub: user.id });
    structuredLogger.logAuthEvent('LOGIN_SUCCESS', { userId: user.id, email: user.email, ip: req.ip, userAgent: req.headers['user-agent'] });
    return res.json({ success: true, data: { user: { id: user.id, email: user.email }, accessToken, refreshToken } });
  } catch (err) {
    structuredLogger.logAuthEvent('LOGIN_FAILED', { email: req.body?.email, ip: req.ip, userAgent: req.headers['user-agent'], reason: err.message });
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

const me = async (req, res) => {
  try {
    const user = await UserMongo.findById(req.user.sub).select('-password');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    return res.json({ success: true, data: user });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

const logout = async (req, res) => {
  try {
    const authHeader = req.headers.authorization || '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : null;
    if (token) await tokenBlacklistService.blacklistToken(token);
    structuredLogger.logAuthEvent('LOGOUT', { userId: req.user?.sub, ip: req.ip, userAgent: req.headers['user-agent'] });
    return res.json({ success: true, message: 'Logged out' });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

const getRefreshSecret = () => {
  if (!process.env.JWT_REFRESH_SECRET) {
    console.error('❌ CRITICAL: JWT_REFRESH_SECRET environment variable is missing');
    return null;
  }
  if (process.env.JWT_REFRESH_SECRET === process.env.JWT_SECRET) {
    console.error('❌ CRITICAL: JWT_REFRESH_SECRET must be different from JWT_SECRET');
    return null;
  }
  return process.env.JWT_REFRESH_SECRET;
};

const refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body || {};
    if (!refreshToken) return res.status(400).json({ success: false, code: 'MISSING_REFRESH_TOKEN' });
    
    const secret = getRefreshSecret();
    if (!secret) {
      return res.status(500).json({ success: false, code: 'CONFIGURATION_ERROR' });
    }
    
    const decoded = jwt.verify(refreshToken, secret);
    
    // Vérifier le type de token (doit être refresh)
    if (decoded.type !== 'refresh') {
      return res.status(401).json({ success: false, code: 'INVALID_TOKEN_TYPE' });
    }
    
    const user = await UserMongo.findById(decoded.sub);
    if (!user) return res.status(401).json({ success: false, code: 'USER_NOT_FOUND' });
    
    await tokenBlacklistService.blacklistToken(refreshToken);
    const newAccessToken = signAccessToken({ sub: user.id, role: user.role, email: user.email });
    const newRefreshToken = signRefreshToken({ sub: user.id });
    
    return res.json({ success: true, data: { accessToken: newAccessToken, refreshToken: newRefreshToken } });
  } catch (err) {
    // Gestion d'erreur JWT détaillée
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, code: 'TOKEN_EXPIRED' });
    } else if (err.name === 'JsonWebTokenError') {
      return res.status(401).json({ success: false, code: 'INVALID_TOKEN_SIGNATURE' });
    } else if (err.name === 'NotBeforeError') {
      return res.status(401).json({ success: false, code: 'TOKEN_NOT_ACTIVE' });
    }
    
    // Log de l'erreur pour debugging
    console.error('Refresh token error:', err.name, err.message);
    return res.status(401).json({ success: false, code: 'INVALID_REFRESH_TOKEN' });
  }
};

module.exports = { register, login, me, logout, refreshToken };


