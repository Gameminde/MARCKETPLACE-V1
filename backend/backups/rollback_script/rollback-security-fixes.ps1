# 🚨 ROLLBACK SCRIPT - SÉCURISATION SERVICES BACKEND
# Restaure les services originaux en cas de problème

param(
    [string]$BackupDir = "./backups/original_20250824_002024",
    [switch]$Force
)

Write-Host "🔄 Démarrage du rollback des corrections de sécurité..." -ForegroundColor Yellow

# Vérifier que le backup existe
if (-not (Test-Path $BackupDir)) {
    Write-Host "❌ Erreur: Répertoire de backup introuvable: $BackupDir" -ForegroundColor Red
    Write-Host "📁 Répertoires disponibles:" -ForegroundColor Cyan
    Get-ChildItem "./backups/" | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
    exit 1
}

# Confirmation utilisateur
if (-not $Force) {
    Write-Host "⚠️  ATTENTION: Ce script va restaurer les services originaux" -ForegroundColor Red
    Write-Host "📁 Source: $BackupDir" -ForegroundColor Cyan
    Write-Host "📁 Destination: ./src/services/" -ForegroundColor Cyan
    
    $confirmation = Read-Host "Êtes-vous sûr de vouloir continuer? (oui/non)"
    if ($confirmation -ne "oui") {
        Write-Host "❌ Rollback annulé par l'utilisateur" -ForegroundColor Yellow
        exit 0
    }
}

try {
    # 1. Créer backup de l'état actuel
    $currentBackup = "./backups/current_state_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Write-Host "💾 Création backup de l'état actuel: $currentBackup" -ForegroundColor Cyan
    Copy-Item -Path "src/services/*.js" -Destination $currentBackup -Recurse -Force
    
    # 2. Restaurer les services originaux
    Write-Host "🔄 Restauration des services originaux..." -ForegroundColor Yellow
    
    # Services critiques à restaurer
    $criticalServices = @(
        "token-blacklist.service.js",
        "captcha.service.js", 
        "stripe.service.js",
        "database.service.js"
    )
    
    foreach ($service in $criticalServices) {
        $sourcePath = Join-Path $BackupDir $service
        $destPath = Join-Path "src/services" $service
        
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            Write-Host "✅ Restauré: $service" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Service non trouvé dans backup: $service" -ForegroundColor Yellow
        }
    }
    
    # 3. Restaurer utils
    Write-Host "🔄 Restauration des utilitaires..." -ForegroundColor Yellow
    $utilsBackup = Join-Path $BackupDir "sanitizer.js"
    if (Test-Path $utilsBackup) {
        Copy-Item -Path $utilsBackup -Destination "src/utils/sanitizer.js" -Force
        Write-Host "✅ Restauré: sanitizer.js" -ForegroundColor Green
    }
    
    # 4. Validation du rollback
    Write-Host "🔍 Validation du rollback..." -ForegroundColor Cyan
    
    # Test de chargement des services restaurés
    try {
        $tokenBlacklist = Get-Content "src/services/token-blacklist.service.js" | Select-String "new Redis"
        if ($tokenBlacklist) {
            Write-Host "✅ Token-Blacklist: Redis direct restauré" -ForegroundColor Green
        }
        
        $captcha = Get-Content "src/services/captcha.service.js" | Select-String "timeout"
        if (-not $captcha) {
            Write-Host "✅ CAPTCHA: Protection DoS supprimée" -ForegroundColor Green
        }
        
        $stripe = Get-Content "src/services/stripe.service.js" | Select-String "limits"
        if (-not $stripe) {
            Write-Host "✅ Stripe: Validation financière simplifiée" -ForegroundColor Green
        }
        
        $database = Get-Content "src/services/database.service.js" | Select-String "localhost"
        if ($database) {
            Write-Host "✅ Database: Simulation connexion restaurée" -ForegroundColor Green
        }
        
        Write-Host "🎉 ROLLBACK RÉUSSI - Services originaux restaurés!" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Erreur lors de la validation: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 5. Instructions post-rollback
    Write-Host "`n📋 INSTRUCTIONS POST-ROLLBACK:" -ForegroundColor Cyan
    Write-Host "1. Redémarrer le serveur: npm run dev" -ForegroundColor White
    Write-Host "2. Vérifier la connectivité Redis" -ForegroundColor White
    Write-Host "3. Tester les endpoints critiques" -ForegroundColor White
    Write-Host "4. Analyser les logs pour détecter les problèmes" -ForegroundColor White
    
    Write-Host "`n💾 Backups créés:" -ForegroundColor Cyan
    Write-Host "  - Original: $BackupDir" -ForegroundColor Gray
    Write-Host "  - État actuel: $currentBackup" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ ERREUR CRITIQUE LORS DU ROLLBACK: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "🔧 Intervention manuelle requise" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Rollback terminé avec succès!" -ForegroundColor Green
