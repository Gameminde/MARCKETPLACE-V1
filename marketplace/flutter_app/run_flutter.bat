@echo off
REM Script pour utiliser Flutter local
set FLUTTER_ROOT=%~dp0..\flutter
set PATH=%FLUTTER_ROOT%\bin;%PATH%

echo Utilisation de Flutter local: %FLUTTER_ROOT%
echo.

REM Vérifier la version de Flutter
echo Vérification de la version Flutter...
flutter --version
echo.

REM Installer les dépendances
echo Installation des dépendances...
flutter pub get
echo.

REM Analyser le code
echo Analyse du code...
flutter analyze
echo.

echo Prêt ! Utilisez 'flutter run' pour lancer l'application.
echo Ou 'flutter build apk' pour créer un APK.
pause
