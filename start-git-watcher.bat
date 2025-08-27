@echo off
chcp 65001 >nul
title 🚀 Git Watcher - Agent de fond Marketplace

echo.
echo ========================================
echo 🚀 GIT WATCHER - AGENT DE FOND
echo ========================================
echo.
echo 📁 Dossier: %CD%
echo 🌐 Repository: https://github.com/Gameminde/Marcketplace
echo.
echo 💡 Cet agent surveille automatiquement vos changements Git
echo 💡 et suggère des actions pour optimiser votre workflow
echo.

REM Vérifier si Node.js est installé
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ ERREUR: Node.js n'est pas installé!
    echo 💡 Installez Node.js depuis: https://nodejs.org/
    pause
    exit /b 1
)

REM Vérifier si les dépendances sont installées
if not exist "node_modules" (
    echo 📦 Installation des dépendances...
    npm install
    if %errorlevel% neq 0 (
        echo ❌ Erreur lors de l'installation des dépendances
        pause
        exit /b 1
    )
)

REM Vérifier si le repository Git est configuré
git status >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ ERREUR: Ce dossier n'est pas un repository Git!
    echo 💡 Assurez-vous d'être dans le dossier marketplace
    pause
    exit /b 1
)

echo ✅ Vérifications terminées avec succès!
echo.
echo 🚀 Démarrage de Git Watcher...
echo 💡 Appuyez sur Ctrl+C pour arrêter
echo.

REM Démarrer l'agent
npm start

pause
