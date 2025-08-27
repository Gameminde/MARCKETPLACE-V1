class CaptchaService {
  constructor() {
    this.secretKey = process.env.RECAPTCHA_SECRET_KEY;
    this.siteKey = process.env.RECAPTCHA_SITE_KEY;
    this.verifyUrl = 'https://www.google.com/recaptcha/api/siteverify';
  }

  async verifyCaptcha(token, remoteIp) {
    try {
      if (!this.secretKey) {
        console.warn('⚠️ RECAPTCHA_SECRET_KEY not configured, skipping verification');
        return true;
      }

      if (!token) {
        return false;
      }

      const response = await fetch(this.verifyUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          secret: this.secretKey,
          response: token,
          remoteip: remoteIp
        })
      });

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
      console.error('❌ CAPTCHA verification error:', error);
      return false;
    }
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


