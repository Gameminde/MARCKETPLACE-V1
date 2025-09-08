@echo off
echo 🚀 TEST ANDROID - MARKETPLACE FLUTTER
echo =====================================

echo.
echo 📱 Vérification de la structure Android...
if exist "android\app\src\main\AndroidManifest.xml" (
    echo ✅ AndroidManifest.xml trouvé
) else (
    echo ❌ AndroidManifest.xml manquant
    exit /b 1
)

if exist "android\app\build.gradle" (
    echo ✅ build.gradle trouvé
) else (
    echo ❌ build.gradle manquant
    exit /b 1
)

echo.
echo 🔧 Configuration du PATH Flutter...
set PATH=..\flutter\bin;%PATH%

echo.
echo 📋 Vérification des appareils disponibles...
flutter devices

echo.
echo 🎯 Test de compilation Android...
flutter build apk --debug

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ SUCCÈS ! L'application est prête pour Android Studio
    echo.
    echo 📱 Pour lancer sur Android Studio :
    echo 1. Ouvrir Android Studio
    echo 2. File → Open
    echo 3. Sélectionner ce dossier
    echo 4. Sélectionner l'émulateur Pixel 6
    echo 5. Cliquer Run ▶️
) else (
    echo.
    echo ❌ Erreur de compilation
    echo Vérifiez la configuration Android
)

echo.
pause


