# 🚀 GIT WATCHER - Agent de fond pour Marketplace

## 📋 Description

Le **Git Watcher** est un agent de fond intelligent qui surveille automatiquement votre repository marketplace et automatise de nombreuses tâches de développement. Il fonctionne en arrière-plan et vous aide à maintenir un workflow Git optimal.

## ✨ Fonctionnalités

### 🔍 **Surveillance Automatique**
- Surveille les changements dans `backend/src/` et `app/lib/`
- Détecte les ajouts, modifications et suppressions de fichiers
- Ignore automatiquement les dossiers non pertinents (`node_modules`, `.git`, etc.)

### 🤖 **Hooks Git Automatisés**
- **Pre-commit** : Vérifie la syntaxe JavaScript et Dart avant chaque commit
- **Post-commit** : Auto-push automatique vers GitHub sur la branche main
- Vérifications de sécurité (variables sensibles dans .env)

### 💡 **Suggestions Intelligentes**
- Recommande des actions basées sur les types de fichiers modifiés
- Suggère des commandes de test et de linting appropriées
- Guide vers les bonnes pratiques de développement

### 🔄 **Vérifications Périodiques**
- Vérifie la santé du repository toutes les 5 minutes
- Surveille les mises à jour de dépendances disponibles
- Alertes sur les problèmes potentiels

## 🚀 Installation

### 1. **Prérequis**
```bash
# Vérifier que Node.js est installé
node --version  # Doit être >= 16.0.0

# Vérifier que Git est configuré
git --version
```

### 2. **Installation des Dépendances**
```bash
# Installer les dépendances
npm install

# Ou utiliser le script d'installation
npm run install-deps
```

### 3. **Configuration des Hooks Git**
```bash
# Rendre les hooks exécutables (Linux/Mac)
chmod +x .git/hooks/*

# Ou utiliser le script de setup
npm run setup
```

## 🎯 Utilisation

### **Démarrage Rapide**

#### Windows
```bash
# Double-cliquer sur le fichier
start-git-watcher.bat

# Ou en ligne de commande
npm start
```

#### Linux/Mac
```bash
# Rendre le script exécutable
chmod +x start-git-watcher.sh

# Démarrer l'agent
./start-git-watcher.sh

# Ou en ligne de commande
npm start
```

### **Commandes Interactives**

Une fois l'agent démarré, vous pouvez utiliser ces commandes :

```bash
status    # Vérifier le statut Git actuel
health    # Vérifier la santé du repository
deps      # Vérifier les dépendances
help      # Afficher l'aide
quit      # Quitter l'agent
```

## 🔧 Configuration

### **Chemins Surveillés**
L'agent surveille automatiquement :
- `backend/src/**/*.js` - Fichiers JavaScript du backend
- `backend/src/**/*.json` - Fichiers de configuration
- `app/lib/**/*.dart` - Fichiers Dart de l'app Flutter
- `app/pubspec.yaml` - Dépendances Flutter

### **Chemins Ignorés**
- `node_modules/**` - Dépendances Node.js
- `.git/**` - Métadonnées Git
- `**/*.log` - Fichiers de logs
- `**/build/**` - Dossiers de build
- `**/.dart_tool/**` - Outils Dart

### **Personnalisation**
Vous pouvez modifier `git-watcher.js` pour :
- Changer les chemins surveillés
- Ajouter des vérifications personnalisées
- Modifier la fréquence des vérifications
- Intégrer avec d'autres outils

## 📊 Workflow Typique

### **1. Développement Normal**
```bash
# L'agent surveille automatiquement vos changements
# Quand vous modifiez un fichier :
📝 MODIFIED: backend/src/controllers/auth.controller.js
🔄 Changements détectés dans Git...
📊 1 fichier(s) modifié(s)
🔧 Backend modifié - Actions suggérées:
   - npm run lint (vérification code)
   - npm test (tests unitaires)
   - git add . && git commit -m "Update backend"
```

### **2. Commit Automatique**
```bash
# Quand vous commitez :
git add .
git commit -m "Fix authentication bug"

🔍 PRE-COMMIT HOOK - Vérification automatique du code...
📝 Vérification syntaxe JavaScript...
✅ Tous les fichiers JavaScript sont syntaxiquement corrects
🔐 Vérification sécurité...
✅ PRE-COMMIT HOOK - Toutes les vérifications sont passées!
🚀 Prêt pour le commit!

🚀 POST-COMMIT HOOK - Automatisation du déploiement...
📝 Commit: a1b2c3d4e5f6
💬 Message: Fix authentication bug
🌿 Branche: main
🔄 Auto-push vers GitHub...
✅ Push réussi vers GitHub!
🌐 Repository: https://github.com/Gameminde/Marcketplace
```

### **3. Vérifications Périodiques**
```bash
# Toutes les 5 minutes :
🏥 Vérification santé du projet...
✅ Repository Git configuré correctement
📦 Vérification des dépendances Node.js...
📱 Vérification des dépendances Flutter...
```

## 🛠️ Dépannage

### **Problèmes Courants**

#### ❌ "Node.js n'est pas installé"
```bash
# Installer Node.js depuis https://nodejs.org/
# Ou utiliser un gestionnaire de versions comme nvm
```

#### ❌ "Repository Git non configuré"
```bash
# Vérifier que vous êtes dans le bon dossier
pwd
git status

# Si pas de repo Git, l'initialiser
git init
git remote add origin https://github.com/Gameminde/Marcketplace.git
```

#### ❌ "Erreur de permissions sur les hooks"
```bash
# Linux/Mac : Rendre les hooks exécutables
chmod +x .git/hooks/*

# Windows : Vérifier les permissions du dossier
```

#### ❌ "Dépendances manquantes"
```bash
# Réinstaller les dépendances
rm -rf node_modules package-lock.json
npm install
```

### **Logs et Debug**
```bash
# Vérifier les logs Git
tail -f .git/logs/auto-push.log

# Mode debug de l'agent
DEBUG=* npm start

# Vérifier le statut des hooks
ls -la .git/hooks/
```

## 🔒 Sécurité

### **Variables d'Environnement**
- L'agent vérifie automatiquement que `.env` n'est pas commité
- Alerte si des secrets sont détectés
- Recommande l'utilisation de `.env.example`

### **Hooks Sécurisés**
- Vérification de syntaxe avant commit
- Validation des fichiers sensibles
- Prévention des commits dangereux

## 🚀 Intégration CI/CD

### **GitHub Actions**
L'agent peut être intégré avec GitHub Actions pour :
- Tests automatiques sur chaque push
- Déploiement automatique
- Notifications Slack/Discord

### **Webhooks**
- Notifications en temps réel
- Intégration avec d'autres services
- Monitoring externe

## 📈 Métriques et Analytics

L'agent collecte automatiquement :
- Nombre de commits par jour
- Temps entre modifications et commits
- Types de fichiers modifiés
- Fréquence des pushes

## 🤝 Contribution

### **Améliorer l'Agent**
1. Fork le repository
2. Créer une branche feature
3. Implémenter vos améliorations
4. Tester avec `npm test`
5. Créer une Pull Request

### **Idées d'Amélioration**
- Intégration avec des outils de linting
- Support pour d'autres langages
- Interface web pour la configuration
- Intégration avec des services cloud

## 📞 Support

### **Documentation**
- [Guide Git Hooks](https://git-scm.com/docs/githooks)
- [Node.js Child Process](https://nodejs.org/api/child_process.html)
- [Chokidar File Watching](https://github.com/paulmillr/chokidar)

### **Issues**
- Créer une issue sur GitHub pour les bugs
- Proposer des features via Pull Request
- Contribuer à la documentation

---

## 🎯 **COMMENCER MAINTENANT !**

```bash
# 1. Installer les dépendances
npm install

# 2. Démarrer l'agent
npm start

# 3. Commencer à développer !
# L'agent surveillera automatiquement vos changements
```

**🚀 Votre agent Git de fond sera opérationnel en moins de 2 minutes !**

---

<div align="center">
  <h3>🌟 Si cet agent vous aide, donnez-lui une étoile ! 🌟</h3>
  <p>Construit avec ❤️ pour optimiser votre workflow marketplace</p>
</div>
