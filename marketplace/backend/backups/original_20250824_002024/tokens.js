const jwt = require('jsonwebtoken');

class TokenService {
  constructor() {
    this.accessSecret = process.env.JWT_SECRET;
    this.refreshSecret = process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET;
    this.accessExpiry = process.env.JWT_ACCESS_EXPIRY || '15m';
    this.refreshExpiry = process.env.JWT_REFRESH_EXPIRY || '7d';
  }

  signAccessToken(payload) {
    try {
      return jwt.sign(payload, this.accessSecret, {
        expiresIn: this.accessExpiry,
        algorithm: 'HS256',
        issuer: 'marketplace-api',
        audience: 'marketplace-users'
      });
    } catch (error) {
      throw new Error(`Failed to sign access token: ${error.message}`);
    }
  }

  signRefreshToken(payload) {
    try {
      return jwt.sign(payload, this.refreshSecret, {
        expiresIn: this.refreshExpiry,
        algorithm: 'HS256',
        issuer: 'marketplace-api',
        audience: 'marketplace-users'
      });
    } catch (error) {
      throw new Error(`Failed to sign refresh token: ${error.message}`);
    }
  }

  verifyAccessToken(token) {
    try {
      return jwt.verify(token, this.accessSecret, {
        algorithms: ['HS256'],
        issuer: 'marketplace-api',
        audience: 'marketplace-users'
      });
    } catch (error) {
      throw new Error(`Failed to verify access token: ${error.message}`);
    }
  }

  verifyRefreshToken(token) {
    try {
      return jwt.verify(token, this.refreshSecret, {
        algorithms: ['HS256'],
        issuer: 'marketplace-api',
        audience: 'marketplace-users'
      });
    } catch (error) {
      throw new Error(`Failed to verify refresh token: ${error.message}`);
    }
  }

  decodeToken(token) {
    try {
      return jwt.decode(token, { complete: true });
    } catch (error) {
      throw new Error(`Failed to decode token: ${error.message}`);
    }
  }

  getTokenExpiry(token) {
    try {
      const decoded = jwt.decode(token);
      if (!decoded || !decoded.exp) {
        throw new Error('Invalid token format');
      }
      
      const now = Math.floor(Date.now() / 1000);
      const timeLeft = decoded.exp - now;
      
      return {
        expiresAt: new Date(decoded.exp * 1000),
        timeLeft: Math.max(0, timeLeft),
        isExpired: timeLeft <= 0
      };
    } catch (error) {
      throw new Error(`Failed to get token expiry: ${error.message}`);
    }
  }

  generateTokenPair(payload) {
    try {
      const accessToken = this.signAccessToken(payload);
      const refreshToken = this.signRefreshToken(payload);
      
      return {
        accessToken,
        refreshToken,
        expiresIn: this.accessExpiry
      };
    } catch (error) {
      throw new Error(`Failed to generate token pair: ${error.message}`);
    }
  }
}

const tokenService = new TokenService();

// Fonctions d'export pour compatibilité
const signAccessToken = tokenService.signAccessToken.bind(tokenService);
const signRefreshToken = tokenService.signRefreshToken.bind(tokenService);

module.exports = {
  signAccessToken,
  signRefreshToken,
  tokenService
};


