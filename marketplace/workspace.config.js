/**
 * @MARCKETPLACE Workspace Configuration
 * 
 * This file defines the monorepo structure for the MARCKETPLACE application.
 * It configures the workspace packages and their relationships.
 */

module.exports = {
  name: '@MARCKETPLACE/marketplace',
  version: '1.0.0',
  description: 'Modern marketplace application with Flutter frontend and Node.js backend',
  
  // Workspace packages
  workspaces: [
    'app',
    'backend'
  ],
  
  // Package configurations
  packages: {
    '@MARCKETPLACE/marketplace': {
      name: '@MARCKETPLACE/marketplace',
      version: '1.0.0',
      private: true,
      description: 'Root workspace for MARCKETPLACE application'
    },
    
    '@MARCKETPLACE/app': {
      name: '@MARCKETPLACE/app',
      version: '1.0.0',
      private: true,
      description: 'Flutter frontend application',
      path: './app'
    },
    
    '@MARCKETPLACE/backend': {
      name: '@MARCKETPLACE/backend',
      version: '1.0.0',
      private: true,
      description: 'Node.js backend API',
      path: './backend'
    }
  },
  
  // Development scripts
  scripts: {
    'start': 'concurrently "npm run start:backend" "npm run start:app"',
    'start:backend': 'cd backend && npm start',
    'start:app': 'cd app && flutter run',
    'dev': 'concurrently "npm run dev:backend" "npm run dev:app"',
    'dev:backend': 'cd backend && npm run dev',
    'dev:app': 'cd app && flutter run --debug',
    'build': 'npm run build:backend && npm run build:app',
    'build:backend': 'cd backend && npm run build',
    'build:app': 'cd app && flutter build',
    'test': 'npm run test:backend && npm run test:app',
    'test:backend': 'cd backend && npm test',
    'test:app': 'cd app && flutter test',
    'install:all': 'npm install && cd backend && npm install && cd ../app && flutter pub get',
    'clean': 'npm run clean:backend && npm run clean:app',
    'clean:backend': 'cd backend && npm run clean',
    'clean:app': 'cd app && flutter clean'
  },
  
  // Dependencies
  devDependencies: {
    'concurrently': '^8.2.2'
  },
  
  // Engine requirements
  engines: {
    node: '>=18.0.0',
    npm: '>=8.0.0'
  },
  
  // Repository information
  repository: {
    type: 'git',
    url: 'https://github.com/Gameminde/MARCKETPLACE-V1.git'
  },
  
  // Keywords for discovery
  keywords: [
    'marketplace',
    'flutter',
    'nodejs',
    'ai',
    'templates',
    'ecommerce',
    '@MARCKETPLACE'
  ],
  
  // Author and license
  author: 'MARCKETPLACE Team',
  license: 'MIT'
};
