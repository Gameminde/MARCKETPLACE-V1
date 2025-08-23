const express = require('express');
const router = express.Router();
const healthCheck = require('../services/health-check.service');
const { redisCircuitBreaker } = require('../services/redis-circuit.service');
const authMiddleware = require('../middleware/auth.middleware');

// Route health publique pour load balancers
router.get('/health', async (req, res) => {
  try {
    const health = await healthCheck.getHealthStatus();
    res.status(health.status === 'healthy' ? 200 : 503).json({
      status: health.status,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(503).json({
      status: 'error',
      timestamp: new Date().toISOString()
    });
  }
});

// Middleware pour vérifier le rôle admin
const requireAdmin = (req, res, next) => {
  if (req.user?.role !== 'admin') {
    return res.status(403).json({
      success: false,
      code: 'ADMIN_REQUIRED',
      message: 'Admin role required for this endpoint'
    });
  }
  next();
};

router.get('/dashboard', 
  authMiddleware, 
  requireAdmin,
  async (req, res) => {
    try {
      const health = await healthCheck.getHealthStatus();
      const metrics = {
        timestamp: new Date().toISOString(),
        health,
        circuitBreaker: { state: redisCircuitBreaker.state, stats: redisCircuitBreaker.stats },
        system: { uptime: process.uptime(), memory: process.memoryUsage(), cpu: process.cpuUsage() },
        auth: { totalLogins: 0, failedAttempts: 0, activeUsers: 0, captchaRequests: 0 },
      };
      res.json(metrics);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
);

router.get('/metrics', 
  authMiddleware, 
  requireAdmin,
  async (req, res) => {
    try {
      const health = await healthCheck.getHealthStatus();
      let prometheusMetrics = '';
      prometheusMetrics += `# HELP marketplace_health_status Health status of services\n`;
      prometheusMetrics += `# TYPE marketplace_health_status gauge\n`;
      prometheusMetrics += `marketplace_health_status{service="redis"} ${health.services.redis.status === 'healthy' ? 1 : 0}\n`;
      prometheusMetrics += `marketplace_health_status{service="mongo"} ${health.services.mongo.status === 'healthy' ? 1 : 0}\n`;
      prometheusMetrics += `# HELP marketplace_circuit_breaker_state Circuit breaker state\n`;
      prometheusMetrics += `# TYPE marketplace_circuit_breaker_state gauge\n`;
      prometheusMetrics += `marketplace_circuit_breaker_state{service="redis"} ${redisCircuitBreaker.state === 'CLOSED' ? 0 : 1}\n`;
      res.set('Content-Type', 'text/plain');
      res.send(prometheusMetrics);
    } catch (error) {
      res.status(500).send('Error generating metrics');
    }
  }
);

module.exports = router;



