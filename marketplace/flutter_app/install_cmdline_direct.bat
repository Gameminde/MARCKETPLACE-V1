@echo off
echo 🔧 Installation directe des Android cmdline-tools...
echo.

REM Variables
set SDK_PATH=C:\Users\youcef cheriet\AppData\Local\Android\sdk
set CMDLINE_TOOLS_PATH=%SDK_PATH%\cmdline-tools
set LATEST_PATH=%CMDLINE_TOOLS_PATH%\latest
set DOWNLOAD_URL=https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip
set ZIP_FILE=%TEMP%\commandlinetools-win.zip

echo 📁 Création des dossiers...
if not exist "%CMDLINE_TOOLS_PATH%" mkdir "%CMDLINE_TOOLS_PATH%"
if not exist "%LATEST_PATH%" mkdir "%LATEST_PATH%"

echo ⬇️ Téléchargement des cmdline-tools...
echo URL: %DOWNLOAD_URL%
echo Destination: %ZIP_FILE%

powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing}"

if not exist "%ZIP_FILE%" (
    echo ❌ Erreur: Impossible de télécharger les cmdline-tools
    echo 💡 Solution: Téléchargez manuellement depuis https://developer.android.com/studio#command-tools
    pause
    exit /b 1
)

echo ✅ Téléchargement terminé

echo 📦 Extraction des cmdline-tools...
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%LATEST_PATH%' -Force"

echo ✅ Extraction terminée

echo 🧹 Nettoyage...
del "%ZIP_FILE%"

echo 🔧 Test de l'installation...
"%LATEST_PATH%\bin\sdkmanager.bat" --version

if %errorlevel% equ 0 (
    echo ✅ cmdline-tools installés avec succès!
    echo.
    echo 📋 Prochaines étapes:
    echo 1. Redémarrer le terminal
    echo 2. Exécuter: flutter doctor --android-licenses
    echo 3. Accepter toutes les licences (taper 'y')
    echo 4. Vérifier avec: flutter doctor
) else (
    echo ❌ Erreur lors du test des cmdline-tools
    echo 💡 Vérifiez que le dossier %LATEST_PATH%\bin existe
)

echo.
pause
