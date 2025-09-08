@echo off
echo 🚀 Lancement de l'application Flutter Marketplace...
echo.

REM Configuration du PATH Flutter local
set PATH=..\flutter\bin;%PATH%

REM Vérification de Flutter
echo 📋 Vérification de Flutter...
flutter --version
if %errorlevel% neq 0 (
    echo ❌ Erreur: Flutter non trouvé
    pause
    exit /b 1
)

echo.
echo 🔧 Installation des dépendances...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Erreur lors de l'installation des dépendances
    pause
    exit /b 1
)

echo.
echo 🔍 Analyse du code...
flutter analyze
if %errorlevel% neq 0 (
    echo ⚠️  Warnings détectés, mais continuons...
)

echo.
echo 🚀 Lancement de l'application...
echo Choisissez votre plateforme:
echo 1. Chrome (Web)
echo 2. Windows (Desktop)
echo 3. Edge (Web)
echo.
set /p choice="Votre choix (1-3): "

if "%choice%"=="1" (
    echo 🌐 Lancement sur Chrome...
    flutter run -d chrome
) else if "%choice%"=="2" (
    echo 🖥️  Lancement sur Windows...
    flutter run -d windows
) else if "%choice%"=="3" (
    echo 🌐 Lancement sur Edge...
    flutter run -d edge
) else (
    echo ❌ Choix invalide
    pause
    exit /b 1
)

echo.
echo ✅ Application lancée avec succès!
echo 💡 Utilisez 'r' pour Hot Reload, 'R' pour Hot Restart, 'q' pour quitter
pause




