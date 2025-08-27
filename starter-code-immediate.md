# 🚀 STARTER CODE - COMMENCER IMMÉDIATEMENT

## 📁 STRUCTURE INITIALE À CRÉER

```
marketplace/
├── backend/
│   ├── .env.example
│   ├── .cursorrules
│   ├── package.json
│   ├── server.js
│   └── src/
├── app/
│   ├── .cursorrules
│   ├── pubspec.yaml
│   ├── lib/
│   │   └── main.dart
└── docs/
    ├── api.md
    └── templates.md
```

## 🔧 FICHIERS DE CONFIGURATION IMMÉDIATE

### 1. backend/package.json
```json
{
  "name": "marketplace-backend",
  "version": "1.0.0",
  "description": "Marketplace backend API",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "jest"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mongoose": "^8.0.3",
    "pg": "^8.11.3",
    "jsonwebtoken": "^9.0.2",
    "bcryptjs": "^2.4.3",
    "multer": "^1.4.5",
    "stripe": "^14.7.0",
    "joi": "^17.11.0",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "express-rate-limit": "^7.1.5",
    "compression": "^1.7.4",
    "morgan": "^1.10.0",
    "dotenv": "^16.3.1",
    "@google-cloud/vision": "^4.0.6",
    "sharp": "^0.33.0",
    "redis": "^4.6.11"
  },
  "devDependencies": {
    "nodemon": "^3.0.2",
    "jest": "^29.7.0"
  }
}
```

### 2. backend/.env.example
```env
# Database
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/marketplace
POSTGRES_URI=postgresql://username:password@host:port/marketplace

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRE=7d

# Stripe
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret

# Google Cloud
GOOGLE_CLOUD_PROJECT_ID=your-project-id
GOOGLE_CLOUD_KEY_FILE=path/to/service-account.json

# Redis
REDIS_URL=redis://localhost:6379

# App
PORT=3000
NODE_ENV=development
BASE_URL=http://localhost:3000

# File Upload
MAX_FILE_SIZE=5242880
UPLOAD_PATH=uploads/
```

### 3. backend/server.js
```javascript
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const morgan = require('morgan');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://your-app.com'] 
    : ['http://localhost:3000', 'http://localhost:8080'],
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP'
});
app.use('/api/', limiter);

// General middleware
app.use(compression());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Static files
app.use('/uploads', express.static('uploads'));

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV 
  });
});

// API routes (à développer)
// app.use('/api/v1/auth', require('./src/routes/auth.routes'));
// app.use('/api/v1/shops', require('./src/routes/shop.routes'));
// app.use('/api/v1/products', require('./src/routes/product.routes'));

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: process.env.NODE_ENV === 'production' 
      ? 'Something went wrong!' 
      : err.message
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📍 Environment: ${process.env.NODE_ENV}`);
  console.log(`🌐 Health check: http://localhost:${PORT}/health`);
});

module.exports = app;
```

### 4. app/pubspec.yaml
```yaml
name: marketplace_app
description: Modern marketplace application
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.1
  # riverpod: ^2.4.9  # Alternative à Provider
  
  # Navigation
  go_router: ^12.1.3
  
  # HTTP & API
  http: ^1.1.2
  dio: ^5.4.0  # Alternative plus puissante à http
  
  # Local Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Authentication
  jwt_decoder: ^2.0.1
  
  # UI & Styling
  google_fonts: ^6.1.0
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  lottie: ^2.7.0
  
  # File & Image
  image_picker: ^1.0.5
  file_picker: ^6.1.1
  image_cropper: ^5.0.1
  
  # Payments
  stripe_payment: ^1.1.4
  
  # Push Notifications
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  
  # Utils
  intl: ^0.19.0
  uuid: ^4.2.1
  url_launcher: ^6.2.2
  
  # Development
  flutter_launcher_icons: ^0.13.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  hive_generator: ^2.0.1
  build_runner: ^2.4.7

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
    - assets/templates/
  
  fonts:
    - family: CustomIcons
      fonts:
        - asset: assets/fonts/custom_icons.ttf
```

### 5. app/lib/main.dart
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

// Providers (à créer)
// import 'providers/auth_provider.dart';
// import 'providers/shop_provider.dart';

void main() {
  runApp(const MarketplaceApp());
}

class MarketplaceApp extends StatelessWidget {
  const MarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ChangeNotifierProvider(create: (_) => ShopProvider()),
      ],
      child: MaterialApp.router(
        title: 'Marketplace',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ),
        routerConfig: _router,
      ),
    );
  }
}

// Router Configuration
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    // Autres routes à ajouter...
  ],
);

// Screens temporaires (à développer)
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Marketplace',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
      ),
      body: const Center(
        child: Text('Authentication Screen - À développer'),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
      ),
      body: const Center(
        child: Text('Home Screen - À développer'),
      ),
    );
  }
}
```

### 6. Templates JSON de base

Créez `backend/src/data/templates.json`:
```json
{
  "templates": [
    {
      "id": "feminine",
      "name": "Féminin",
      "description": "Design élégant avec couleurs douces",
      "category": "gendered",
      "config": {
        "colors": {
          "primary": "#FF69B4",
          "secondary": "#FFC0CB", 
          "accent": "#FF1493",
          "background": "#FFF5F5",
          "surface": "#FFFFFF",
          "text": "#333333"
        },
        "typography": {
          "fontFamily": "Poppins",
          "headingSize": 24,
          "bodySize": 16,
          "fontWeight": "400"
        },
        "layout": {
          "gridColumns": 2,
          "spacing": "comfortable",
          "borderRadius": 15,
          "cardElevation": 2
        },
        "animations": {
          "transition": "soft",
          "duration": 300,
          "easing": "ease-in-out"
        }
      }
    },
    {
      "id": "masculine",
      "name": "Masculin", 
      "description": "Design moderne avec couleurs neutres",
      "category": "gendered",
      "config": {
        "colors": {
          "primary": "#2C3E50",
          "secondary": "#34495E",
          "accent": "#3498DB", 
          "background": "#F8F9FA",
          "surface": "#FFFFFF",
          "text": "#2C3E50"
        },
        "typography": {
          "fontFamily": "Roboto",
          "headingSize": 26,
          "bodySize": 16,
          "fontWeight": "500"
        },
        "layout": {
          "gridColumns": 1,
          "spacing": "compact",
          "borderRadius": 8,
          "cardElevation": 1
        },
        "animations": {
          "transition": "sharp",
          "duration": 200,
          "easing": "ease-out"
        }
      }
    },
    {
      "id": "minimal",
      "name": "Minimal",
      "description": "Design épuré et moderne",
      "category": "style",
      "config": {
        "colors": {
          "primary": "#000000",
          "secondary": "#666666",
          "accent": "#FF4444",
          "background": "#FFFFFF", 
          "surface": "#F9F9F9",
          "text": "#000000"
        },
        "typography": {
          "fontFamily": "Inter",
          "headingSize": 22,
          "bodySize": 14,
          "fontWeight": "300"
        },
        "layout": {
          "gridColumns": 3,
          "spacing": "minimal",
          "borderRadius": 0,
          "cardElevation": 0
        }
      }
    },
    {
      "id": "urban",
      "name": "Urbain",
      "description": "Style street et moderne",
      "category": "style", 
      "config": {
        "colors": {
          "primary": "#FF6B35",
          "secondary": "#F7931E",
          "accent": "#FFD23F",
          "background": "#1A1A1A",
          "surface": "#2A2A2A", 
          "text": "#FFFFFF"
        },
        "typography": {
          "fontFamily": "Oswald",
          "headingSize": 28,
          "bodySize": 16,
          "fontWeight": "600"
        },
        "layout": {
          "gridColumns": 2,
          "spacing": "wide",
          "borderRadius": 12,
          "cardElevation": 3
        }
      }
    },
    {
      "id": "neutral",
      "name": "Neutre",
      "description": "Design polyvalent pour tous",
      "category": "universal",
      "config": {
        "colors": {
          "primary": "#6366F1",
          "secondary": "#8B5CF6", 
          "accent": "#10B981",
          "background": "#F9FAFB",
          "surface": "#FFFFFF",
          "text": "#374151"
        },
        "typography": {
          "fontFamily": "System",
          "headingSize": 24,
          "bodySize": 16,
          "fontWeight": "400"
        },
        "layout": {
          "gridColumns": 2,
          "spacing": "normal",
          "borderRadius": 10,
          "cardElevation": 1
        }
      }
    }
  ]
}
```

## ⚡ COMMANDES POUR COMMENCER IMMÉDIATEMENT

```bash
# 1. Créer la structure
mkdir marketplace
cd marketplace

# 2. Backend
mkdir backend
cd backend
npm init -y
# Copier le package.json ci-dessus et faire:
npm install

# Créer les dossiers
mkdir -p src/{controllers,models,routes,services,middleware,utils,data}
mkdir uploads

# 3. Flutter App  
cd ../
flutter create app
cd app
# Remplacer pubspec.yaml par le contenu ci-dessus
flutter pub get

# 4. Git setup
cd ../
git init
echo "node_modules/" > .gitignore
echo ".env" >> .gitignore
echo "uploads/" >> .gitignore
git add .
git commit -m "Initial marketplace setup"

# 5. Tester
cd backend && npm run dev  # Terminal 1
cd app && flutter run      # Terminal 2
```

## 🎯 PREMIERS PROMPTS CURSOR

Une fois la structure créée, utilisez ces prompts dans Cursor :

### 1. Setup Database Models
```
@src/models/ 
Crée les modèles Mongoose et Sequelize pour:
- User (id, email, password, role, createdAt)
- Shop (id, userId, name, templateId, customization)
- Product (id, shopId, title, description, price, images, category)
- Order (id, buyerId, sellerId, products, total, status)

Inclus les validations et relations appropriées.
```

### 2. Authentication System  
```
@src/controllers/auth.controller.js @src/routes/auth.routes.js
Implémente l'authentification complète:
- POST /register (avec validation email + password)
- POST /login (JWT token)
- GET /me (profil utilisateur)
- POST /logout
- Middleware d'authentification JWT

Utilise bcrypt pour les mots de passe et validation Joi.
```

### 3. Flutter Authentication
```
@lib/providers/ @lib/services/
Crée le système d'authentification Flutter:
- AuthProvider avec état global
- AuthService pour API calls
- Login/Register screens
- Token storage avec SharedPreferences
- Auto-login au démarrage

Gère tous les états: loading, success, error.
```

Voilà ! Avec ces fichiers, vous pouvez commencer le développement **IMMÉDIATEMENT** ! 🚀

Les templates sont prêts, la structure est optimisée, et Cursor AI aura tout le contexte nécessaire pour vous aider efficacement.

**GO GO GO !** 💪⚡