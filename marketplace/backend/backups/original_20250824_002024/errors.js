const ERROR_CODES = {
  INVALID_CREDENTIALS: { code: 'INVALID_CREDENTIALS', message: 'Invalid email or password' },
  EMAIL_EXISTS: { code: 'EMAIL_EXISTS', message: 'Email already registered' },
  WEAK_PASSWORD: { code: 'WEAK_PASSWORD', message: 'Password does not meet requirements' },
  TOKEN_REVOKED: { code: 'TOKEN_REVOKED', message: 'Token has been revoked' },
  INVALID_TOKEN: { code: 'INVALID_TOKEN', message: 'Invalid or expired token' },
};

module.exports = { ERROR_CODES };



