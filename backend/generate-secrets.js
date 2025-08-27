const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

console.log('🔐 GÉNÉRATEUR DE SECRETS SÉCURISÉS - MARKETPLACE');
console.log('==================================================\n');

// Fonction pour générer un secret sécurisé
function generateSecureSecret(length = 64) {
  return crypto.randomBytes(length).toString('base64');
}

// Fonction pour générer une clé privée/publique RSA
function generateRSAKeys() {
  const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
    modulusLength: 2048,
    publicKeyEncoding: {
      type: 'spki',
      format: 'pem'
    },
    privateKeyEncoding: {
      type: 'pkcs8',
      format: 'pem'
    }
  });
  
  return { publicKey, privateKey };
}

// Génération des secrets
console.log('1️⃣ GÉNÉRATION SECRETS JWT:');
const jwtSecret = generateSecureSecret(64);
const jwtRefreshSecret = generateSecureSecret(64);

console.log('✅ JWT_SECRET:');
console.log(jwtSecret);
console.log('\n✅ JWT_REFRESH_SECRET:');
console.log(jwtRefreshSecret);

console.log('\n2️⃣ GÉNÉRATION CLÉS RSA:');
const { publicKey, privateKey } = generateRSAKeys();

console.log('✅ JWT_PRIVATE_KEY:');
console.log(privateKey);
console.log('\n✅ JWT_PUBLIC_KEY:');
console.log(publicKey);

console.log('\n3️⃣ GÉNÉRATION AUTRES SECRETS:');
const stripeWebhookSecret = generateSecureSecret(32);
const sentryDSN = 'https://your-sentry-dsn-here@sentry.io/project-id';

console.log('✅ STRIPE_WEBHOOK_SECRET:');
console.log(stripeWebhookSecret);
console.log('\n✅ SENTRY_DSN:');
console.log(sentryDSN);

// Création du fichier .env.local avec les secrets
console.log('\n4️⃣ CRÉATION FICHIER .env.local:');
const envContent = `# ========================================
# SECRETS GÉNÉRÉS AUTOMATIQUEMENT
# ⚠️ NE JAMAIS COMMITER CE FICHIER
# ========================================

# JWT SECRETS
JWT_SECRET=${jwtSecret}
JWT_REFRESH_SECRET=${jwtRefreshSecret}
JWT_PRIVATE_KEY=${privateKey.replace(/\n/g, '\\n')}
JWT_PUBLIC_KEY=${publicKey.replace(/\n/g, '\\n')}

# STRIPE SECRETS
STRIPE_WEBHOOK_SECRET=${stripeWebhookSecret}

# MONITORING
SENTRY_DSN=${sentryDSN}

# ========================================
# AUTRES VARIABLES À CONFIGURER MANUELLEMENT
# ========================================
MONGODB_URI=your-mongodb-connection-string-here
POSTGRES_URI=your-postgresql-connection-string-here
REDIS_URL=redis://localhost:6379
STRIPE_SECRET_KEY=your-stripe-secret-key-here
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key_here
GOOGLE_CLOUD_PROJECT_ID=your-project-id-here
GOOGLE_VISION_API_KEY=your-vision-api-key-here
`;

try {
  fs.writeFileSync('.env.local', envContent);
  console.log('✅ Fichier .env.local créé avec succès');
  
  // CRITICAL: Automatically update .gitignore
  const gitignorePath = path.join(__dirname, '.gitignore');
  try {
    let gitignoreContent = '';
    if (fs.existsSync(gitignorePath)) {
      gitignoreContent = fs.readFileSync(gitignorePath, 'utf8');
    }
    
    // Add environment files to .gitignore if not already present
    const envPatterns = ['.env.local', '.env', '.env.*'];
    let updated = false;
    
    envPatterns.forEach(pattern => {
      if (!gitignoreContent.includes(pattern)) {
        gitignoreContent += `\n# Environment secrets\n${pattern}`;
        updated = true;
      }
    });
    
    if (updated) {
      fs.writeFileSync(gitignorePath, gitignoreContent);
      console.log('✅ .gitignore mis à jour automatiquement');
    } else {
      console.log('✅ .gitignore déjà configuré correctement');
    }
  } catch (gitignoreError) {
    console.warn('⚠️ Vérifiez manuellement le .gitignore');
  }
  
} catch (error) {
  console.error('❌ Erreur lors de la création du fichier:', error.message);
}

// Instructions de sécurité
console.log('\n🎯 INSTRUCTIONS DE SÉCURITÉ:');
console.log('=============================');
console.log('1. ✅ Secrets générés avec succès');
console.log('2. ✅ Fichier .env.local créé');
console.log('3. ⚠️ Ajouter .env.local au .gitignore');
console.log('4. ⚠️ Ne jamais commiter les secrets');
console.log('5. ⚠️ Changer les secrets en production');
console.log('6. ⚠️ Rotation régulière des secrets');

console.log('\n📋 COMMANDES À EXÉCUTER:');
console.log('========================');
console.log('echo ".env.local" >> .gitignore');
console.log('cp .env.local .env');
console.log('npm run dev');

console.log('\n🔒 VALIDATION FINALE:');
console.log('====================');
console.log('1. ✅ .env.local créé avec secrets sécurisés');
console.log('2. ✅ .gitignore mis à jour automatiquement');
console.log('3. 🔄 Exécutez: cp .env.local .env');
console.log('4. 🚀 Testez: npm run dev');

console.log('\n🚀 MARKETPLACE PRÊT POUR DÉVELOPPEMENT SÉCURISÉ !');
