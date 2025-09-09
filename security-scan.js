#!/usr/bin/env node
/**
 * SECURITY VALIDATION SCRIPT
 * Validates that no secrets are exposed in the codebase
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

console.log('🔍 VALIDATION DE SÉCURITÉ - MARKETPLACE');
console.log('=====================================\n');

const DANGEROUS_PATTERNS = [
  /mongodb+srv://[^\s]+/gi,
  /postgresql://[^\s]+/gi,
  /sk_test_[a-zA-Z0-9]+/gi,
  /sk_live_[a-zA-Z0-9]+/gi,
  /AIzaSy[a-zA-Z0-9_-]+/gi,
  /AKIA[0-9A-Z]{16}/gi,
  /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi
];

function scanFile(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    const violations = [];
    
    DANGEROUS_PATTERNS.forEach((pattern, index) => {
      const matches = content.match(pattern);
      if (matches) {
        violations.push({
          pattern: index,
          matches: matches.length,
          file: filePath
        });
      }
    });
    
    return violations;
  } catch (error) {
    return [];
  }
}

function scanDirectory(dir, violations = []) {
  const files = fs.readdirSync(dir);
  
  files.forEach(file => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    
    if (stat.isDirectory() && !file.startsWith('.') && file !== 'node_modules') {
      scanDirectory(filePath, violations);
    } else if (stat.isFile() && (file.endsWith('.js') || file.endsWith('.json') || file.endsWith('.env'))) {
      const fileViolations = scanFile(filePath);
      violations.push(...fileViolations);
    }
  });
  
  return violations;
}

const violations = scanDirectory('.');

if (violations.length === 0) {
  console.log('✅ AUCUNE VIOLATION DE SÉCURITÉ DÉTECTÉE');
  console.log('✅ Tous les secrets semblent être correctement protégés');
} else {
  console.log('❌ VIOLATIONS DE SÉCURITÉ DÉTECTÉES:');
  violations.forEach(violation => {
    console.log(`   📁 ${violation.file}: ${violation.matches} pattern(s) dangereux`);
  });
  console.log('\n🚨 ACTION REQUISE: Supprimez immédiatement les secrets exposés!');
  process.exit(1);
}

console.log('\n🔒 VALIDATION TERMINÉE');
