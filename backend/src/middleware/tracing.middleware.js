const { v4: uuidv4 } = require('uuid');

class TracingMiddleware {
  constructor() {
    this.traces = new Map();
    this.maxTraces = 1000; // Limite pour éviter les fuites mémoire
    this.cleanupInterval = null;
    this.startCleanup();
  }

  startCleanup() {
    this.cleanupInterval = setInterval(() => {
      this.cleanupOldTraces();
    }, 60000); // Nettoyage toutes les minutes
  }

  cleanupOldTraces() {
    const now = Date.now();
    const maxAge = 300000; // 5 minutes
    
    for (const [traceId, trace] of this.traces.entries()) {
      if (now - trace.createdAt > maxAge) {
        this.traces.delete(traceId);
      }
    }

    // Vérifier la taille de la mémoire
    if (this.traces.size > this.maxTraces) {
      const entries = Array.from(this.traces.entries());
      entries.sort((a, b) => a[1].createdAt - b[1].createdAt);
      
      // Supprimer les plus anciens
      const toRemove = entries.slice(0, Math.floor(this.maxTraces * 0.2));
      toRemove.forEach(([traceId]) => this.traces.delete(traceId));
    }
  }

  createTraceMiddleware() {
    return (req, res, next) => {
      const traceId = req.headers['x-trace-id'] || uuidv4();
      const spanId = uuidv4();
      
      // Ajouter au request
      req.traceId = traceId;
      req.spanId = spanId;
      
      // Créer le trace
      this.traces.set(traceId, {
        id: traceId,
        createdAt: Date.now(),
        spans: new Map(),
        metadata: {
          method: req.method,
          url: req.url,
          userAgent: req.headers['user-agent'],
          ip: req.ip
        }
      });
      
      // Ajouter headers de réponse
      res.set('X-Trace-ID', traceId);
      res.set('X-Span-ID', spanId);
      
      next();
    };
  }

  startSpan(traceId, spanName, metadata = {}) {
    const trace = this.traces.get(traceId);
    if (!trace) return null;
    
    const spanId = uuidv4();
    const span = {
      id: spanId,
      name: spanName,
      startTime: Date.now(),
      metadata
    };
    
    trace.spans.set(spanId, span);
    return spanId;
  }

  endSpan(traceId, spanId, result = {}) {
    const trace = this.traces.get(traceId);
    if (!trace) return;
    
    const span = trace.spans.get(spanId);
    if (!span) return;
    
    span.endTime = Date.now();
    span.duration = span.endTime - span.startTime;
    span.result = result;
  }

  getTraceStats() {
    const totalTraces = this.traces.size;
    let totalSpans = 0;
    let totalDuration = 0;
    
    for (const trace of this.traces.values()) {
      totalSpans += trace.spans.size;
      for (const span of trace.spans.values()) {
        if (span.duration) {
          totalDuration += span.duration;
        }
      }
    }
    
    return {
      totalTraces,
      totalSpans,
      averageSpanDuration: totalSpans > 0 ? totalDuration / totalSpans : 0,
      memoryUsage: process.memoryUsage(),
      timestamp: new Date().toISOString()
    };
  }

  clearAllTraces() {
    this.traces.clear();
    return { message: 'All traces cleared', timestamp: new Date().toISOString() };
  }

  getTrace(traceId) {
    return this.traces.get(traceId);
  }

  getActiveTraces() {
    const now = Date.now();
    const activeTraces = [];
    
    for (const [traceId, trace] of this.traces.entries()) {
      if (now - trace.createdAt < 300000) { // 5 minutes
        activeTraces.push({
          id: traceId,
          createdAt: trace.createdAt,
          spanCount: trace.spans.size,
          metadata: trace.metadata
        });
      }
    }
    
    return activeTraces;
  }

  stopCleanup() {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
      this.cleanupInterval = null;
    }
  }
}

module.exports = new TracingMiddleware();


