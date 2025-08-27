#!/bin/bash

echo "🚀 Installation des MCPs pour Glassify Forge Marketplace..."

# MCPs pour le design et l'UI
echo "📦 Installation des MCPs Design & UI..."
npm install @modelcontextprotocol/server-figma
npm install @modelcontextprotocol/server-tailwind

# MCPs pour la 3D et les graphiques
echo "🎨 Installation des MCPs 3D & Graphics..."
npm install @modelcontextprotocol/server-threejs
npm install @modelcontextprotocol/server-blender

# MCPs pour le développement et les performances
echo "⚡ Installation des MCPs Development & Performance..."
npm install @modelcontextprotocol/server-vite
npm install @modelcontextprotocol/server-react-perf

# MCPs pour les animations
echo "🎭 Installation des MCPs Animation..."
npm install @modelcontextprotocol/server-framer-motion
npm install @modelcontextprotocol/server-gsap

# MCPs additionnels pour marketplace
echo "🛒 Installation des MCPs Marketplace..."
npm install @modelcontextprotocol/server-ecommerce
npm install @modelcontextprotocol/server-analytics

echo "✅ Installation terminée ! Tous les MCPs sont prêts."
echo "🎯 Vous pouvez maintenant me donner votre prompt pour transformer le design !"