# Marketplace Backend API

Backend API moderne et sécurisé pour application marketplace avec authentification JWT, rate limiting avancé, et protection contre les attaques.

## 🚀 Fonctionnalités

- **Authentification sécurisée** : JWT avec refresh tokens et blacklisting
- **Rate limiting intelligent** : Protection IP + Email avec délais progressifs
- **Protection CAPTCHA** : Google reCAPTCHA pour les endpoints sensibles
- **Validation robuste** : Joi schemas avec cache des mots de passe
- **Logging structuré** : Winston avec rotation des fichiers
- **Monitoring sécurisé** : Endpoints protégés par authentification admin
- **Tracing distribué** : UUID pour le suivi des requêtes
- **Base de données** : MongoDB avec Mongoose, Redis pour le cache
- **Sécurité** : Helmet, CORS, XSS protection, HPP protection

## 📋 Prérequis

- Node.js >= 18.0.0
- MongoDB >= 5.0
- Redis >= 6.0
- npm >= 8.0.0

## 🛠️ Installation

1. **Cloner le projet**
```bash
git clone <repository-url>
cd marketplace/backend
```

2. **Installer les dépendances**
```bash
npm install
```

3. **Configuration des variables d'environnement**
```bash
cp .env.example .env
# Éditer .env avec vos valeurs
```

4. **Variables d'environnement requises**
```bash
# Base de données
MONGODB_URI=mongodb://localhost:27017/marketplace
REDIS_URL=redis://localhost:6379

# JWT
JWT_SECRET=your-super-secret-jwt-key-here
JWT_REFRESH_SECRET=your-super-secret-refresh-key-here

# Sécurité
BCRYPT_ROUNDS=12
RECAPTCHA_SECRET_KEY=your-recaptcha-secret-key
RECAPTCHA_SITE_KEY=your-recaptcha-site-key

# Serveur
PORT=3000
NODE_ENV=development
```

5. **Démarrer les services**
```bash
# MongoDB
mongod

# Redis
redis-server

# Démarrer l'API
npm run dev
```

## 🏗️ Architecture

### Structure des dossiers
```
src/
├── controllers/     # Contrôleurs métier
├── middleware/      # Middlewares Express
├── models/         # Modèles Mongoose
├── routes/         # Routes API
├── services/       # Services métier
├── utils/          # Utilitaires
└── validators/     # Schémas de validation Joi
```

### Services principaux

- **AuthService** : Authentification et gestion des tokens
- **RedisService** : Cache et blacklisting des tokens
- **LoggerService** : Logging structuré avec Winston
- **HealthCheckService** : Monitoring de santé du système
- **TracingMiddleware** : Traçage distribué des requêtes

### Middlewares de sécurité

- **Helmet** : Headers de sécurité HTTP
- **CORS** : Configuration Cross-Origin
- **Rate Limiting** : Protection contre DDoS et brute force
- **CAPTCHA** : Vérification reCAPTCHA
- **Validation** : Validation des entrées avec Joi

## 🔒 Sécurité

### Protection contre les attaques

- **Timing Attacks** : Délais cryptographiquement sécurisés
- **Brute Force** : Rate limiting progressif par IP et email
- **XSS** : Protection automatique avec xss-clean
- **CSRF** : Headers de sécurité avec Helmet
- **SQL Injection** : Validation stricte des entrées

### Authentification

- **JWT** : Tokens d'accès et de rafraîchissement
- **Blacklisting** : Révocation des tokens compromis
- **Rotation** : Renouvellement automatique des tokens
- **Rôles** : Système de permissions basé sur les rôles

## 📊 API Endpoints

### Authentification
- `POST /api/v1/auth/register` - Inscription utilisateur
- `POST /api/v1/auth/login` - Connexion utilisateur
- `POST /api/v1/auth/logout` - Déconnexion
- `POST /api/v1/auth/refresh` - Rafraîchissement du token
- `GET /api/v1/auth/me` - Profil utilisateur actuel

### Monitoring (Admin uniquement)
- `GET /api/v1/monitoring/health` - Santé du système
- `GET /api/v1/monitoring/metrics` - Métriques système
- `GET /api/v1/monitoring/tracing/stats` - Statistiques de traçage

### Produits
- `GET /api/v1/products` - Liste des produits
- `POST /api/v1/products` - Créer un produit
- `GET /api/v1/products/:id` - Détails d'un produit
- `PUT /api/v1/products/:id` - Modifier un produit
- `DELETE /api/v1/products/:id` - Supprimer un produit

### Boutiques
- `GET /api/v1/shops` - Liste des boutiques
- `POST /api/v1/shops` - Créer une boutique
- `GET /api/v1/shops/:id` - Détails d'une boutique
- `PUT /api/v1/shops/:id` - Modifier une boutique

## 🧪 Tests

```bash
# Tests unitaires
npm test

# Tests avec coverage
npm test -- --coverage

# Tests en mode watch
npm test -- --watch
```

## 📝 Logs

Les logs sont stockés dans le dossier `logs/` :
- `app.log` : Logs généraux de l'application
- `error.log` : Logs d'erreurs
- `auth-audit.log` : Audit des événements d'authentification

## 🔧 Développement

```bash
# Mode développement avec hot reload
npm run dev

# Linting
npm run lint

# Linting avec auto-correction
npm run lint:fix
```

## 🚀 Déploiement

### Production
```bash
npm start
```

### Variables d'environnement de production
```bash
NODE_ENV=production
PORT=3000
MONGODB_URI=mongodb://production-host:27017/marketplace
REDIS_URL=redis://production-host:6379
JWT_SECRET=production-secret-key
```

## 📈 Monitoring

### Health Checks
- `/health` : Vérification de base
- `/health/ready` : Prêt pour le trafic
- `/health/live` : Vérification de liveness

### Métriques
- Utilisation mémoire et CPU
- Connexions base de données
- Statistiques Redis
- Traçage des requêtes

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🆘 Support

Pour toute question ou problème :
- Créer une issue sur GitHub
- Contacter l'équipe de développement
- Consulter la documentation technique

