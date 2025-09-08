@echo off
echo 🧪 Test de l'application Flutter...
echo.

echo 📋 Vérification de l'état Flutter...
..\flutter\bin\flutter.bat doctor
echo.

echo 📱 Liste des appareils disponibles...
..\flutter\bin\flutter.bat devices
echo.

echo 🔧 Nettoyage du projet...
..\flutter\bin\flutter.bat clean
..\flutter\bin\flutter.bat pub get
echo.

echo 🚀 Lancement de l'application...
echo Choisissez votre option:
echo 1. Lancer sur Chrome (recommandé pour test rapide)
echo 2. Lancer sur émulateur Android (si configuré)
echo 3. Lancer sur émulateur Windows
echo.

set /p choice="Votre choix (1-3): "

if "%choice%"=="1" (
    echo 🌐 Lancement sur Chrome...
    ..\flutter\bin\flutter.bat run -d chrome
) else if "%choice%"=="2" (
    echo 📱 Lancement sur émulateur Android...
    ..\flutter\bin\flutter.bat run -d android
) else if "%choice%"=="3" (
    echo 🖥️ Lancement sur Windows...
    ..\flutter\bin\flutter.bat run -d windows
) else (
    echo ❌ Choix invalide. Lancement par défaut sur Chrome...
    ..\flutter\bin\flutter.bat run -d chrome
)

echo.
echo ✅ Test terminé!
pause

