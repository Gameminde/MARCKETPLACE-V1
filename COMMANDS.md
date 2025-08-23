# 🚀 COMMANDES DE DÉVELOPPEMENT - MARKETPLACE

## 📋 COMMANDES RAPIDES

### 🏗️ Setup Initial
```bash
# Cloner le projet
git clone <your-repo-url>
cd marketplace

# Script automatique (Linux/Mac)
chmod +x start.sh
./start.sh

# Script automatique (Windows)
start.bat

# Setup manuel
cd backend && npm install
cd ../app && flutter pub get
```

### 🔧 Backend Development
```bash
# Démarrer en mode développement
cd backend
npm run dev

# Démarrer en mode production
npm start

# Lancer les tests
npm test

# Lancer les tests avec coverage
npm run test:coverage

# Build pour production
npm run build

# Déployer sur Fly.io
npm run deploy
```

### 📱 Flutter Development
```bash
# Installer les dépendances
cd app
flutter pub get

# Lancer l'app
flutter run

# Lancer sur un appareil spécifique
flutter run -d <device-id>

# Lancer en mode web
flutter run -d chrome

# Lancer les tests
flutter test

# Build APK
flutter build apk

# Build iOS
flutter build ios

# Build web
flutter build web
```

### 🗄️ Base de Données
```bash
# MongoDB Atlas
# 1. Créer un compte sur mongodb.com
# 2. Créer un cluster gratuit (512MB)
# 3. Configurer IP whitelist
# 4. Récupérer connection string

# Neon PostgreSQL
# 1. Créer un compte sur neon.tech
# 2. Créer un projet gratuit (1GB)
# 3. Récupérer connection string

# Redis (optionnel)
# 1. Installer Redis localement
# 2. Ou utiliser Redis Cloud gratuit
```

### ☁️ Services Cloud
```bash
# Google Cloud Vision API
# 1. Créer un projet sur console.cloud.google.com
# 2. Activer Vision API
# 3. Créer une clé API
# 4. Ajouter dans .env

# Stripe
# 1. Créer un compte sur stripe.com
# 2. Récupérer les clés test
# 3. Configurer webhooks

# Fly.io
# 1. Créer un compte sur fly.io
# 2. Installer flyctl
# 3. fly auth login
# 4. fly launch
# 5. fly deploy
```

## 🔍 COMMANDES DE DEBUG

### Backend Debug
```bash
# Voir les logs en temps réel
cd backend
npm run dev

# Vérifier la santé de l'API
curl http://localhost:3000/health

# Vérifier le statut de l'API
curl http://localhost:3000/status

# Tester une route spécifique
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password123"}'
```

### Flutter Debug
```bash
# Voir les logs Flutter
flutter logs

# Hot reload
r

# Hot restart
R

# Quitter
q

# Voir les devices disponibles
flutter devices

# Vérifier la configuration
flutter doctor
```

## 🧪 TESTS

### Tests Backend
```bash
cd backend

# Tests unitaires
npm test

# Tests avec coverage
npm run test:coverage

# Tests en mode watch
npm run test:watch

# Tests d'intégration
npm run test:integration

# Tests de charge
npm run test:load
```

### Tests Flutter
```bash
cd app

# Tests unitaires
flutter test

# Tests avec coverage
flutter test --coverage

# Tests d'intégration
flutter test integration_test/

# Tests sur un device spécifique
flutter test -d <device-id>
```

## 🚀 DÉPLOIEMENT

### Déploiement Backend (Fly.io)
```bash
cd backend

# Première fois
fly auth login
fly launch

# Déploiements suivants
fly deploy

# Vérifier le statut
fly status

# Voir les logs
fly logs

# Ouvrir l'app
fly open
```

### Déploiement Flutter
```bash
cd app

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release

# Build Web
flutter build web --release

# Publier sur Google Play
flutter build appbundle --release
# Puis uploader sur Google Play Console

# Publier sur App Store
flutter build ios --release
# Puis utiliser Xcode pour uploader
```

## 📊 MONITORING

### Health Checks
```bash
# Vérifier la santé de l'API
curl http://localhost:3000/health

# Vérifier le statut de l'API
curl http://localhost:3000/status

# Vérifier la base de données
curl http://localhost:3000/api/v1/health/db
```

### Logs
```bash
# Backend logs
cd backend
npm run dev

# Flutter logs
flutter logs

# Fly.io logs
fly logs

# MongoDB logs (Atlas)
# Voir dans le dashboard MongoDB Atlas

# PostgreSQL logs (Neon)
# Voir dans le dashboard Neon
```

## 🔒 SÉCURITÉ

### Vérifications de Sécurité
```bash
# Vérifier les vulnérabilités npm
cd backend
npm audit

# Corriger les vulnérabilités
npm audit fix

# Vérifier les vulnérabilités Flutter
cd app
flutter analyze

# Vérifier la configuration de sécurité
# - Helmet headers
# - CORS configuration
# - Rate limiting
# - JWT validation
```

## 📱 PERFORMANCE

### Optimisations Backend
```bash
# Vérifier la performance
cd backend
npm run test:performance

# Profiler l'API
npm run profile

# Vérifier la mémoire
npm run memory-check
```

### Optimisations Flutter
```bash
# Vérifier la performance
cd app
flutter run --profile

# Analyser le code
flutter analyze

# Vérifier la taille du bundle
flutter build apk --analyze-size
```

## 🛠️ OUTILS UTILES

### Postman
```bash
# Collection d'API
# Importer le fichier marketplace-api.postman_collection.json
# Configurer l'environnement avec vos variables
```

### VS Code Extensions
```bash
# Extensions recommandées
- Flutter
- Dart
- Node.js
- REST Client
- Thunder Client
- MongoDB for VS Code
- PostgreSQL
```

### Cursor AI
```bash
# Utiliser le fichier .cursorrules
# Prompts optimisés pour le projet
# Code generation automatique
```

## 📚 DOCUMENTATION

### Liens Utiles
- [Flutter Documentation](https://flutter.dev/docs)
- [Node.js Documentation](https://nodejs.org/docs)
- [Express.js Documentation](https://expressjs.com/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Stripe Documentation](https://stripe.com/docs)
- [Google Vision API](https://cloud.google.com/vision/docs)

### Documentation Locale
```bash
# Générer la documentation API
cd backend
npm run docs:generate

# Ouvrir la documentation
npm run docs:serve
```

## 🆘 DÉPANNAGE

### Problèmes Communs

#### Backend ne démarre pas
```bash
# Vérifier le port
lsof -i :3000

# Vérifier les variables d'environnement
cat .env

# Vérifier les logs
npm run dev
```

#### Flutter ne compile pas
```bash
# Nettoyer le cache
flutter clean

# Réinstaller les dépendances
flutter pub get

# Vérifier la configuration
flutter doctor
```

#### Base de données inaccessible
```bash
# Vérifier la connexion
# Vérifier les IP whitelist
# Vérifier les credentials
# Vérifier la région
```

---

## 🎯 COMMANDES RAPIDES (COPIER-COLLER)

### Démarrage Complet
```bash
git clone <your-repo-url> && cd marketplace && chmod +x start.sh && ./start.sh
```

### Développement
```bash
# Terminal 1
cd backend && npm run dev

# Terminal 2  
cd app && flutter run
```

### Tests Complets
```bash
cd backend && npm test && cd ../app && flutter test
```

### Déploiement
```bash
cd backend && fly deploy
```

---

**✨ Ces commandes vous permettront de développer votre marketplace efficacement !**

