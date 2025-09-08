# 📱 Marketplace Flutter App

Application mobile moderne pour la marketplace, développée avec Flutter.

## 🚀 Configuration Rapide

### 1. Installation des dépendances
```bash
cd marketplace/flutter_app
flutter pub get
```

### 2. Lancement sur émulateur Android
```bash
flutter run
```

### 3. Hot Reload pendant le développement
- Appuyez sur `r` pour Hot Reload
- Appuyez sur `R` pour Hot Restart
- Appuyez sur `q` pour quitter

## 📁 Structure du Projet

```
lib/
├── main.dart           # Point d'entrée de l'application
├── screens/           # Écrans de l'application
├── widgets/           # Widgets réutilisables
├── models/            # Modèles de données
├── services/          # Services API et logique métier
└── utils/             # Utilitaires et constantes

assets/
├── images/            # Images et illustrations
├── icons/             # Icônes personnalisées
└── fonts/             # Polices personnalisées
```

## 🎨 Design System

### Couleurs Principales
- Primary: `Colors.blue`
- Secondary: `Colors.blue.shade100`
- Background: `Colors.white`
- Text: `Colors.black87`

### Typographie
- Titre: `fontSize: 32, fontWeight: FontWeight.bold`
- Sous-titre: `fontSize: 16, color: Colors.grey.shade600`

## 📱 Fonctionnalités

- [x] Écran de démarrage (Splash Screen)
- [ ] Authentification (Login/Register)
- [ ] Navigation principale
- [ ] Liste des produits
- [ ] Détails produit
- [ ] Panier
- [ ] Profil utilisateur

## 🔧 Développement

### Hot Reload
Flutter supporte le Hot Reload pour un développement rapide :
- Modifiez le code dans Cursor
- Sauvegardez (Ctrl+S)
- L'émulateur Android se met à jour automatiquement

### Debugging
- Utilisez `print()` pour les logs de debug
- L'émulateur Android affiche les erreurs en temps réel
- Console de debug disponible dans Android Studio

## 📦 Assets

### Ajout d'images
1. Placez vos images dans `assets/images/`
2. Utilisez `Image.asset('assets/images/nom_image.png')`

### Configuration
Les assets sont déjà configurés dans `pubspec.yaml` :
```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
    - assets/fonts/
```

## 🚨 Notes Importantes

- **Émulateur requis** : Android Studio avec émulateur Android configuré
- **Hot Reload** : Sauvegardez dans Cursor pour voir les changements
- **Debugging** : Erreurs visibles dans la console de l'émulateur
- **Assets** : Ajoutez vos images dans le dossier assets/ approprié

---

**Prêt à recevoir vos images de design pour générer l'interface !** 🎯
