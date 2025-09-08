# 🚀 Script PowerShell pour Flutter Marketplace
# Configuration automatique du PATH et lancement

Write-Host "🚀 Lancement de l'application Flutter Marketplace..." -ForegroundColor Green
Write-Host ""

# Configuration du PATH Flutter local
$flutterPath = "..\flutter\bin"
$currentPath = $env:PATH
$env:PATH = "$flutterPath;$currentPath"

Write-Host "📋 Configuration du PATH Flutter..." -ForegroundColor Yellow
Write-Host "   Flutter Path: $flutterPath" -ForegroundColor Gray

# Vérification de Flutter
Write-Host "🔍 Vérification de Flutter..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Flutter trouvé et fonctionnel" -ForegroundColor Green
        Write-Host "   $($flutterVersion[0])" -ForegroundColor Gray
    } else {
        throw "Flutter non trouvé"
    }
} catch {
    Write-Host "❌ Erreur: Flutter non trouvé dans le PATH" -ForegroundColor Red
    Write-Host "   Vérifiez que le dossier flutter existe dans: $flutterPath" -ForegroundColor Yellow
    Read-Host "Appuyez sur Entrée pour quitter"
    exit 1
}

Write-Host ""
Write-Host "🔧 Installation des dépendances..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de l'installation des dépendances" -ForegroundColor Red
    Read-Host "Appuyez sur Entrée pour quitter"
    exit 1
}

Write-Host ""
Write-Host "🔍 Analyse du code..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Warnings détectés, mais continuons..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🚀 Lancement de l'application..." -ForegroundColor Green
Write-Host "Choisissez votre plateforme:" -ForegroundColor Cyan
Write-Host "1. Chrome (Web) - Recommandé" -ForegroundColor White
Write-Host "2. Windows (Desktop)" -ForegroundColor White
Write-Host "3. Edge (Web)" -ForegroundColor White
Write-Host "4. Tous les appareils disponibles" -ForegroundColor White
Write-Host ""

do {
    $choice = Read-Host "Votre choix (1-4)"
} while ($choice -notmatch '^[1-4]$')

switch ($choice) {
    "1" {
        Write-Host "🌐 Lancement sur Chrome..." -ForegroundColor Blue
        flutter run -d chrome
    }
    "2" {
        Write-Host "🖥️  Lancement sur Windows..." -ForegroundColor Blue
        flutter run -d windows
    }
    "3" {
        Write-Host "🌐 Lancement sur Edge..." -ForegroundColor Blue
        flutter run -d edge
    }
    "4" {
        Write-Host "📱 Affichage des appareils disponibles..." -ForegroundColor Blue
        flutter devices
        Write-Host ""
        $device = Read-Host "Entrez l'ID de l'appareil (ou laissez vide pour Chrome)"
        if ($device) {
            flutter run -d $device
        } else {
            flutter run -d chrome
        }
    }
}

Write-Host ""
Write-Host "✅ Application lancée avec succès!" -ForegroundColor Green
Write-Host "💡 Utilisez 'r' pour Hot Reload, 'R' pour Hot Restart, 'q' pour quitter" -ForegroundColor Cyan
Write-Host "🔧 DevTools: http://127.0.0.1:9100" -ForegroundColor Gray



