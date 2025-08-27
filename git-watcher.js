#!/usr/bin/env node

/**
 * 🚀 GIT WATCHER - Agent de fond pour automatisation Git
 * Surveille les changements et automatise les tâches de développement
 */

const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const chokidar = require('chokidar');

class GitWatcher {
  constructor() {
    this.isWatching = false;
    this.lastCommit = '';
    this.watchPaths = [
      'backend/src/**/*.js',
      'backend/src/**/*.json',
      'app/lib/**/*.dart',
      'app/pubspec.yaml'
    ];
    this.ignoredPaths = [
      'node_modules/**',
      '.git/**',
      '**/*.log',
      '**/build/**',
      '**/.dart_tool/**'
    ];
  }

  /**
   * Démarrer la surveillance
   */
  start() {
    console.log('🚀 Démarrage de Git Watcher...');
    console.log('📁 Surveillance des chemins:', this.watchPaths.join(', '));
    
    this.isWatching = true;
    this.watchFiles();
    this.startPeriodicChecks();
    
    console.log('✅ Git Watcher démarré avec succès!');
    console.log('💡 Appuyez sur Ctrl+C pour arrêter');
  }

  /**
   * Surveiller les fichiers
   */
  watchFiles() {
    const watcher = chokidar.watch(this.watchPaths, {
      ignored: this.ignoredPaths,
      persistent: true,
      ignoreInitial: true
    });

    watcher
      .on('add', (filePath) => this.handleFileChange('added', filePath))
      .on('change', (filePath) => this.handleFileChange('modified', filePath))
      .on('unlink', (filePath) => this.handleFileChange('deleted', filePath))
      .on('error', (error) => console.error('❌ Erreur de surveillance:', error));
  }

  /**
   * Gérer les changements de fichiers
   */
  handleFileChange(event, filePath) {
    const relativePath = path.relative(process.cwd(), filePath);
    console.log(`📝 ${event.toUpperCase()}: ${relativePath}`);
    
    // Délai pour éviter les changements multiples
    setTimeout(() => {
      this.analyzeChanges();
    }, 1000);
  }

  /**
   * Analyser les changements
   */
  async analyzeChanges() {
    try {
      const status = await this.getGitStatus();
      
      if (status.hasChanges) {
        console.log('🔄 Changements détectés dans Git...');
        this.suggestActions(status);
      }
    } catch (error) {
      console.error('❌ Erreur lors de l\'analyse:', error.message);
    }
  }

  /**
   * Obtenir le statut Git
   */
  getGitStatus() {
    return new Promise((resolve, reject) => {
      exec('git status --porcelain', (error, stdout, stderr) => {
        if (error) {
          reject(error);
          return;
        }
        
        const changes = stdout.trim().split('\n').filter(line => line);
        resolve({
          hasChanges: changes.length > 0,
          changes: changes,
          count: changes.length
        });
      });
    });
  }

  /**
   * Suggérer des actions
   */
  suggestActions(status) {
    console.log(`📊 ${status.count} fichier(s) modifié(s)`);
    
    if (status.changes.some(change => change.includes('backend/'))) {
      console.log('🔧 Backend modifié - Actions suggérées:');
      console.log('   - npm run lint (vérification code)');
      console.log('   - npm test (tests unitaires)');
      console.log('   - git add . && git commit -m "Update backend"');
    }
    
    if (status.changes.some(change => change.includes('app/'))) {
      console.log('📱 App Flutter modifiée - Actions suggérées:');
      console.log('   - flutter analyze (vérification code)');
      console.log('   - flutter test (tests)');
      console.log('   - git add . && git commit -m "Update Flutter app"');
    }
    
    console.log('💡 Utilisez "git add . && git commit -m \'message\'" pour commiter');
  }

  /**
   * Vérifications périodiques
   */
  startPeriodicChecks() {
    setInterval(async () => {
      try {
        await this.checkRepositoryHealth();
        await this.checkDependencies();
      } catch (error) {
        console.error('❌ Erreur lors des vérifications périodiques:', error.message);
      }
    }, 300000); // Toutes les 5 minutes
  }

  /**
   * Vérifier la santé du repository
   */
  async checkRepositoryHealth() {
    return new Promise((resolve, reject) => {
      exec('git remote -v', (error, stdout, stderr) => {
        if (error) {
          console.log('⚠️  Repository Git non configuré');
          reject(error);
          return;
        }
        
        if (stdout.includes('origin')) {
          console.log('✅ Repository Git configuré correctement');
        }
        resolve();
      });
    });
  }

  /**
   * Vérifier les dépendances
   */
  async checkDependencies() {
    // Vérifier Node.js
    if (fs.existsSync('backend/package.json')) {
      exec('cd backend && npm outdated', (error, stdout, stderr) => {
        if (!error && stdout.trim()) {
          console.log('📦 Mises à jour Node.js disponibles');
        }
      });
    }
    
    // Vérifier Flutter
    if (fs.existsSync('app/pubspec.yaml')) {
      exec('cd app && flutter pub outdated', (error, stdout, stderr) => {
        if (!error && stdout.trim()) {
          console.log('📱 Mises à jour Flutter disponibles');
        }
      });
    }
  }

  /**
   * Arrêter la surveillance
   */
  stop() {
    console.log('🛑 Arrêt de Git Watcher...');
    this.isWatching = false;
    process.exit(0);
  }
}

// Gestion des signaux d'arrêt
process.on('SIGINT', () => {
  console.log('\n🛑 Signal d\'arrêt reçu...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n🛑 Signal de terminaison reçu...');
  process.exit(0);
});

// Démarrer le watcher
const watcher = new GitWatcher();
watcher.start();

// Interface CLI simple
process.stdin.on('data', (data) => {
  const input = data.toString().trim().toLowerCase();
  
  switch (input) {
    case 'status':
    case 's':
      watcher.analyzeChanges();
      break;
    case 'health':
    case 'h':
      watcher.checkRepositoryHealth();
      break;
    case 'deps':
    case 'd':
      watcher.checkDependencies();
      break;
    case 'quit':
    case 'q':
    case 'exit':
      watcher.stop();
      break;
    case 'help':
      console.log('📚 Commandes disponibles:');
      console.log('  status/s  - Vérifier le statut Git');
      console.log('  health/h  - Vérifier la santé du repo');
      console.log('  deps/d    - Vérifier les dépendances');
      console.log('  quit/q    - Quitter');
      console.log('  help      - Afficher cette aide');
      break;
    default:
      console.log('💡 Tapez "help" pour voir les commandes disponibles');
  }
});

console.log('💡 Tapez "help" pour voir les commandes disponibles');
