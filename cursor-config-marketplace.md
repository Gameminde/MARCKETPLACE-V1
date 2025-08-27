# 🎯 CONFIGURATION CURSOR AI - MARKETPLACE PROJECT

## 🔧 .cursorrules (FICHIER À CRÉER DANS VOTRE PROJET)

Créez ce fichier `.cursorrules` à la racine de votre projet pour optimiser Cursor AI :

```
# MARKETPLACE PROJECT RULES

## CONTEXT
You are working on a modern marketplace application similar to Temu/Amazon where users can create custom shops and instantly publish products.

## TECH STACK
- Frontend: Flutter 3.19+ (Dart)
- Backend: Node.js + Express.js
- Databases: PostgreSQL (transactions) + MongoDB (products)
- Auth: JWT + bcrypt
- Payments: Stripe Connect
- AI: Google Vision API
- Deployment: Fly.io + Cloudflare

## CODE STYLE

### Flutter/Dart:
- Use meaningful widget names (CustomShopCard, ProductUploadForm)
- Implement proper state management with Provider/Riverpod
- Always handle loading and error states
- Use const constructors when possible
- Follow Material Design 3 guidelines
- Implement responsive design (mobile-first)

### Node.js/JavaScript:
- Use async/await instead of Promises chains
- Implement proper error handling with try-catch
- Use descriptive variable names (shopId, productData, userProfile)
- Add JSDoc comments for complex functions
- Validate all inputs with Joi
- Use middleware for authentication and validation

### Database:
- Use transactions for critical operations
- Index frequently queried fields
- Sanitize all database inputs
- Use connection pooling
- Implement proper error handling

## SECURITY REQUIREMENTS
- Always validate user inputs
- Use parameterized queries
- Implement rate limiting
- Hash passwords with bcrypt
- Validate JWT tokens
- Sanitize file uploads
- Use HTTPS everywhere

## API DESIGN
- Use RESTful conventions
- Version your APIs (/api/v1/)
- Return consistent JSON responses
- Include proper HTTP status codes
- Implement pagination for lists
- Add request/response logging

## MARKETPLACE SPECIFIC
- Template system: Support 5 base templates (Feminine, Masculine, Neutral, Urban, Minimal)
- AI validation: Always validate products before publishing
- Instant publishing: Process uploads in under 30 seconds
- Commission system: Track marketplace fees
- Shop customization: Allow color/font/layout changes
- Gamification: Implement levels and badges for sellers

## PERFORMANCE
- Optimize images automatically
- Implement caching strategies
- Use pagination for large datasets
- Minimize API calls
- Implement lazy loading
- Compress responses

## ERROR HANDLING
- Always provide user-friendly error messages
- Log detailed errors for debugging
- Implement retry mechanisms
- Handle network timeouts
- Provide fallback options

## TESTING
- Write unit tests for business logic
- Test API endpoints with proper mocking
- Test Flutter widgets
- Test error scenarios
- Test authentication flows

## COMMENTS
- Explain complex business logic
- Document API endpoints
- Explain template system logic
- Document AI validation rules
- Explain payment flow

## EXAMPLES TO FOLLOW

### Good Flutter Widget:
```dart
class ProductCard extends StatelessWidget {
  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
  }) : super(key: key);

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            // Implementation
          ],
        ),
      ),
    );
  }
}
```

### Good API Endpoint:
```javascript
/**
 * Create a new product with AI validation
 */
router.post('/products', authMiddleware, async (req, res) => {
  try {
    const { error, value } = productSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: error.details[0].message
      });
    }

    // AI validation
    const validationResult = await aiValidationService.validateProduct(value);
    
    if (!validationResult.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Product validation failed',
        errors: validationResult.errors
      });
    }

    const product = await productService.create(value);
    
    res.status(201).json({
      success: true,
      data: product
    });
  } catch (error) {
    logger.error('Product creation failed:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});
```

## AVOID
- Hard-coded values
- Unvalidated user inputs
- Synchronous operations for I/O
- Missing error handling
- Unclear variable names
- Deeply nested callbacks
- Missing authentication checks
- Unoptimized database queries
```

## 🎯 CURSOR AI WORKFLOW OPTIMISÉ

### 1. DÉBUT DE SESSION
```
Cursor, nous travaillons sur une marketplace moderne avec:
- Flutter frontend 
- Node.js backend
- Templates personnalisables
- Publication instantanée avec IA
- Système de gamification vendeurs

Réfère-toi au fichier .cursorrules pour le contexte complet.
```

### 2. PROMPTS POUR CHAQUE PHASE

#### PHASE SETUP
```
@package.json @pubspec.yaml 
Vérifie que toutes les dépendances sont optimales pour notre marketplace.
Ajoute les packages manquants pour:
- Authentification (JWT, bcrypt)
- Base de données (mongoose, pg)
- Upload fichiers (multer)
- Paiements (stripe)
- IA (google-vision, openai)
```

#### PHASE BACKEND
```
@src/controllers/ @src/models/
Crée l'API complète pour:
1. Authentification users
2. Gestion boutiques avec templates
3. CRUD produits avec validation IA
4. Système de paiements Stripe
5. Gamification (niveaux + badges)

Respecte les règles de sécurité et performance du .cursorrules
```

#### PHASE FLUTTER
```
@lib/ 
Développe l'app Flutter avec:
1. Navigation propre (GoRouter)
2. State management (Provider/Riverpod)
3. Screens principales (Home, Shop, Product, Upload)
4. Système de templates avec preview
5. Upload images optimisé
6. Gestion des états (loading, error, success)

Utilise Material Design 3 et responsive design.
```

#### PHASE IA
```
@src/services/ai-validation.service.js
Implémente la validation IA qui:
1. Analyse les images produits (Google Vision)
2. Génère des descriptions automatiques
3. Classe les produits par catégorie
4. Détecte le contenu inapproprié
5. Optimise les images (compression, resize)
6. Retourne un score de qualité 0-100

Temps de traitement < 30 secondes obligatoire.
```

### 3. COMMANDES CURSOR AVANCÉES

#### DEBUGGING
```
Ctrl+K + "Analyse ce code pour les bugs potentiels"
Ctrl+K + "Optimise les performances de cette fonction"
Ctrl+K + "Ajoute la gestion d'erreurs manquante"
```

#### REFACTORING
```
Ctrl+K + "Refactorise en respectant le .cursorrules"
Ctrl+K + "Sépare cette fonction en modules plus petits"
Ctrl+K + "Ajoute les tests unitaires pour ce code"
```

#### DOCUMENTATION
```
Ctrl+K + "Génère la JSDoc pour cette fonction"
Ctrl+K + "Documente cette API endpoint"
Ctrl+K + "Ajoute des commentaires explicatifs"
```

## 🔥 TECHNIQUES CURSOR AVANCÉES

### 1. MULTI-FILE CONTEXT
```
@User.js @Shop.js @Product.js
Crée les relations entre ces modèles pour:
- Un User peut avoir plusieurs Shops
- Un Shop peut avoir plusieurs Products
- Gestion des permissions (owner, admin)
```

### 2. VISUAL PROGRAMMING
```
// Utilise l'extension Visual qui permet d'éditer l'UI directement
// Très utile pour ajuster les templates et layouts
```

### 3. TEST-DRIVEN DEVELOPMENT
```
@tests/ 
Écris d'abord les tests pour:
1. Authentification API
2. Upload produits
3. Validation IA
4. Paiements Stripe
5. Templates system

Puis implémente le code qui passe ces tests.
```

### 4. INCREMENTAL BUILDING
```
// Au lieu de demander tout d'un coup:
"Crée juste la fonction d'upload d'image"
// Puis:
"Maintenant ajoute la validation IA"
// Puis:
"Intègre avec la base de données"
```

## 🚦 CHECKPOINTS DE VALIDATION

À chaque fin de phase, demande à Cursor :

```
Vérifie que le code respecte:
✅ .cursorrules du projet
✅ Sécurité (authentification, validation, sanitization)
✅ Performance (cache, optimisations)
✅ Error handling complet
✅ Tests unitaires présents
✅ Documentation à jour
✅ Responsive design (Flutter)
✅ API RESTful conventions
```

## 🎯 PROMPTS SPÉCIAUX MARKETPLACE

### TEMPLATES SYSTEM
```
Développe le système de templates qui:
1. Charge les 5 templates de base depuis JSON
2. Permet la prévisualisation en temps réel
3. Sauvegarde les customisations en DB
4. Génère le CSS/Style dynamiquement
5. Supporte le responsive design
```

### IA VALIDATION
```
Crée le service IA qui traite un produit en:
1. < 10s pour validation basique
2. < 20s pour génération description
3. < 30s pour optimisation complète
4. Queue system pour pics de charge
5. Fallback si IA indisponible
```

### GAMIFICATION ENGINE
```
Implémente la gamification avec:
1. Système XP (actions → points)
2. Niveaux (Rookie → Master)
3. Badges unlock conditions
4. Leaderboard temps réel
5. Rewards (réductions, features premium)
```

## 💡 CONSEILS CURSOR PRO

1. **Contexte Graduel** : Ajoute progressivement les fichiers avec @
2. **Spécificité** : Plus le prompt est précis, meilleur est le résultat
3. **Itération** : Améliore le code par petites étapes
4. **Tests** : Demande toujours les tests en même temps que le code
5. **Documentation** : Génère la doc au fur et à mesure
6. **Performance** : Optimise dès le début, pas à la fin

Avec cette configuration, Cursor AI va devenir votre super-développeur qui comprend parfaitement votre projet marketplace ! 🚀