#!/bin/bash

echo "========================================"
echo "🚀 GIT WATCHER - AGENT DE FOND"
echo "========================================"
echo ""
echo "📁 Dossier: $(pwd)"
echo "🌐 Repository: https://github.com/Gameminde/Marcketplace"
echo ""
echo "💡 Cet agent surveille automatiquement vos changements Git"
echo "💡 et suggère des actions pour optimiser votre workflow"
echo ""

# Vérifier si Node.js est installé
if ! command -v node &> /dev/null; then
    echo "❌ ERREUR: Node.js n'est pas installé!"
    echo "💡 Installez Node.js depuis: https://nodejs.org/"
    exit 1
fi

# Vérifier si les dépendances sont installées
if [ ! -d "node_modules" ]; then
    echo "📦 Installation des dépendances..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ Erreur lors de l'installation des dépendances"
        exit 1
    fi
fi

# Vérifier si le repository Git est configuré
if ! git status &> /dev/null; then
    echo "❌ ERREUR: Ce dossier n'est pas un repository Git!"
    echo "💡 Assurez-vous d'être dans le dossier marketplace"
    exit 1
fi

# Rendre les hooks exécutables
chmod +x .git/hooks/* 2>/dev/null

echo "✅ Vérifications terminées avec succès!"
echo ""
echo "🚀 Démarrage de Git Watcher..."
echo "💡 Appuyez sur Ctrl+C pour arrêter"
echo ""

# Démarrer l'agent
npm start
