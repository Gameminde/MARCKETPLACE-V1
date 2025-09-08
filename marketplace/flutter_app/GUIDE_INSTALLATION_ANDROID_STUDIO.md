# 🚀 GUIDE COMPLET - INSTALLATION ANDROID STUDIO + FLUTTER

## 📋 ÉTAT ACTUEL

Votre installation Flutter est **FONCTIONNELLE** mais manque les **cmdline-tools Android**.

### ✅ **DÉJÀ INSTALLÉ**
- Flutter 3.19.6 ✅
- Android Studio 2025.1.3 ✅
- Android SDK ✅
- VS Code + Extensions Flutter ✅

### ❌ **MANQUANT**
- Android cmdline-tools (nécessaire pour compiler Android)

## 🛠️ SOLUTION ÉTAPE PAR ÉTAPE

### **ÉTAPE 1 : Installer cmdline-tools via Android Studio**

#### **1.1 Ouvrir Android Studio**
```
C:\Program Files\Android\Android Studio\bin\studio64.exe
```

#### **1.2 Aller dans Settings**
- **Menu** : `File` → `Settings` (ou `Ctrl+Alt+S`)
- **Navigation** : `Appearance & Behavior` → `System Settings` → `Android SDK`

#### **1.3 Installer cmdline-tools**
- **Onglet** : `SDK Tools`
- **Cocher** : `Android SDK Command-line Tools (latest)`
- **Cliquer** : `Apply` → `OK`
- **Attendre** : Installation automatique (2-3 minutes)

### **ÉTAPE 2 : Accepter les licences Android**

#### **2.1 Ouvrir un nouveau terminal**
```powershell
# Aller dans le dossier Flutter
cd C:\Users\youcef cheriet\Desktop\MARCKETPLACE\marketplace\flutter

# Accepter les licences
.\bin\flutter.bat doctor --android-licenses
```

#### **2.2 Accepter toutes les licences**
- **Taper** : `y` pour chaque licence
- **Appuyer** : `Enter` après chaque `y`

### **ÉTAPE 3 : Vérifier l'installation**

```powershell
.\bin\flutter.bat doctor
```

**Résultat attendu :**
```
[√] Flutter (Channel stable, 3.19.6)
[√] Windows Version
[√] Android toolchain - develop for Android devices
[√] Chrome - develop for the web
[√] Android Studio
[√] VS Code
[√] Connected device (3 available)
[√] Network resources

No issues found!
```

## 📱 CONFIGURATION ÉMULATEUR PIXEL 6

### **ÉTAPE 4 : Créer l'émulateur Pixel 6**

#### **4.1 Ouvrir AVD Manager**
- **Dans Android Studio** : `Tools` → `AVD Manager`
- **Ou** : Cliquer sur l'icône téléphone dans la barre d'outils

#### **4.2 Créer un nouvel émulateur**
- **Cliquer** : `Create Virtual Device`
- **Sélectionner** : `Pixel 6` (dans la catégorie Phone)
- **Cliquer** : `Next`

#### **4.3 Choisir l'image système**
- **Sélectionner** : `API 34` (Android 14) ou `API 33` (Android 13)
- **Si pas installé** : Cliquer sur `Download` à côté de l'API
- **Cliquer** : `Next`

#### **4.4 Configuration finale**
- **Nom** : `Pixel_6_API_34`
- **Orientation** : `Portrait`
- **Cliquer** : `Finish`

## 🚀 TEST DE L'APPLICATION

### **ÉTAPE 5 : Lancer l'émulateur**

#### **5.1 Démarrer l'émulateur**
- **Dans AVD Manager** : Cliquer sur ▶️ à côté de `Pixel_6_API_34`
- **Attendre** : Démarrage complet (2-3 minutes)

#### **5.2 Vérifier que l'émulateur est détecté**
```powershell
cd C:\Users\youcef cheriet\Desktop\MARCKETPLACE\marketplace\flutter_app
..\flutter\bin\flutter.bat devices
```

**Résultat attendu :**
```
2 connected devices:
• sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x64 • Android 14 (API 34)
• Chrome (web)                  • chrome        • web-javascript • Google Chrome
```

### **ÉTAPE 6 : Compiler et lancer l'app**

```powershell
# Compiler et lancer sur l'émulateur
..\flutter\bin\flutter.bat run -d android

# Ou spécifiquement sur l'émulateur
..\flutter\bin\flutter.bat run -d emulator-5554
```

## 🔧 DÉPANNAGE

### **Si cmdline-tools ne s'installe pas :**

#### **Solution 1 : Redémarrer Android Studio**
1. Fermer Android Studio
2. Redémarrer en tant qu'administrateur
3. Réessayer l'installation

#### **Solution 2 : Vérifier la connexion internet**
- Vérifier que vous êtes connecté à internet
- Désactiver temporairement l'antivirus
- Réessayer l'installation

#### **Solution 3 : Installation manuelle**
1. Aller sur : https://developer.android.com/studio#command-tools
2. Télécharger : `commandlinetools-win-11076708_latest.zip`
3. Extraire dans : `C:\Users\youcef cheriet\AppData\Local\Android\sdk\cmdline-tools\latest\`

### **Si l'émulateur ne démarre pas :**

#### **Solution 1 : Vérifier HAXM**
- Aller dans : `Tools` → `SDK Manager` → `SDK Tools`
- Installer : `Intel x86 Emulator Accelerator (HAXM installer)`

#### **Solution 2 : Augmenter la RAM**
- Dans AVD Manager : Cliquer sur ✏️ (Edit) à côté de l'émulateur
- `Advanced Settings` → `RAM` : Augmenter à 4GB ou 6GB

#### **Solution 3 : Utiliser un émulateur x86_64**
- Créer un nouvel émulateur
- Choisir une image `x86_64` au lieu de `arm64`

### **Si l'app ne compile pas :**

#### **Solution 1 : Nettoyer le projet**
```powershell
..\flutter\bin\flutter.bat clean
..\flutter\bin\flutter.bat pub get
```

#### **Solution 2 : Vérifier les permissions**
- Exécuter le terminal en tant qu'administrateur
- Vérifier que Flutter a accès au dossier du projet

## ⚡ COMMANDES RAPIDES

```powershell
# Vérifier l'état Flutter
..\flutter\bin\flutter.bat doctor

# Lister les appareils
..\flutter\bin\flutter.bat devices

# Nettoyer le projet
..\flutter\bin\flutter.bat clean

# Installer les dépendances
..\flutter\bin\flutter.bat pub get

# Lancer sur émulateur
..\flutter\bin\flutter.bat run -d android

# Lancer sur Chrome (fallback)
..\flutter\bin\flutter.bat run -d chrome
```

## 🎯 RÉSULTAT FINAL

Une fois toutes ces étapes terminées, vous devriez avoir :

1. ✅ **Flutter fonctionnel** avec Android toolchain complet
2. ✅ **Émulateur Pixel 6** configuré et fonctionnel
3. ✅ **Application Flutter** qui compile et s'exécute sur l'émulateur
4. ✅ **Hot Reload** fonctionnel pour le développement

## 🆘 SUPPORT

Si vous rencontrez des problèmes :

1. **Vérifiez** : `flutter doctor` pour identifier les problèmes
2. **Consultez** : Les guides de dépannage ci-dessus
3. **Redémarrez** : Android Studio et l'émulateur
4. **Testez** : D'abord sur Chrome, puis sur l'émulateur

---

**🎉 Votre marketplace Flutter sera bientôt fonctionnelle sur Android Studio avec l'émulateur Pixel 6 !**

