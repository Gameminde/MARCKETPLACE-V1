# Script PowerShell pour installer Android cmdline-tools
# Exécuter en tant qu'administrateur

Write-Host "🔧 Installation des Android cmdline-tools..." -ForegroundColor Green

# Variables
$SDK_PATH = "C:\Users\youcef cheriet\AppData\Local\Android\sdk"
$CMDLINE_TOOLS_PATH = "$SDK_PATH\cmdline-tools"
$LATEST_PATH = "$CMDLINE_TOOLS_PATH\latest"

# Créer le dossier latest
Write-Host "📁 Création du dossier latest..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $LATEST_PATH -Force | Out-Null

# URL de téléchargement des cmdline-tools
$DOWNLOAD_URL = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$ZIP_FILE = "$env:TEMP\commandlinetools-win.zip"

Write-Host "⬇️ Téléchargement des cmdline-tools..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $ZIP_FILE -UseBasicParsing
    Write-Host "✅ Téléchargement terminé" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur de téléchargement: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Solution alternative: Télécharger manuellement depuis https://developer.android.com/studio#command-tools" -ForegroundColor Cyan
    exit 1
}

Write-Host "📦 Extraction des cmdline-tools..." -ForegroundColor Yellow
try {
    # Extraire dans le dossier latest
    Expand-Archive -Path $ZIP_FILE -DestinationPath $LATEST_PATH -Force
    Write-Host "✅ Extraction terminée" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur d'extraction: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Nettoyer le fichier ZIP
Remove-Item $ZIP_FILE -Force

Write-Host "🔧 Configuration des variables d'environnement..." -ForegroundColor Yellow

# Ajouter cmdline-tools au PATH
$CMDLINE_TOOLS_BIN = "$LATEST_PATH\bin"
$CURRENT_PATH = [Environment]::GetEnvironmentVariable("PATH", "User")

if ($CURRENT_PATH -notlike "*$CMDLINE_TOOLS_BIN*") {
    $NEW_PATH = "$CURRENT_PATH;$CMDLINE_TOOLS_BIN"
    [Environment]::SetEnvironmentVariable("PATH", $NEW_PATH, "User")
    Write-Host "✅ PATH mis à jour" -ForegroundColor Green
} else {
    Write-Host "✅ PATH déjà configuré" -ForegroundColor Green
}

Write-Host "🎯 Test de l'installation..." -ForegroundColor Yellow

# Tester sdkmanager
try {
    & "$CMDLINE_TOOLS_BIN\sdkmanager.bat" --version
    Write-Host "✅ cmdline-tools installés avec succès!" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors du test: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Redémarrez le terminal et essayez: flutter doctor --android-licenses" -ForegroundColor Cyan
}

Write-Host "`n🎉 Installation terminée!" -ForegroundColor Green
Write-Host "📋 Prochaines étapes:" -ForegroundColor Cyan
Write-Host "1. Redémarrer le terminal" -ForegroundColor White
Write-Host "2. Exécuter: flutter doctor --android-licenses" -ForegroundColor White
Write-Host "3. Accepter toutes les licences (taper 'y')" -ForegroundColor White
Write-Host "4. Vérifier avec: flutter doctor" -ForegroundColor White

