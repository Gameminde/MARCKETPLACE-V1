# 🚀 PROMPTS ULTRA-DÉTAILLÉS POUR AGENT IA - MARKETPLACE DÉVELOPPEMENT

## 🎯 MISSION GLOBALE
Tu es un expert développeur spécialisé en marketplace moderne. Tu vas aider à créer une marketplace comme Temu/Amazon où les utilisateurs peuvent créer leurs propres boutiques personnalisées et publier des produits instantanément.

## 📋 CONTEXTE TECHNIQUE
- **Architecture**: Flutter + Node.js + PostgreSQL + MongoDB
- **Déploiement**: Services cloud gratuits (Google Cloud, Fly.io, Cloudflare)
- **Templates**: 5 designs de base (Féminin, Masculin, Neutre, Urbain, Minimal)
- **IA Validation**: Publication instantanée avec validation automatique

---

## 🏗️ PHASE 1: ARCHITECTURE & SETUP

### PROMPT 1: Structure Projet
```
Crée la structure complète d'un projet marketplace avec:

BACKEND (Node.js + Express):
```
marketplace-backend/
├── src/
│   ├── controllers/
│   │   ├── auth.controller.js
│   │   ├── user.controller.js
│   │   ├── shop.controller.js
│   │   ├── product.controller.js
│   │   └── payment.controller.js
│   ├── models/
│   │   ├── User.js
│   │   ├── Shop.js
│   │   ├── Product.js
│   │   └── Order.js
│   ├── services/
│   │   ├── ai-validation.service.js
│   │   ├── template.service.js
│   │   └── upload.service.js
│   ├── middleware/
│   │   ├── auth.middleware.js
│   │   └── validation.middleware.js
│   ├── routes/
│   │   ├── api.routes.js
│   │   └── auth.routes.js
│   └── utils/
│       ├── database.js
│       └── helpers.js
├── package.json
└── server.js
```

FRONTEND (Flutter):
```
marketplace_app/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   ├── utils/
│   │   └── services/
│   ├── features/
│   │   ├── auth/
│   │   ├── shop/
│   │   ├── products/
│   │   └── templates/
│   ├── shared/
│   │   ├── widgets/
│   │   └── models/
│   └── main.dart
├── pubspec.yaml
└── README.md
```

Génère tous les fichiers de base avec les imports nécessaires.
```

### PROMPT 2: Configuration Base de Données
```
Crée les schémas de base de données pour la marketplace:

1. POSTGRESQL (Transactions, Users, Orders):
- Table users (id, email, password_hash, role, created_at, updated_at)
- Table shops (id, user_id, name, template_id, customization_json, is_active)
- Table orders (id, buyer_id, seller_id, total_amount, status, created_at)
- Table payments (id, order_id, stripe_payment_id, amount, status)

2. MONGODB (Products, Templates):
- Collection products (productId, shopId, title, description, images[], price, category, tags[], isActive)
- Collection templates (templateId, name, type, config_json, preview_url)
- Collection shop_customizations (shopId, colors, fonts, layout, custom_css)

Génère:
- Scripts SQL pour PostgreSQL
- Schémas Mongoose pour MongoDB
- Migrations initiales
- Seeders pour les 5 templates de base
```

### PROMPT 3: API Backend Structure
```
Développe l'API REST complète pour la marketplace:

AUTHENTIFICATION (/api/auth):
- POST /register (inscription)
- POST /login (connexion)
- POST /logout (déconnexion)
- GET /me (profil utilisateur)

BOUTIQUES (/api/shops):
- POST / (créer boutique)
- GET /:id (détails boutique)
- PUT /:id (modifier boutique)
- POST /:id/customize (personnaliser design)
- GET /:id/analytics (statistiques vendeur)

PRODUITS (/api/products):
- POST / (ajouter produit avec validation IA)
- GET / (liste produits avec filtres)
- GET /:id (détail produit)
- PUT /:id (modifier produit)
- DELETE /:id (supprimer produit)
- POST /:id/images (upload images)

TEMPLATES (/api/templates):
- GET / (liste templates disponibles)
- GET /:id (détail template)
- POST /:id/apply (appliquer à une boutique)

Inclus:
- Validation des données avec Joi
- Authentification JWT
- Gestion d'erreurs
- Rate limiting
- CORS configuré
```

---

## 📱 PHASE 2: APPLICATION FLUTTER

### PROMPT 4: Architecture Flutter
```
Crée l'architecture Flutter avec:

1. STATE MANAGEMENT (Provider/Riverpod):
- AuthProvider (gestion authentification)
- ShopProvider (gestion boutiques)
- ProductProvider (gestion produits)
- TemplateProvider (gestion templates)

2. SERVICES:
- ApiService (requêtes HTTP)
- AuthService (authentification)
- ImageService (upload images)
- CacheService (cache local)

3. MODELS:
- User model
- Shop model
- Product model
- Template model

4. SCREENS PRINCIPALES:
- SplashScreen
- AuthScreen (login/register)
- HomeScreen (marketplace)
- ShopScreen (boutique individuelle)
- CreateShopScreen (création boutique)
- ProductFormScreen (ajout produit)
- TemplateSelectionScreen (choix template)

Génère le code Flutter complet avec navigation, état global et API calls.
```

### PROMPT 5: Templates System
```
Implémente le système de templates avec:

1. TEMPLATE CONFIGS (JSON):
```json
{
  "feminine": {
    "colors": {
      "primary": "#FF69B4",
      "secondary": "#FFC0CB",
      "background": "#FFF5F5"
    },
    "typography": {
      "fontFamily": "Poppins",
      "headingSize": 24,
      "bodySize": 16
    },
    "layout": {
      "gridColumns": 2,
      "spacing": "comfortable",
      "borderRadius": 15
    }
  }
}
```

2. TEMPLATE WIDGET BUILDER:
- Fonction qui génère l'UI selon le template
- Support des 5 templates de base
- Système de prévisualisation
- Customisation en temps réel

3. TEMPLATE PREVIEW:
- Widget de prévisualisation
- Mode édition avec drag & drop basique
- Sauvegarde des modifications

Génère le code Flutter complet pour le système de templates.
```

---

## 🤖 PHASE 3: IA VALIDATION

### PROMPT 6: Service IA Validation
```
Développe le service de validation IA pour publication instantanée:

FONCTIONNALITÉS:
1. Validation automatique des images produits
2. Génération automatique de descriptions
3. Détection de catégories
4. Vérification de conformité (pas de contenu interdit)
5. Optimisation SEO automatique

CODE REQUIS:
```javascript
class AIValidationService {
  async validateProduct(productData) {
    // Validation images
    // Génération description si manquante
    // Classification automatique
    // Score de qualité
    // Retour validation + suggestions
  }
  
  async optimizeImages(images) {
    // Compression automatique
    // Redimensionnement
    // Amélioration qualité
  }
  
  async generateSEO(productData) {
    // Mots-clés automatiques
    // Meta description
    // Balises optimisées
  }
}
```

INTÉGRATIONS:
- Google Vision API (gratuit 1000 req/mois)
- OpenAI API ou alternatives gratuites
- Système de scoring 0-100
- Queue de traitement asynchrone

Génère le service complet avec gestion d'erreurs et fallbacks.
```

---

## 💳 PHASE 4: PAIEMENTS & COMMANDES

### PROMPT 7: Système Paiements
```
Intègre Stripe pour les paiements marketplace:

FONCTIONNALITÉS:
1. Stripe Connect pour marketplace
2. Gestion commissions automatiques
3. Splits de paiement (vendeur + marketplace)
4. Gestion remboursements
5. Historique transactions

API ENDPOINTS:
- POST /api/payments/create-intent
- POST /api/payments/confirm
- POST /api/payments/refund
- GET /api/payments/history
- POST /api/stripe/connect (onboarding vendeurs)

FLUTTER INTEGRATION:
- Stripe Flutter SDK
- Formulaire de paiement
- 3D Secure support
- Gestion états de paiement

Génère:
- Backend Stripe integration complète
- Flutter payment flow
- Gestion erreurs et edge cases
- Tests de paiement en mode sandbox
```

---

## 🎮 PHASE 5: GAMIFICATION VENDEURS

### PROMPT 8: Système Gamification
```
Développe la gamification pour les vendeurs:

SYSTÈME DE NIVEAUX:
- Rookie (0-10 produits)
- Pro (11-50 produits) 
- Expert (51-200 produits)
- Master (200+ produits)

BADGES ACHIEVEMENT:
- "Premier Produit" (premier upload)
- "Vendeur Actif" (10 ventes)
- "Design Master" (utilise templates avancés)
- "Client Satisfait" (moyenne 4+ étoiles)

FEATURES:
```javascript
class GamificationService {
  async calculateLevel(userId) {
    // Calcul niveau selon activité
  }
  
  async awardBadge(userId, badgeType) {
    // Attribution badge + notification
  }
  
  async getLeaderboard() {
    // Classement vendeurs du mois
  }
  
  async getDashboardStats(userId) {
    // Stats gamifiées pour dashboard
  }
}
```

UI ELEMENTS:
- Progress bars animées
- Badge collection screen
- Leaderboard
- Achievement notifications

Génère le système complet avec animations Flutter.
```

---

## 🚀 PHASE 6: DÉPLOIEMENT GRATUIT

### PROMPT 9: Configuration Déploiement
```
Configure le déploiement sur services gratuits:

1. BACKEND (Fly.io gratuit):
- Dockerfile optimisé
- fly.toml configuration
- Environment variables
- Database connections

2. MONGODB (MongoDB Atlas gratuit 512MB):
- Cluster configuration
- Connection strings
- Indexes optimisés

3. POSTGRESQL (Neon gratuit ou Supabase):
- Database setup
- Connection pooling
- Migrations automatiques

4. CLOUDFLARE:
- CDN pour images
- DNS configuration
- SSL certificates

5. GITHUB ACTIONS CI/CD:
- Auto-deployment pipeline
- Testing automatique
- Build optimization

Génère:
- Tous les fichiers de configuration
- Scripts de déploiement
- Documentation setup
- Monitoring basique
```

---

## 🔍 PHASE 7: FEATURES AVANCÉES

### PROMPT 10: Recherche & Filtres
```
Implémente la recherche avancée:

BACKEND SEARCH:
- Elasticsearch gratuit (ou alternative)
- Indexation automatique produits
- Recherche full-text
- Filtres par catégorie, prix, ratings
- Suggestions auto-complete
- Recherche géographique

FLUTTER SEARCH UI:
- Barre de recherche avec suggestions
- Filtres UI avec sliders
- Résultats avec infinite scroll
- Tri par pertinence/prix/date
- Historique recherches

FEATURES:
```javascript
class SearchService {
  async searchProducts(query, filters) {
    // Recherche avec filtres
  }
  
  async getSuggestions(partial) {
    // Auto-complete
  }
  
  async getTrendingSearches() {
    // Recherches populaires
  }
}
```

Génère le système de recherche complet avec optimisations performance.
```

### PROMPT 11: Notifications & Real-time
```
Système de notifications en temps réel:

TYPES NOTIFICATIONS:
- Nouvelle commande (vendeur)
- Commande confirmée (acheteur)
- Nouveau message
- Badge débloqué
- Promo/discount

TECHNOLOGIES:
- Firebase Cloud Messaging (gratuit)
- WebSockets pour temps réel
- Push notifications Flutter
- Email notifications (SendGrid gratuit)

CODE STRUCTURE:
```javascript
class NotificationService {
  async sendPushNotification(userId, data) {}
  async sendEmail(to, template, data) {}
  async createInAppNotification(userId, message) {}
  async markAsRead(notificationId) {}
}
```

FLUTTER INTEGRATION:
- Firebase messaging setup
- Notification permissions
- Background handling
- UI notifications center

Génère le système complet de notifications.
```

---

## 📊 PROMPT FINAL: ANALYTICS & MONITORING

### PROMPT 12: Dashboard Analytics
```
Crée le dashboard analytics pour vendeurs:

MÉTRIQUES:
- Vues produits
- Conversions ventes
- Revenue par jour/semaine/mois
- Top produits
- Sources trafic
- Ratings moyens

BACKEND ANALYTICS:
```javascript
class AnalyticsService {
  async trackEvent(userId, event, data) {}
  async getShopAnalytics(shopId, period) {}
  async getProductPerformance(productId) {}
  async generateReport(shopId, type) {}
}
```

FLUTTER CHARTS:
- Charts.flutter library
- Graphiques interactifs
- Export PDF rapports
- Comparaisons périodes

MONITORING:
- Error tracking (Sentry gratuit)
- Performance monitoring
- User behavior analytics
- Sales funnel tracking

Génère le système analytics complet avec visualisations.
```

---

## 🎯 PROMPTS DE DEBUGGING

### PROMPT DEBUG 1:
```
Analyse et corrige les erreurs communes dans [FICHIER]. Vérifie:
- Gestion d'erreurs async/await
- Memory leaks potentiels
- Validation des données
- Sécurité (injections, XSS)
- Performance optimizations
```

### PROMPT DEBUG 2:
```
Optimise les performances de [COMPOSANT]:
- Réduire les re-renders Flutter
- Optimiser les requêtes DB
- Cache strategy
- Image loading optimization
- Bundle size reduction
```

---

## 📝 NOTES IMPORTANTES

**UTILISATION DE CES PROMPTS:**
1. Utilise UN prompt à la fois
2. Attends la complétion avant le suivant
3. Teste chaque phase avant de continuer
4. Adapte selon les réponses de l'agent
5. Garde une trace des modifications

**ORDRE RECOMMANDÉ:**
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7

**TESTS À CHAQUE ÉTAPE:**
- API endpoints avec Postman
- Flutter hot reload
- Database connections
- Authentication flow
- Payment sandbox

Utilise ces prompts comme guide, mais n'hésite pas à les adapter selon tes besoins spécifiques !