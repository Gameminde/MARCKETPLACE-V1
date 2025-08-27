@echo off
echo 🚀 INSTALLATION FLUTTER DEPUIS DOWNLOADS - RÉVOLUTION MARKETPLACE 🚀
echo ================================================================

echo 📍 Vérification du fichier Flutter téléchargé...

set DOWNLOADS_PATH=C:\Users\youcef cheriet\Downloads
set FLUTTER_ZIP=%DOWNLOADS_PATH%\flutter_windows_3.19.6-stable.zip
set FLUTTER_FOLDER=%DOWNLOADS_PATH%\flutter

echo 🔍 Recherche du fichier Flutter...

REM Vérification de différents noms possibles
if exist "%DOWNLOADS_PATH%\flutter_windows_3.19.6-stable.zip" (
    set FLUTTER_ZIP=%DOWNLOADS_PATH%\flutter_windows_3.19.6-stable.zip
    echo ✅ Trouvé : flutter_windows_3.19.6-stable.zip
    goto :extract
)

if exist "%DOWNLOADS_PATH%\flutter_windows_stable.zip" (
    set FLUTTER_ZIP=%DOWNLOADS_PATH%\flutter_windows_stable.zip
    echo ✅ Trouvé : flutter_windows_stable.zip
    goto :extract
)

if exist "%DOWNLOADS_PATH%\flutter.zip" (
    set FLUTTER_ZIP=%DOWNLOADS_PATH%\flutter.zip
    echo ✅ Trouvé : flutter.zip
    goto :extract
)

REM Vérification si déjà extrait
if exist "%FLUTTER_FOLDER%\bin\flutter.bat" (
    echo ✅ Flutter déjà extrait dans Downloads !
    goto :move
)

echo ❌ Fichier ZIP Flutter non trouvé dans Downloads
echo 📁 Contenu du dossier Downloads :
dir "%DOWNLOADS_PATH%\*flutter*" /b
echo.
echo 📝 Veuillez vérifier que le fichier Flutter ZIP est bien dans :
echo %DOWNLOADS_PATH%
pause
exit /b 1

:extract
echo 📦 Extraction de Flutter...
echo Source : %FLUTTER_ZIP%
echo Destination : %DOWNLOADS_PATH%

REM Extraction avec PowerShell (plus fiable)
powershell -Command "Expand-Archive -Path '%FLUTTER_ZIP%' -DestinationPath '%DOWNLOADS_PATH%' -Force"

if %errorlevel% neq 0 (
    echo ❌ Erreur lors de l'extraction
    echo 🔧 Essai avec méthode alternative...
    
    REM Méthode alternative avec tar (Windows 10+)
    tar -xf "%FLUTTER_ZIP%" -C "%DOWNLOADS_PATH%"
    
    if %errorlevel% neq 0 (
        echo ❌ Extraction échouée
        echo 📝 Veuillez extraire manuellement le ZIP dans C:\flutter\
        pause
        exit /b 1
    )
)

echo ✅ Extraction réussie !

:move
echo 📁 Déplacement de Flutter vers C:\flutter\...

if exist "C:\flutter" (
    echo 🗑️ Suppression de l'ancien dossier Flutter...
    rmdir /s /q "C:\flutter"
)

echo 📂 Création du répertoire C:\flutter\...
mkdir "C:\flutter"

echo 🚚 Déplacement des fichiers...
xcopy "%FLUTTER_FOLDER%\*" "C:\flutter\" /E /I /H /Y

if %errorlevel% neq 0 (
    echo ❌ Erreur lors du déplacement
    echo 🔧 Tentative de copie alternative...
    robocopy "%FLUTTER_FOLDER%" "C:\flutter" /E /COPYALL
)

echo ✅ Flutter installé dans C:\flutter\

:verify
echo 🔍 Vérification de l'installation...
if exist "C:\flutter\bin\flutter.bat" (
    echo ✅ Installation réussie !
    echo 📍 Flutter disponible : C:\flutter\bin\flutter.bat
) else (
    echo ❌ Installation incomplète
    echo 📝 Vérifiez manuellement le dossier C:\flutter\
    pause
    exit /b 1
)

echo.
echo 🧹 Nettoyage des fichiers temporaires...
if exist "%FLUTTER_FOLDER%" (
    rmdir /s /q "%FLUTTER_FOLDER%"
    echo ✅ Dossier temporaire supprimé
)

echo.
echo 🎉 FLUTTER INSTALLÉ AVEC SUCCÈS !
echo ================================

echo 📋 Prochaines étapes :
echo 1. Lancement de la vérification Flutter
echo 2. Configuration du projet marketplace
echo 3. Démarrage de la révolution interface !

echo.
echo 🔍 Test de Flutter...
"C:\flutter\bin\flutter.bat" --version

echo.
echo 🚀 LANCEMENT AUTOMATIQUE DE LA RÉVOLUTION !
echo ===========================================

cd /d "C:\Users\youcef cheriet\Desktop\MARCKETPLACE\marketplace\app"

echo 🧹 Nettoyage du cache...
"C:\flutter\bin\flutter.bat" clean

echo 📦 Récupération des dépendances...
"C:\flutter\bin\flutter.bat" pub get

echo 🌐 Activation du support web...
"C:\flutter\bin\flutter.bat" config --enable-web

echo 🔍 Diagnostic Flutter...
"C:\flutter\bin\flutter.bat" doctor

echo.
echo 🎉 LANCEMENT DE LA RÉVOLUTION INTERFACE 3D !
echo ============================================
echo Interface marketplace révolutionnaire en cours de démarrage...
echo.

"C:\flutter\bin\flutter.bat" run -d chrome

if %errorlevel% neq 0 (
    echo.
    echo ⚠️ Problème de lancement avec Chrome
    echo 🔧 Tentative avec serveur web...
    "C:\flutter\bin\flutter.bat" run -d web-server --web-port=8080
    
    if %errorlevel% neq 0 (
        echo.
        echo 📝 Lancement manuel requis
        echo Utilisez : "C:\flutter\bin\flutter.bat" run
    ) else (
        echo.
        echo 🌐 Application disponible sur : http://localhost:8080
        start http://localhost:8080
    )
)

echo.
echo 🏆 RÉVOLUTION TERMINÉE !
echo Votre interface marketplace 3D révolutionnaire est maintenant active !

pause