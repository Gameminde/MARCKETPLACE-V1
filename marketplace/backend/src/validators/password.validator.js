const Joi = require('joi');

const passwordSchema = Joi.string()
  .min(8)
  .max(128)
  .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])/)
  .message('Password must contain uppercase, lowercase, digit and special character')
  .required();

module.exports = {
  passwordSchema
};


