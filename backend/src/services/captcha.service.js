class CaptchaService {
  constructor() {
    this.secretKey = process.env.RECAPTCHA_SECRET_KEY;
    this.siteKey = process.env.RECAPTCHA_SITE_KEY;
    this.verifyUrl = 'https://www.google.com/recaptcha/api/siteverify';
    this.timeout = 5000; // 5 secondes timeout
    this.maxRetries = 2;
  }

  async verifyCaptcha(token, remoteIp) {
    try {
      if (!this.secretKey) {
        console.warn('⚠️ RECAPTCHA_SECRET_KEY not configured, skipping verification');
        return true;
      }

      if (!token || typeof token !== 'string') {
        return false;
      }

      // Validation token format
      if (token.length < 10 || token.length > 2000) {
        console.warn('🚨 Invalid CAPTCHA token length');
        return false;
      }

      const result = await this.makeSecureRequest(token, remoteIp);
      return result;
    } catch (error) {
      console.error('❌ CAPTCHA verification error:', error);
      return false;
    }
  }

  async makeSecureRequest(token, remoteIp, retryCount = 0) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => {
      controller.abort();
    }, this.timeout);

    try {
      const response = await fetch(this.verifyUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Marketplace-API/1.0'
        },
        body: new URLSearchParams({
          secret: this.secretKey,
          response: token,
          remoteip: remoteIp
        }),
        signal: controller.signal
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        if (response.status >= 500 && retryCount < this.maxRetries) {
          console.warn(`CAPTCHA API error ${response.status}, retrying... (${retryCount + 1}/${this.maxRetries})`);
          await this.delay(1000 * (retryCount + 1)); // Exponential backoff
          return this.makeSecureRequest(token, remoteIp, retryCount + 1);
        }
        throw new Error(`CAPTCHA API returned ${response.status}: ${response.statusText}`);
      }

      const data = await response.json();

      if (data.success && data.score >= 0.5) {
        return true;
      }

      console.warn('🚨 CAPTCHA verification failed:', {
        success: data.success,
        score: data.score,
        errorCodes: data['error-codes'],
        ip: remoteIp
      });
      
      return false;
    } catch (error) {
      clearTimeout(timeoutId);
      
      if (error.name === 'AbortError') {
        if (retryCount < this.maxRetries) {
          console.warn(`CAPTCHA timeout, retrying... (${retryCount + 1}/${this.maxRetries})`);
          return this.makeSecureRequest(token, remoteIp, retryCount + 1);
        }
        throw new Error('CAPTCHA verification timeout after retries');
      }
      
      throw error;
    }
  }

  async delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  createCaptchaMiddleware() {
    return async (req, res, next) => {
      try {
        const token = req.body.captchaToken || req.headers['x-captcha-token'];
        const remoteIp = req.ip || req.connection.remoteAddress;

        if (!token) {
          return res.status(400).json({
            success: false,
            code: 'CAPTCHA_TOKEN_REQUIRED',
            message: 'CAPTCHA token is required'
          });
        }

        const isValid = await this.verifyCaptcha(token, remoteIp);
        
        if (!isValid) {
          return res.status(400).json({
            success: false,
            code: 'CAPTCHA_VERIFICATION_FAILED',
            message: 'CAPTCHA verification failed'
          });
        }

        next();
      } catch (error) {
        console.error('❌ CAPTCHA middleware error:', error);
        return res.status(500).json({
          success: false,
          code: 'CAPTCHA_ERROR',
          message: 'CAPTCHA verification error'
        });
      }
    };
  }

  getSiteKey() {
    return this.siteKey;
  }

  isConfigured() {
    return !!(this.secretKey && this.siteKey);
  }
}

const captchaService = new CaptchaService();

module.exports = {
  captchaMiddleware: captchaService.createCaptchaMiddleware(),
  verifyCaptcha: captchaService.verifyCaptcha.bind(captchaService),
  getSiteKey: captchaService.getSiteKey.bind(captchaService),
  isConfigured: captchaService.isConfigured.bind(captchaService)
};


