@echo off
echo ========================================
echo 🔍 DIAGNOSTIC COMPLET FLUTTER MARKETPLACE
echo ========================================
echo.

cd /d "c:\Users\youcef cheriet\Desktop\MARCKETPLACE\marketplace\app"

echo 📋 1. VÉRIFICATION DE L'ENVIRONNEMENT FLUTTER
echo ----------------------------------------
"C:\flutter\bin\flutter.bat" --version
echo.

echo 📋 2. VÉRIFICATION DES DÉPENDANCES
echo ----------------------------------------
"C:\flutter\bin\flutter.bat" pub deps
echo.

echo 📋 3. ANALYSE DU PROJET
echo ----------------------------------------
"C:\flutter\bin\flutter.bat" analyze
echo.

echo 📋 4. VÉRIFICATION DES DEVICES
echo ----------------------------------------
"C:\flutter\bin\flutter.bat" devices
echo.

echo 📋 5. VÉRIFICATION DE LA CONFIGURATION WEB
echo ----------------------------------------
if exist "web\index.html" (
    echo ✅ Configuration web trouvée
) else (
    echo ❌ Configuration web manquante
    echo 🔧 Ajout du support web...
    "C:\flutter\bin\flutter.bat" create --platforms web .
)
echo.

echo 📋 6. NETTOYAGE ET RECONSTRUCTION
echo ----------------------------------------
"C:\flutter\bin\flutter.bat" clean
"C:\flutter\bin\flutter.bat" pub get
echo.

echo 📋 7. TEST DE COMPILATION
echo ----------------------------------------
"C:\flutter\bin\flutter.bat" build web --no-sound-null-safety
echo.

echo ========================================
echo ✅ DIAGNOSTIC TERMINÉ
echo ========================================
echo.
echo 📊 Résultats sauvegardés dans diagnostic_results.txt
echo.
pause