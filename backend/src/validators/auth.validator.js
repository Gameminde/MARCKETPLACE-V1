const Joi = require('joi');
const { passwordSchema } = require('./password.validator');

const registrationSchema = Joi.object({
  email: Joi.string().email().required(),
  password: passwordSchema,
  firstName: Joi.string().max(100).allow('', null),
  lastName: Joi.string().max(100).allow('', null),
});

const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required(),
});

const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string().required(),
});

const forgotPasswordSchema = Joi.object({
  email: Joi.string().email().required(),
});

const resetPasswordSchema = Joi.object({
  token: Joi.string().required(),
  password: passwordSchema,
});

const changePasswordSchema = Joi.object({
  currentPassword: Joi.string().required(),
  newPassword: passwordSchema,
});

const verifyEmailSchema = Joi.object({
  token: Joi.string().required(),
});

// Middleware de validation
const validateRegistration = (req, res, next) => {
  const { error } = registrationSchema.validate(req.body);
  if (error) {
    return res.status(400).json({
      success: false,
      code: 'VALIDATION_ERROR',
      message: error.details[0].message
    });
  }
  next();
};

const validateLogin = (req, res, next) => {
  const { error } = loginSchema.validate(req.body);
  if (error) {
    return res.status(400).json({
      success: false,
      code: 'VALIDATION_ERROR',
      message: error.details[0].message
    });
  }
  next();
};

const validateRefreshToken = (req, res, next) => {
  const { error } = refreshTokenSchema.validate(req.body);
  if (error) {
    return res.status(400).json({
      success: false,
      code: 'VALIDATION_ERROR',
      message: error.details[0].message
    });
  }
  next();
};

const validateForgotPassword = (req, res, next) => {
  const { error } = forgotPasswordSchema.validate(req.body);
  if (error) {
    return res.status(400).json({
      success: false,
      code: 'VALIDATION_ERROR',
      message: error.details[0].message
    });
  }
  next();
};

const validateResetPassword = (req, res, next) => {
  const { error } = resetPasswordSchema.validate(req.body);
  if (error) {
    return res.status(400).json({
      success: false,
      code: 'VALIDATION_ERROR',
      message: error.details[0].message
    });
  }
  next();
};

const validateChangePassword = (req, res, next) => {
  const { error } = changePasswordSchema.validate(req.body);
  if (error) {
    return res.status(400).json({
      success: false,
      code: 'VALIDATION_ERROR',
      message: error.details[0].message
    });
  }
  next();
};

const validateVerifyEmail = (req, res, next) => {
  const { error } = verifyEmailSchema.validate(req.body);
  if (error) {
    return res.status(400).json({
      success: false,
      code: 'VALIDATION_ERROR',
      message: error.details[0].message
    });
  }
  next();
};

module.exports = {
  registrationSchema,
  loginSchema,
  refreshTokenSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  changePasswordSchema,
  verifyEmailSchema,
  validateRegistration,
  validateLogin,
  validateRefreshToken,
  validateForgotPassword,
  validateResetPassword,
  validateChangePassword,
  validateVerifyEmail
};

