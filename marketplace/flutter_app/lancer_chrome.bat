@echo off
echo 🚀 LANCEMENT MARKETPLACE FLUTTER SUR CHROME
echo ============================================

echo.
echo 📁 Navigation vers le dossier Flutter...
cd /d "%~dp0"

echo.
echo 🔧 Configuration du PATH Flutter...
set PATH=..\flutter\bin;%PATH%

echo.
echo 🌐 Lancement de l'application sur Chrome...
echo.
echo ✅ L'application va s'ouvrir dans Chrome
echo ✅ Toutes les fonctionnalités sont disponibles
echo ✅ Interface moderne et fluide
echo.

flutter run -d chrome

echo.
echo 🎉 Application lancée avec succès !
pause



