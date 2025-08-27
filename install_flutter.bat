@echo off
echo 🚀 INSTALLATION FLUTTER POUR RÉVOLUTION MARKETPLACE 🚀
echo =====================================================

echo 📍 Création du répertoire Flutter...
if not exist "C:\flutter" mkdir "C:\flutter"

echo 📥 Téléchargement de Flutter...
echo 🔗 Ouvrez ce lien dans votre navigateur :
echo https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.6-stable.zip

echo.
echo 📋 INSTRUCTIONS MANUELLES :
echo 1. Téléchargez le fichier ZIP depuis le lien ci-dessus
echo 2. Extrayez le contenu dans C:\flutter\
echo 3. Ajoutez C:\flutter\bin au PATH système
echo.

echo 🔧 ALTERNATIVE : Installation avec Git (si disponible)
where git >nul 2>nul
if %errorlevel% == 0 (
    echo ✅ Git détecté - Installation automatique possible
    echo Voulez-vous installer Flutter avec Git ? (O/N)
    set /p choice=
    if /i "%choice%"=="O" (
        cd /d C:\
        git clone https://github.com/flutter/flutter.git -b stable
        echo ✅ Flutter installé dans C:\flutter\
        goto :configure
    )
) else (
    echo ❌ Git non disponible - Installation manuelle requise
)

echo.
echo 📝 Après téléchargement et extraction :
echo 1. Relancez launch_revolution.bat
echo 2. Ou utilisez les commandes manuelles ci-dessous

:configure
echo.
echo 🔧 CONFIGURATION PATH SYSTÈME :
echo Ajoutez cette ligne à votre PATH :
echo C:\flutter\bin
echo.
echo 📋 COMMANDES MANUELLES APRÈS INSTALLATION :
echo cd "C:\Users\youcef cheriet\Desktop\MARCKETPLACE\marketplace\app"
echo C:\flutter\bin\flutter.bat doctor
echo C:\flutter\bin\flutter.bat clean
echo C:\flutter\bin\flutter.bat pub get
echo C:\flutter\bin\flutter.bat config --enable-web
echo C:\flutter\bin\flutter.bat run -d chrome

pause