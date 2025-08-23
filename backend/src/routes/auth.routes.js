const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const { register, login, me, logout, refreshToken } = require('../controllers/auth.controller');
const { advancedRateLimit } = require('../middleware/advanced-rate-limiter');
const { captchaMiddleware } = require('../services/captcha.service');
const { validateRegistration, validateLogin } = require('../validators/auth.validator');

// Auth endpoints
router.post('/register', advancedRateLimit, captchaMiddleware, validateRegistration, register);
router.post('/login', advancedRateLimit, captchaMiddleware, validateLogin, login);
router.get('/me', authMiddleware, me);
router.post('/logout', authMiddleware, logout);
router.post('/refresh', advancedRateLimit, refreshToken);

module.exports = router;


