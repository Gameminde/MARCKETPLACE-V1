# 🚀 @MARCKETPLACE - Marketplace Application

## 📦 **Workspace Structure**

This repository is organized as a **monorepo** under the `@MARCKETPLACE` scope, providing a unified development experience for the complete marketplace application.

### **🏗️ Package Organization**

```
@MARCKETPLACE/
├── @MARCKETPLACE/marketplace     # Root workspace (this package)
├── @MARCKETPLACE/app            # Flutter frontend application
└── @MARCKETPLACE/backend        # Node.js backend API
```

### **📱 @MARCKETPLACE/app**
- **Flutter 3.19+** application with Material Design 3
- **5 Template Designs**: Féminin, Masculin, Neutre, Urbain, Minimal
- **AI Integration**: Validation, suggestions, and content generation
- **Responsive Design**: Mobile-first approach with web support

### **🔧 @MARCKETPLACE/backend**
- **Node.js + Express.js** API server
- **Hybrid Database**: PostgreSQL + MongoDB
- **Security**: JWT + bcrypt + rate limiting
- **AI Services**: Google Vision + OpenAI integration
- **Stripe Connect**: Marketplace payment processing

## 🚀 **Quick Start**

### **Install Dependencies**
```bash
# Install all dependencies (root + backend + Flutter)
npm run install:all
```

### **Development Mode**
```bash
# Start both backend and Flutter app
npm run dev

# Or start individually
npm run dev:backend    # Backend API
npm run dev:app        # Flutter app
```

### **Production Build**
```bash
# Build both applications
npm run build

# Or build individually
npm run build:backend  # Backend build
npm run build:app      # Flutter build
```

## 🎯 **Key Features**

- ✨ **Templates Anti-Bugs IA** with 5 designs perfectionnés
- ⚡ **Publication <30 secondes** with AI validation
- 🎮 **Gamification vendeurs** with levels and badges
- 💰 **0€ budget initial** using free services
- 🔒 **Enterprise Security** with JWT + bcrypt + rate limiting

## 📊 **Technology Stack**

| Component | Technology | Version |
|-----------|------------|---------|
| **Frontend** | Flutter | 3.19+ |
| **Backend** | Node.js + Express | 18+ |
| **Database** | PostgreSQL + MongoDB | Hybrid |
| **Cache** | Redis | 6+ |
| **AI** | Google Vision + OpenAI | Latest |
| **Payments** | Stripe Connect | Latest |

## 🔧 **Development Commands**

```bash
# Testing
npm run test              # Run all tests
npm run test:backend      # Backend tests only
npm run test:app          # Flutter tests only

# Code Quality
npm run lint              # Lint backend code
npm run analyze           # Analyze Flutter code

# Maintenance
npm run clean             # Clean all builds
npm run install:all       # Reinstall all dependencies
```

## 📁 **Project Structure**

```
marketplace/
├── app/                          # Flutter application
│   ├── lib/                     # Dart source code
│   ├── assets/                  # Images, fonts, etc.
│   └── test/                    # Flutter tests
├── backend/                     # Node.js backend
│   ├── src/                     # Source code
│   ├── config/                  # Configuration files
│   └── tests/                   # Backend tests
├── package.json                 # Root workspace config
└── README_MARCKETPLACE.md       # This file
```

## 🌟 **Benefits of @MARCKETPLACE Scope**

1. **Unified Namespace**: All packages share the MARCKETPLACE brand
2. **Monorepo Management**: Single repository for frontend + backend
3. **Dependency Management**: Centralized package management
4. **Development Workflow**: Unified scripts and commands
5. **Version Control**: Coordinated releases across all packages

## 📈 **Roadmap**

- **Phase 1**: ✅ Setup & Architecture
- **Phase 2**: ✅ Authentication & Core API
- **Phase 3**: ✅ Flutter Interface & Templates
- **Phase 4**: ✅ AI Validation System
- **Phase 5**: 🔄 Stripe Payments Integration
- **Phase 6**: 🔄 Gamification & Analytics
- **Phase 7**: 🔄 Deployment & Production

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 **License**

MIT License - see LICENSE file for details

---

**Built with ❤️ by the MARCKETPLACE Team**
