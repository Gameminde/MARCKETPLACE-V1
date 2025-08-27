#!/bin/bash

# ========================================
# 🚀 MARKETPLACE STARTUP SCRIPT
# ========================================

echo "🚀 Démarrage de la Marketplace Moderne..."
echo "========================================"

# Vérifier si Node.js est installé
if ! command -v node &> /dev/null; then
    echo "❌ Node.js n'est pas installé. Veuillez l'installer depuis https://nodejs.org/"
    exit 1
fi

# Vérifier si Flutter est installé
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter n'est pas installé. Veuillez l'installer depuis https://flutter.dev/"
    exit 1
fi

# Vérifier la version de Node.js
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js 18+ est requis. Version actuelle: $(node -v)"
    exit 1
fi

# Vérifier la version de Flutter
FLUTTER_VERSION=$(flutter --version | grep -o "Flutter [0-9]\+\.[0-9]\+" | cut -d' ' -f2 | cut -d'.' -f1)
if [ "$FLUTTER_VERSION" -lt 3 ]; then
    echo "❌ Flutter 3.19+ est requis. Version actuelle: $(flutter --version | grep -o "Flutter [0-9]\+\.[0-9]\+")"
    exit 1
fi

echo "✅ Versions vérifiées:"
echo "   Node.js: $(node -v)"
echo "   Flutter: $(flutter --version | grep -o "Flutter [0-9]\+\.[0-9]\+\.[0-9]\+")"
echo ""

# Créer les dossiers nécessaires
echo "📁 Création des dossiers..."
mkdir -p backend/uploads
mkdir -p backend/public
mkdir -p app/assets/images
mkdir -p app/assets/icons
mkdir -p app/assets/templates
mkdir -p app/assets/animations
mkdir -p app/assets/fonts

# Backend setup
echo "🔧 Configuration du backend..."
cd backend

if [ ! -f ".env" ]; then
    echo "📝 Création du fichier .env..."
    cp env.example .env
    echo "⚠️  IMPORTANT: Configurez vos variables d'environnement dans backend/.env"
    echo "   - MONGODB_URI"
    echo "   - POSTGRES_URI"
    echo "   - JWT_SECRET"
    echo "   - STRIPE_SECRET_KEY"
    echo "   - GOOGLE_VISION_API_KEY"
    echo ""
fi

echo "📦 Installation des dépendances backend..."
npm install

if [ $? -eq 0 ]; then
    echo "✅ Dépendances backend installées"
else
    echo "❌ Erreur lors de l'installation des dépendances backend"
    exit 1
fi

# Flutter setup
echo "📱 Configuration de l'app Flutter..."
cd ../app

echo "📦 Installation des dépendances Flutter..."
flutter pub get

if [ $? -eq 0 ]; then
    echo "✅ Dépendances Flutter installées"
else
    echo "❌ Erreur lors de l'installation des dépendances Flutter"
    exit 1
fi

# Retour à la racine
cd ..

echo ""
echo "🎉 Configuration terminée avec succès !"
echo "========================================"
echo ""
echo "📋 PROCHAINES ÉTAPES:"
echo "1. Configurez vos variables d'environnement dans backend/.env"
echo "2. Créez vos comptes cloud gratuits:"
echo "   - MongoDB Atlas: https://mongodb.com"
echo "   - Neon PostgreSQL: https://neon.tech"
echo "   - Fly.io: https://fly.io"
echo "   - Google Cloud: https://console.cloud.google.com"
echo "   - Stripe: https://stripe.com"
echo ""
echo "🚀 POUR DÉMARRER LE DÉVELOPPEMENT:"
echo ""
echo "Terminal 1 (Backend):"
echo "  cd backend && npm run dev"
echo ""
echo "Terminal 2 (Flutter):"
echo "  cd app && flutter run"
echo ""
echo "🌐 Votre API sera accessible sur: http://localhost:3000"
echo "📱 Votre app Flutter sera accessible sur votre appareil/émulateur"
echo ""
echo "🔗 Liens utiles:"
echo "   - Health check: http://localhost:3000/health"
echo "   - API status: http://localhost:3000/status"
echo "   - Documentation: README.md"
echo ""
echo "✨ Bon développement ! Votre marketplace sera opérationnelle en moins de 2 heures !"

