const cluster = require('cluster');
const os = require('os');
const structuredLogger = require('./src/services/structured-logger.service');

class ClusterManager {
  constructor() {
    this.numCPUs = os.cpus().length;
    this.workers = new Map();
    this.restartCount = 0;
    this.maxRestarts = 10;
    this.restartDelay = 1000;
  }

  start() {
    if (cluster.isMaster) {
      this.startMaster();
    } else {
      this.startWorker();
    }
  }

  startMaster() {
    structuredLogger.logInfo('CLUSTER_MASTER_START', {
      pid: process.pid,
      cpus: this.numCPUs,
      nodeVersion: process.version
    });

    // Fork workers
    for (let i = 0; i < this.numCPUs; i++) {
      this.forkWorker();
    }

    // Handle worker events
    cluster.on('exit', (worker, code, signal) => {
      this.handleWorkerExit(worker, code, signal);
    });

    cluster.on('disconnect', (worker) => {
      structuredLogger.logWarning('WORKER_DISCONNECTED', {
        workerId: worker.id,
        pid: worker.process.pid
      });
    });

    // Graceful shutdown
    process.on('SIGTERM', () => this.gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => this.gracefulShutdown('SIGINT'));

    // Health check
    setInterval(() => {
      this.healthCheck();
    }, 30000); // Every 30 seconds
  }

  startWorker() {
    structuredLogger.logInfo('CLUSTER_WORKER_START', {
      workerId: cluster.worker.id,
      pid: process.pid
    });

    // Start the server
    require('./server');

    // Handle worker-specific events
    process.on('uncaughtException', (error) => {
      structuredLogger.logError('WORKER_UNCAUGHT_EXCEPTION', {
        workerId: cluster.worker.id,
        error: error.message,
        stack: error.stack
      });
      process.exit(1);
    });

    process.on('unhandledRejection', (reason, promise) => {
      structuredLogger.logError('WORKER_UNHANDLED_REJECTION', {
        workerId: cluster.worker.id,
        reason: reason?.message || reason,
        promise: promise.toString()
      });
      process.exit(1);
    });
  }

  forkWorker() {
    const worker = cluster.fork();
    this.workers.set(worker.id, {
      worker,
      startTime: Date.now(),
      restartCount: 0
    });

    structuredLogger.logInfo('WORKER_FORKED', {
      workerId: worker.id,
      pid: worker.process.pid
    });

    return worker;
  }

  handleWorkerExit(worker, code, signal) {
    const workerInfo = this.workers.get(worker.id);
    
    structuredLogger.logWarning('WORKER_EXITED', {
      workerId: worker.id,
      pid: worker.process.pid,
      code,
      signal,
      uptime: Date.now() - workerInfo.startTime
    });

    // Remove from workers map
    this.workers.delete(worker.id);

    // Restart worker if not intentional shutdown
    if (signal !== 'SIGTERM' && signal !== 'SIGINT') {
      this.restartWorker(worker, workerInfo);
    }
  }

  restartWorker(worker, workerInfo) {
    if (this.restartCount >= this.maxRestarts) {
      structuredLogger.logError('MAX_RESTARTS_REACHED', {
        workerId: worker.id,
        restartCount: this.restartCount,
        maxRestarts: this.maxRestarts
      });
      return;
    }

    this.restartCount++;
    workerInfo.restartCount++;

    structuredLogger.logInfo('RESTARTING_WORKER', {
      workerId: worker.id,
      restartCount: workerInfo.restartCount,
      totalRestarts: this.restartCount,
      delay: this.restartDelay
    });

    // Exponential backoff
    const delay = this.restartDelay * Math.pow(2, workerInfo.restartCount - 1);
    
    setTimeout(() => {
      this.forkWorker();
    }, Math.min(delay, 30000)); // Max 30 seconds
  }

  healthCheck() {
    const activeWorkers = this.workers.size;
    const totalWorkers = cluster.workers ? Object.keys(cluster.workers).length : 0;

    structuredLogger.logInfo('CLUSTER_HEALTH_CHECK', {
      activeWorkers,
      totalWorkers,
      restartCount: this.restartCount,
      memoryUsage: process.memoryUsage(),
      uptime: process.uptime()
    });

    // Alert if too many workers have died
    if (activeWorkers < this.numCPUs / 2) {
      structuredLogger.logError('CLUSTER_UNHEALTHY', {
        activeWorkers,
        expectedWorkers: this.numCPUs,
        restartCount: this.restartCount
      });
    }
  }

  gracefulShutdown(signal) {
    structuredLogger.logInfo('CLUSTER_GRACEFUL_SHUTDOWN_START', {
      signal,
      activeWorkers: this.workers.size
    });

    // Stop accepting new connections
    if (cluster.isMaster) {
      // Notify all workers to shutdown
      for (const [workerId, workerInfo] of this.workers) {
        workerInfo.worker.kill(signal);
      }

      // Wait for all workers to exit
      const checkWorkers = () => {
        if (this.workers.size === 0) {
          structuredLogger.logInfo('CLUSTER_SHUTDOWN_COMPLETE');
          process.exit(0);
        } else {
          setTimeout(checkWorkers, 1000);
        }
      };

      checkWorkers();
    } else {
      // Worker shutdown
      process.exit(0);
    }
  }

  getStats() {
    return {
      isMaster: cluster.isMaster,
      workerId: cluster.isWorker ? cluster.worker.id : null,
      totalWorkers: this.workers.size,
      restartCount: this.restartCount,
      uptime: process.uptime(),
      memoryUsage: process.memoryUsage(),
      cpuUsage: process.cpuUsage()
    };
  }
}

// Start cluster if this file is run directly
if (require.main === module) {
  const clusterManager = new ClusterManager();
  clusterManager.start();
}

module.exports = ClusterManager;
