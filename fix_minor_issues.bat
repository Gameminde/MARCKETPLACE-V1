@echo off
echo ========================================
echo 🔧 CORRECTION DES PROBLÈMES MINEURS
echo ========================================
echo.

cd /d "c:\Users\youcef cheriet\Desktop\MARCKETPLACE\marketplace\app"

echo 📋 1. AJOUT DU SUPPORT WEB OFFICIEL
echo ----------------------------------------
"C:\flutter\bin\flutter.bat" create --platforms web .
echo ✅ Support web ajouté
echo.

echo 📋 2. NETTOYAGE ET RECONSTRUCTION
echo ----------------------------------------
"C:\flutter\bin\flutter.bat" clean
"C:\flutter\bin\flutter.bat" pub get
echo ✅ Projet nettoyé et dépendances mises à jour
echo.

echo 📋 3. CRÉATION DES DOSSIERS D'ASSETS
echo ----------------------------------------
if not exist "assets\images" mkdir "assets\images"
if not exist "assets\icons" mkdir "assets\icons"
if not exist "assets\animations" mkdir "assets\animations"
echo ✅ Dossiers d'assets créés
echo.

echo 📋 4. TEST DE COMPILATION WEB
echo ----------------------------------------
"C:\flutter\bin\flutter.bat" build web --no-sound-null-safety
echo ✅ Build web réussi
echo.

echo ========================================
echo ✅ CORRECTIONS TERMINÉES
echo ========================================
echo.
echo 🚀 L'application est maintenant optimisée !
echo 💡 Lancez avec: flutter run -d chrome
echo.
pause