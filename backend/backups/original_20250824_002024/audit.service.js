const winston = require('winston');

const auditLogger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(winston.format.timestamp(), winston.format.json()),
  transports: [new winston.transports.File({ filename: 'audit.log' })],
});

const logAuthEvent = (event, data) => {
  auditLogger.info(event, {
    timestamp: new Date().toISOString(),
    ip: data.ip,
    userAgent: data.userAgent,
    ...data,
  });
};

module.exports = { logAuthEvent };



