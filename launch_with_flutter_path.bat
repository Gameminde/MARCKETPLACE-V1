@echo off
echo 🚀 LANCEMENT RÉVOLUTION AVEC CHEMIN FLUTTER ABSOLU 🚀
echo ====================================================

cd /d "C:\Users\youcef cheriet\Desktop\MARCKETPLACE\marketplace\app"

echo 📍 Répertoire actuel : %CD%

echo 🔍 Tentative avec différents chemins Flutter...

REM Chemins Flutter possibles
set FLUTTER_PATHS[0]=C:\flutter\bin\flutter.bat
set FLUTTER_PATHS[1]=%USERPROFILE%\flutter\bin\flutter.bat
set FLUTTER_PATHS[2]=C:\src\flutter\bin\flutter.bat
set FLUTTER_PATHS[3]=C:\tools\flutter\bin\flutter.bat
set FLUTTER_PATHS[4]=D:\flutter\bin\flutter.bat

set FLUTTER_FOUND=0

for /L %%i in (0,1,4) do (
    call set "CURRENT_PATH=%%FLUTTER_PATHS[%%i]%%"
    if exist "!CURRENT_PATH!" (
        echo ✅ Flutter trouvé : !CURRENT_PATH!
        set FLUTTER_PATH=!CURRENT_PATH!
        set FLUTTER_FOUND=1
        goto :found
    )
)

:found
if %FLUTTER_FOUND%==0 (
    echo ❌ Flutter non trouvé dans les emplacements standards
    echo.
    echo 📥 SOLUTIONS DISPONIBLES :
    echo 1. Lancez install_flutter.bat pour installer Flutter
    echo 2. Téléchargez Flutter manuellement depuis https://flutter.dev
    echo 3. Si Flutter est installé ailleurs, modifiez ce script
    echo.
    echo 🔧 INSTALLATION MANUELLE RAPIDE :
    echo 1. Téléchargez : https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.6-stable.zip
    echo 2. Extrayez dans C:\flutter\
    echo 3. Relancez ce script
    echo.
    pause
    exit /b 1
)

echo.
echo 🧹 Nettoyage du cache Flutter...
"%FLUTTER_PATH%" clean

echo 📦 Récupération des dépendances...
"%FLUTTER_PATH%" pub get

echo 🌐 Activation du support web...
"%FLUTTER_PATH%" config --enable-web

echo 🔍 Vérification de l'installation...
"%FLUTTER_PATH%" doctor

echo.
echo 🎉 LANCEMENT DE LA RÉVOLUTION !
echo Interface 3D avec glassmorphisme en cours de démarrage...
echo.

"%FLUTTER_PATH%" run -d chrome

if %errorlevel% neq 0 (
    echo.
    echo ❌ Erreur lors du lancement
    echo 🔧 Solutions possibles :
    echo 1. Vérifiez que Chrome est installé
    echo 2. Essayez : "%FLUTTER_PATH%" run -d web-server
    echo 3. Ou : "%FLUTTER_PATH%" run
    echo.
)

pause