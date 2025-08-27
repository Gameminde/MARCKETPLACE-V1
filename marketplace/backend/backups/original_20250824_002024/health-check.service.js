const redisClientService = require('./redis-client.service');

class HealthCheckService {
  constructor() {
    this.startTime = Date.now();
    this.checks = new Map();
  }

  async getHealthStatus() {
    try {
      const checks = await Promise.all([
        this.checkRedis(),
        this.checkMongoDB(),
        this.checkSystemResources()
      ]);

      const allHealthy = checks.every(check => check.status === 'healthy');
      
      return {
        status: allHealthy ? 'healthy' : 'unhealthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        services: {
          redis: checks[0],
          mongo: checks[1],
          system: checks[2]
        }
      };
    } catch (error) {
      return {
        status: 'error',
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  async checkRedis() {
    try {
      const status = await redisClientService.healthCheck();
      return {
        name: 'Redis',
        status: status.status,
        responseTime: Date.now(),
        ...status
      };
    } catch (error) {
      return {
        name: 'Redis',
        status: 'unhealthy',
        error: error.message,
        responseTime: Date.now()
      };
    }
  }

  async checkMongoDB() {
    try {
      // Vérification MongoDB (à implémenter selon votre modèle)
      return {
        name: 'MongoDB',
        status: 'healthy',
        responseTime: Date.now(),
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      return {
        name: 'MongoDB',
        status: 'unhealthy',
        error: error.message,
        responseTime: Date.now()
      };
    }
  }

  async checkSystemResources() {
    try {
      const usage = process.memoryUsage();
      const cpuUsage = process.cpuUsage();
      
      return {
        name: 'System',
        status: 'healthy',
        memory: {
          rss: Math.round(usage.rss / 1024 / 1024) + ' MB',
          heapTotal: Math.round(usage.heapTotal / 1024 / 1024) + ' MB',
          heapUsed: Math.round(usage.heapUsed / 1024 / 1024) + ' MB',
          external: Math.round(usage.external / 1024 / 1024) + ' MB'
        },
        cpu: {
          user: Math.round(cpuUsage.user / 1000) + ' ms',
          system: Math.round(cpuUsage.system / 1000) + ' ms'
        },
        uptime: Math.round(process.uptime()) + ' seconds',
        responseTime: Date.now()
      };
    } catch (error) {
      return {
        name: 'System',
        status: 'unhealthy',
        error: error.message,
        responseTime: Date.now()
      };
    }
  }

  async getSystemMetrics() {
    try {
      const [redis, mongo, system] = await Promise.all([
        this.checkRedis(),
        this.checkMongoDB(),
        this.checkSystemResources()
      ]);

      return {
        redis,
        mongo,
        system,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      throw new Error(`Failed to get system metrics: ${error.message}`);
    }
  }

  getDetailedHealth() {
    return {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      cpu: process.cpuUsage(),
      platform: process.platform,
      nodeVersion: process.version,
      pid: process.pid
    };
  }
}

module.exports = new HealthCheckService();


