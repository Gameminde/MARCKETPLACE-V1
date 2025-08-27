@echo off
chcp 65001 >nul

REM ========================================
REM 🚀 MARKETPLACE STARTUP SCRIPT (Windows)
REM ========================================

echo 🚀 Démarrage de la Marketplace Moderne...
echo ========================================

REM Vérifier si Node.js est installé
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Node.js n'est pas installé. Veuillez l'installer depuis https://nodejs.org/
    pause
    exit /b 1
)

REM Vérifier si Flutter est installé
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Flutter n'est pas installé. Veuillez l'installer depuis https://flutter.dev/
    pause
    exit /b 1
)

REM Vérifier la version de Node.js
for /f "tokens=1,2 delims=." %%a in ('node -v') do set NODE_VERSION=%%a
set NODE_VERSION=%NODE_VERSION:~1%
if %NODE_VERSION% lss 18 (
    echo ❌ Node.js 18+ est requis. Version actuelle: 
    node -v
    pause
    exit /b 1
)

echo ✅ Versions vérifiées:
echo    Node.js: 
node -v
echo    Flutter: 
flutter --version | findstr "Flutter"
echo.

REM Créer les dossiers nécessaires
echo 📁 Création des dossiers...
if not exist "backend\uploads" mkdir "backend\uploads"
if not exist "backend\public" mkdir "backend\public"
if not exist "app\assets\images" mkdir "app\assets\images"
if not exist "app\assets\icons" mkdir "app\assets\icons"
if not exist "app\assets\templates" mkdir "app\assets\templates"
if not exist "app\assets\animations" mkdir "app\assets\animations"
if not exist "app\assets\fonts" mkdir "app\assets\fonts"

REM Backend setup
echo 🔧 Configuration du backend...
cd backend

if not exist ".env" (
    echo 📝 Création du fichier .env...
    copy env.example .env >nul
    echo ⚠️  IMPORTANT: Configurez vos variables d'environnement dans backend\.env
    echo    - MONGODB_URI
    echo    - POSTGRES_URI
    echo    - JWT_SECRET
    echo    - STRIPE_SECRET_KEY
    echo    - GOOGLE_VISION_API_KEY
    echo.
)

echo 📦 Installation des dépendances backend...
call npm install

if %errorlevel% equ 0 (
    echo ✅ Dépendances backend installées
) else (
    echo ❌ Erreur lors de l'installation des dépendances backend
    pause
    exit /b 1
)

REM Flutter setup
echo 📱 Configuration de l'app Flutter...
cd ..\app

echo 📦 Installation des dépendances Flutter...
call flutter pub get

if %errorlevel% equ 0 (
    echo ✅ Dépendances Flutter installées
) else (
    echo ❌ Erreur lors de l'installation des dépendances Flutter
    pause
    exit /b 1
)

REM Retour à la racine
cd ..

echo.
echo 🎉 Configuration terminée avec succès !
echo ========================================
echo.
echo 📋 PROCHAINES ÉTAPES:
echo 1. Configurez vos variables d'environnement dans backend\.env
echo 2. Créez vos comptes cloud gratuits:
echo    - MongoDB Atlas: https://mongodb.com
echo    - Neon PostgreSQL: https://neon.tech
echo    - Fly.io: https://fly.io
echo    - Google Cloud: https://console.cloud.google.com
echo    - Stripe: https://stripe.com
echo.
echo 🚀 POUR DÉMARRER LE DÉVELOPPEMENT:
echo.
echo Terminal 1 (Backend):
echo   cd backend ^&^& npm run dev
echo.
echo Terminal 2 (Flutter):
echo   cd app ^&^& flutter run
echo.
echo 🌐 Votre API sera accessible sur: http://localhost:3000
echo 📱 Votre app Flutter sera accessible sur votre appareil/émulateur
echo.
echo 🔗 Liens utiles:
echo    - Health check: http://localhost:3000/health
echo    - API status: http://localhost:3000/status
echo    - Documentation: README.md
echo.
echo ✨ Bon développement ! Votre marketplace sera opérationnelle en moins de 2 heures !
echo.
pause

