const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const structuredLogger = require('./structured-logger.service');

// SOLID: Dependency Inversion - Depend on abstractions
class JWTSecurityService {
  constructor(secretManager, logger) {
    this.secretManager = secretManager || this._createSecretManager();
    this.logger = logger || structuredLogger;
    this.accessTokenExpiry = process.env.JWT_EXPIRE || '15m';
    this.refreshTokenExpiry = process.env.JWT_REFRESH_EXPIRE || '7d';
    this.issuer = process.env.JWT_ISSUER || 'marketplace-api';
    this.audience = process.env.JWT_AUDIENCE || 'marketplace-client';
    
    // Initialize token blacklist service
    this.tokenBlacklistService = this._createTokenBlacklistService();
  }

  // MANDATORY: Separate secrets for different token types
  generateTokenPair(payload, userId) {
    try {
      const accessToken = this.generateAccessToken(payload, userId);
      const refreshToken = this.generateRefreshToken(userId);
      
      this.logger.info('Token pair generated successfully', {
        userId,
        accessTokenExpiry: this.accessTokenExpiry,
        refreshTokenExpiry: this.refreshTokenExpiry
      });

      return {
        accessToken,
        refreshToken,
        expiresIn: this.accessTokenExpiry,
        tokenType: 'Bearer'
      };
    } catch (error) {
      this.logger.error('Token pair generation failed', {
        error: error.message,
        userId
      });
      throw error;
    }
  }

  generateAccessToken(payload, userId) {
    const accessSecret = this.secretManager.getSecret('JWT_SECRET');
    
    if (!accessSecret) {
      throw new Error('JWT_SECRET not configured');
    }

    const tokenPayload = {
      ...payload,
      sub: userId,
      type: 'access',
      iat: Math.floor(Date.now() / 1000),
      jti: this._generateJTI(), // JWT ID for tracking
    };

    return jwt.sign(tokenPayload, accessSecret, {
      expiresIn: this.accessTokenExpiry,
      issuer: this.issuer,
      audience: this.audience,
      algorithm: 'HS256'
    });
  }

  generateRefreshToken(userId) {
    const refreshSecret = this.secretManager.getSecret('JWT_REFRESH_SECRET');
    
    if (!refreshSecret) {
      throw new Error('JWT_REFRESH_SECRET not configured');
    }

    const tokenPayload = {
      sub: userId,
      type: 'refresh',
      iat: Math.floor(Date.now() / 1000),
      jti: this._generateJTI(),
    };

    return jwt.sign(tokenPayload, refreshSecret, {
      expiresIn: this.refreshTokenExpiry,
      issuer: this.issuer,
      audience: this.audience,
      algorithm: 'HS256'
    });
  }

  // MANDATORY: Token validation with proper error handling
  async validateAccessToken(token) {
    try {
      if (!token) {
        throw new Error('Token is required');
      }

      const accessSecret = this.secretManager.getSecret('JWT_SECRET');
      
      if (!accessSecret) {
        throw new Error('JWT_SECRET not configured');
      }

      // Verify token signature and claims
      const decoded = jwt.verify(token, accessSecret, {
        issuer: this.issuer,
        audience: this.audience,
        algorithms: ['HS256']
      });

      // Validate token type
      if (decoded.type !== 'access') {
        throw new Error('Invalid token type');
      }

      // MANDATORY: Check token blacklist
      const isBlacklisted = await this.isTokenBlacklisted(token);
      if (isBlacklisted) {
        throw new Error('Token has been revoked');
      }

      // Additional security checks
      this._validateTokenClaims(decoded);

      return decoded;
    } catch (error) {
      this.logger.warn('Token validation failed', {
        error: error.message,
        token: token ? token.substring(0, 20) + '...' : 'null' // Log partial token only
      });
      throw error;
    }
  }

  async validateRefreshToken(token) {
    try {
      if (!token) {
        throw new Error('Refresh token is required');
      }

      const refreshSecret = this.secretManager.getSecret('JWT_REFRESH_SECRET');
      
      if (!refreshSecret) {
        throw new Error('JWT_REFRESH_SECRET not configured');
      }

      const decoded = jwt.verify(token, refreshSecret, {
        issuer: this.issuer,
        audience: this.audience,
        algorithms: ['HS256']
      });

      if (decoded.type !== 'refresh') {
        throw new Error('Invalid refresh token type');
      }

      // Check if refresh token is blacklisted
      const isBlacklisted = await this.isTokenBlacklisted(token);
      if (isBlacklisted) {
        throw new Error('Refresh token has been revoked');
      }

      this._validateTokenClaims(decoded);

      return decoded;
    } catch (error) {
      this.logger.warn('Refresh token validation failed', {
        error: error.message,
        token: token ? token.substring(0, 20) + '...' : 'null'
      });
      throw error;
    }
  }

  // MANDATORY: Token blacklist for logout/revocation
  async blacklistToken(token, userId, reason = 'logout') {
    try {
      const decoded = jwt.decode(token);
      
      if (!decoded) {
        throw new Error('Invalid token format');
      }

      const expiryDate = new Date(decoded.exp * 1000);
      
      await this.tokenBlacklistService.add(token, userId, expiryDate, reason);
      
      this.logger.info('Token blacklisted', {
        userId,
        reason,
        exp: expiryDate,
        jti: decoded.jti
      });

      return true;
    } catch (error) {
      this.logger.error('Token blacklisting failed', {
        error: error.message,
        userId,
        reason
      });
      throw error;
    }
  }

  async isTokenBlacklisted(token) {
    try {
      return await this.tokenBlacklistService.isBlacklisted(token);
    } catch (error) {
      this.logger.error('Blacklist check failed', {
        error: error.message
      });
      // Fail secure - assume token is blacklisted if check fails
      return true;
    }
  }

  // Refresh token rotation for enhanced security
  async refreshTokenPair(refreshToken) {
    try {
      // Validate refresh token
      const decoded = await this.validateRefreshToken(refreshToken);
      
      // Blacklist the old refresh token
      await this.blacklistToken(refreshToken, decoded.sub, 'token_refresh');
      
      // Generate new token pair
      const payload = {
        role: decoded.role,
        permissions: decoded.permissions,
        email: decoded.email
      };
      
      const newTokenPair = this.generateTokenPair(payload, decoded.sub);
      
      this.logger.info('Token pair refreshed successfully', {
        userId: decoded.sub,
        oldJti: decoded.jti
      });

      return newTokenPair;
    } catch (error) {
      this.logger.error('Token refresh failed', {
        error: error.message
      });
      throw error;
    }
  }

  // Security utilities
  _generateJTI() {
    return crypto.randomBytes(16).toString('hex');
  }

  _validateTokenClaims(decoded) {
    const now = Math.floor(Date.now() / 1000);
    
    // Check expiration
    if (decoded.exp && decoded.exp < now) {
      throw new Error('Token has expired');
    }
    
    // Check not before
    if (decoded.nbf && decoded.nbf > now) {
      throw new Error('Token not yet valid');
    }
    
    // Check issued at (prevent tokens from future)
    if (decoded.iat && decoded.iat > now + 60) { // 60 seconds tolerance
      throw new Error('Token issued in the future');
    }
    
    // Validate required claims
    if (!decoded.sub) {
      throw new Error('Token missing subject claim');
    }
    
    if (!decoded.jti) {
      throw new Error('Token missing JWT ID');
    }
  }

  _createSecretManager() {
    return {
      getSecret: (key) => {
        const secret = process.env[key];
        if (!secret) {
          this.logger.error(`Secret ${key} not found in environment`);
          return null;
        }
        return secret;
      }
    };
  }

  _createTokenBlacklistService() {
    // Simple in-memory blacklist for development
    // In production, this should use Redis or database
    const blacklistedTokens = new Map();
    
    return {
      async add(token, userId, expiryDate, reason) {
        const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
        blacklistedTokens.set(tokenHash, {
          userId,
          expiryDate,
          reason,
          blacklistedAt: new Date()
        });
        
        // Clean up expired tokens periodically
        this._cleanupExpiredTokens();
      },
      
      async isBlacklisted(token) {
        const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
        const entry = blacklistedTokens.get(tokenHash);
        
        if (!entry) {
          return false;
        }
        
        // Check if blacklist entry has expired
        if (entry.expiryDate < new Date()) {
          blacklistedTokens.delete(tokenHash);
          return false;
        }
        
        return true;
      },
      
      _cleanupExpiredTokens() {
        const now = new Date();
        for (const [tokenHash, entry] of blacklistedTokens.entries()) {
          if (entry.expiryDate < now) {
            blacklistedTokens.delete(tokenHash);
          }
        }
      }
    };
  }

  // Token introspection for debugging (development only)
  introspectToken(token) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error('Token introspection not available in production');
    }
    
    try {
      const decoded = jwt.decode(token, { complete: true });
      return {
        header: decoded.header,
        payload: {
          ...decoded.payload,
          // Mask sensitive data
          sub: decoded.payload.sub ? '***' + decoded.payload.sub.slice(-4) : undefined
        },
        signature: '***'
      };
    } catch (error) {
      return { error: error.message };
    }
  }

  // Get token statistics
  getTokenStats() {
    return {
      accessTokenExpiry: this.accessTokenExpiry,
      refreshTokenExpiry: this.refreshTokenExpiry,
      issuer: this.issuer,
      audience: this.audience,
      algorithm: 'HS256',
      blacklistedTokensCount: this.tokenBlacklistService ? 
        this.tokenBlacklistService.blacklistedTokens?.size || 0 : 0
    };
  }
}

module.exports = JWTSecurityService;