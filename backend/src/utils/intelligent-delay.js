const crypto = require('crypto');

class IntelligentDelay {
  constructor() {
    this.baseDelayMs = 200; // Délai de base réduit
    this.maxDelayMs = 2000; // Maximum 2 secondes
    this.failureMultiplier = 1.5;
  }

  async calculateDelay(email, isSuccess = false) {
    // Utiliser crypto.randomBytes pour la sécurité cryptographique
    const hash = crypto.createHash('sha256').update(email || 'unknown').digest('hex');
    const pseudoRandom = parseInt(hash.substring(0, 8), 16) % 1000; // 0-999ms
    
    let delay = this.baseDelayMs + pseudoRandom;
    
    if (!isSuccess) {
      // Augmenter délai pour échecs (anti-brute force)
      delay *= this.failureMultiplier;
    }
    
    return Math.min(delay, this.maxDelayMs);
  }

  async applyDelay(startTime, targetDelayMs) {
    const elapsedMs = Date.now() - startTime;
    const remainingDelay = Math.max(0, targetDelayMs - elapsedMs);
    
    if (remainingDelay > 0) {
      await new Promise(resolve => setTimeout(resolve, remainingDelay));
    }
  }

  // Méthode pour générer un délai aléatoire cryptographiquement sécurisé
  generateSecureRandomDelay(minMs = 100, maxMs = 500) {
    const randomBytes = crypto.randomBytes(4);
    const randomValue = randomBytes.readUInt32BE(0);
    return minMs + (randomValue % (maxMs - minMs));
  }
}

module.exports = new IntelligentDelay();


