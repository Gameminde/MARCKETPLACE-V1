#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🚀 Setting up MCP servers for Glassify Forge...\n');

// MCP Configuration
const mcpConfig = {
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-figma"],
      "env": {
        "FIGMA_ACCESS_TOKEN": "your_figma_token_here"
      },
      "capabilities": ["design-sync", "asset-export", "component-generation"],
      "status": "ready"
    },
    "threejs": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-threejs"],
      "env": {},
      "capabilities": ["3d-scenes", "materials", "lighting", "animations"],
      "status": "pending"
    },
    "tailwind": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-tailwind"],
      "env": {},
      "capabilities": ["css-generation", "design-system", "responsive-design"],
      "status": "ready"
    },
    "framer-motion": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-framer-motion"],
      "env": {},
      "capabilities": ["animations", "transitions", "gestures", "layout-animations"],
      "status": "pending"
    },
    "vite": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-vite"],
      "env": {},
      "capabilities": ["build-optimization", "hot-reload", "bundle-analysis"],
      "status": "ready"
    },
    "react-perf": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-react-perf"],
      "env": {},
      "capabilities": ["component-optimization", "render-analysis", "performance-suggestions"],
      "status": "pending"
    },
    "blender": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-blender"],
      "env": {
        "BLENDER_PATH": "/path/to/blender"
      },
      "capabilities": ["3d-modeling", "texture-creation", "asset-optimization"],
      "status": "pending"
    },
    "gsap": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-gsap"],
      "env": {},
      "capabilities": ["high-performance-animations", "timeline-management", "advanced-effects"],
      "status": "pending"
    },
    "ecommerce": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-ecommerce"],
      "env": {},
      "capabilities": ["product-management", "cart-optimization", "checkout-flow"],
      "status": "pending"
    },
    "analytics": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-analytics"],
      "env": {},
      "capabilities": ["user-tracking", "performance-metrics", "conversion-analysis"],
      "status": "pending"
    }
  },
  "designCapabilities": {
    "3d": {
      "enabled": true,
      "engines": ["three.js", "blender"],
      "features": ["particles", "lighting", "materials", "animations", "physics"]
    },
    "ui": {
      "enabled": true,
      "frameworks": ["tailwind", "framer-motion"],
      "features": ["glassmorphism", "neon-effects", "micro-interactions", "responsive-design"]
    },
    "performance": {
      "enabled": true,
      "tools": ["vite", "react-perf"],
      "features": ["lazy-loading", "code-splitting", "optimization", "caching"]
    },
    "marketplace": {
      "enabled": true,
      "features": ["product-showcase", "3d-previews", "interactive-catalog", "analytics"]
    }
  },
  "prompts": {
    "3d": [
      "Create a floating product showcase with glassmorphism effects",
      "Generate particle systems for premium marketplace feel",
      "Design interactive 3D product previews with smooth animations",
      "Build immersive 3D environment for product exploration"
    ],
    "ui": [
      "Design modern marketplace cards with neon glow effects",
      "Create responsive product grid with hover animations",
      "Generate premium glassmorphism navigation components",
      "Build interactive search interface with smooth transitions"
    ],
    "animation": [
      "Add smooth page transitions between marketplace sections",
      "Create micro-interactions for product cards and buttons",
      "Design loading animations for better perceived performance",
      "Build scroll-triggered animations for product reveals"
    ],
    "performance": [
      "Optimize 3D assets for faster marketplace loading",
      "Implement lazy loading for product images and components",
      "Add code splitting for better bundle management",
      "Create virtual scrolling for large product catalogs"
    ]
  }
};

// Write MCP configuration
const configPath = path.join(__dirname, 'mcp-config.json');
fs.writeFileSync(configPath, JSON.stringify(mcpConfig, null, 2));

console.log('✅ MCP configuration created at mcp-config.json');

// Create environment template
const envTemplate = `# MCP Server Environment Variables
# Copy this to .env and fill in your actual values

# Figma Integration
FIGMA_ACCESS_TOKEN=your_figma_personal_access_token_here

# Blender Integration (optional)
BLENDER_PATH=/path/to/blender/executable

# Analytics (optional)
ANALYTICS_API_KEY=your_analytics_api_key_here

# Performance Monitoring (optional)
PERFORMANCE_API_KEY=your_performance_monitoring_key_here
`;

const envPath = path.join(__dirname, '.env.mcp.template');
fs.writeFileSync(envPath, envTemplate);

console.log('✅ Environment template created at .env.mcp.template');

// Create installation instructions
const instructions = `# 🚀 MCP Setup Instructions for Glassify Forge

## Quick Start

1. **Install MCP dependencies:**
   \`\`\`bash
   npm run install-mcps
   \`\`\`

2. **Configure environment variables:**
   \`\`\`bash
   cp .env.mcp.template .env.local
   # Edit .env.local with your actual tokens
   \`\`\`

3. **Start the application:**
   \`\`\`bash
   npm run dev
   \`\`\`

4. **Access MCP Studio:**
   Navigate to http://localhost:8080/mcp

## Available MCP Servers

### 🎨 Design & UI
- **Figma MCP**: Design synchronization and asset export
- **Tailwind MCP**: Intelligent CSS generation and design system

### 🌐 3D & Graphics  
- **Three.js MCP**: Advanced 3D scene generation
- **Blender MCP**: Professional 3D modeling and texturing

### 🎭 Animation & Interaction
- **Framer Motion MCP**: Smooth animations and transitions
- **GSAP MCP**: High-performance animation engine

### ⚡ Performance & Optimization
- **Vite MCP**: Build optimization and analysis
- **React Performance MCP**: Component optimization suggestions

### 🛒 Marketplace Features
- **E-commerce MCP**: Product management and optimization
- **Analytics MCP**: User behavior and conversion tracking

## Usage Examples

### Generate 3D Product Showcase
\`\`\`javascript
import { generate3DScene } from '@/lib/mcp-integration';

const result = await generate3DScene(
  "Create a floating product showcase with glassmorphism effects and particle systems"
);
\`\`\`

### Create Modern UI Components
\`\`\`javascript
import { generateUIComponents } from '@/lib/mcp-integration';

const result = await generateUIComponents(
  "Design premium marketplace cards with neon glow effects and hover animations"
);
\`\`\`

### Add Smooth Animations
\`\`\`javascript
import { generateAnimations } from '@/lib/mcp-integration';

const result = await generateAnimations(
  "Add micro-interactions for product cards and smooth page transitions"
);
\`\`\`

## Next Steps

1. Visit the MCP Studio at /mcp to start generating designs
2. Activate the MCP servers you want to use
3. Use the quick action buttons or provide custom prompts
4. Apply the generated suggestions to enhance your marketplace

Happy designing! 🎨✨
`;

const instructionsPath = path.join(__dirname, 'MCP-SETUP.md');
fs.writeFileSync(instructionsPath, instructions);

console.log('✅ Setup instructions created at MCP-SETUP.md');

console.log('\n🎯 Setup complete! Next steps:');
console.log('1. Run: npm install --legacy-peer-deps (to fix Three.js conflicts)');
console.log('2. Run: npm run install-mcps');
console.log('3. Copy .env.mcp.template to .env.local and configure');
console.log('4. Start the app: npm run dev');
console.log('5. Visit: http://localhost:8080/mcp');
console.log('\n📖 Read MCP-SETUP.md for detailed instructions');
console.log('\n⚠️  Note: Using --legacy-peer-deps is safe for Three.js projects');