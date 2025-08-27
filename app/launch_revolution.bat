@echo off
echo 🚀 LANCEMENT RÉVOLUTION INTERFACE MARKETPLACE 🚀
echo ================================================

cd /d "%~dp0"

echo 📍 Répertoire actuel : %CD%

echo 🔍 Recherche de Flutter...

REM Tentative de localisation de Flutter
set FLUTTER_PATH=
if exist "C:\flutter\bin\flutter.bat" (
    set FLUTTER_PATH=C:\flutter\bin\flutter.bat
    echo ✅ Flutter trouvé : C:\flutter\bin\
) else if exist "%USERPROFILE%\flutter\bin\flutter.bat" (
    set FLUTTER_PATH=%USERPROFILE%\flutter\bin\flutter.bat
    echo ✅ Flutter trouvé : %USERPROFILE%\flutter\bin\
) else if exist "C:\src\flutter\bin\flutter.bat" (
    set FLUTTER_PATH=C:\src\flutter\bin\flutter.bat
    echo ✅ Flutter trouvé : C:\src\flutter\bin\
) else (
    echo ❌ Flutter non trouvé dans les emplacements standards
    echo 📝 Veuillez installer Flutter ou ajouter Flutter au PATH
    echo 🔗 https://docs.flutter.dev/get-started/install/windows
    pause
    exit /b 1
)

echo 🧹 Nettoyage du cache Flutter...
"%FLUTTER_PATH%" clean

echo 📦 Récupération des dépendances...
"%FLUTTER_PATH%" pub get

echo 🌐 Activation du support web...
"%FLUTTER_PATH%" config --enable-web

echo 🎉 LANCEMENT DE LA RÉVOLUTION !
echo Interface 3D avec glassmorphisme en cours de démarrage...
"%FLUTTER_PATH%" run -d chrome

pause