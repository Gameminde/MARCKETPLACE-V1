/**
 * Audit configuration for Algeria Marketplace Phase 2 standards
 */

import { AuditConfiguration } from '../types/audit-types';

export const AUDIT_CONFIG: AuditConfiguration = {
  thresholds: {
    overall: 90,        // Phase 2 ready when ≥ 90/100
    security: 100,      // Banking-grade security (non-negotiable)
    performance: 95,    // 45M users performance requirement
    environment: 95,    // Build stability requirement
    codeQuality: 90,    // Production-ready code standards
    uiux: 95           // Algeria compliance requirement
  },
  
  algeriaStandards: {
    colorPalette: [
      '#051F20',  // Algeria green dark
      '#0A3D40',  // Algeria green medium
      '#1A5D60',  // Algeria green light
      '#DAFDE2'   // Algeria green accent
    ],
    rtlSupport: true,
    currencyFormat: 'DZD',
    bankingCompliance: [
      'CIB',
      'EDAHABIA',
      'end-to-end-encryption',
      'secure-authentication',
      'input-validation'
    ]
  },
  
  performanceTargets: {
    coldStartTime: 3000,      // < 3 seconds
    animationFPS: 60,         // 60 FPS maintained
    apiResponseTime: 500,     // < 500ms
    memoryUsage: 150          // < 150MB baseline
  }
};

export const FLUTTER_REQUIREMENTS = {
  minFlutterVersion: '3.35.0',
  minDartVersion: '3.9.0',
  maxFlutterVersion: '4.0.0',
  maxDartVersion: '4.0.0',
  recommendedFlutterVersion: '3.35.3',
  recommendedDartVersion: '3.9.2'
};

export const ANDROID_REQUIREMENTS = {
  minGradleVersion: '8.6',
  minAGPVersion: '8.6.0',
  minKotlinVersion: '2.1.0',
  targetSDK: 35,
  minSDK: 21
};

export const SECURITY_STANDARDS = {
  encryptionAlgorithms: ['AES-256', 'RSA-2048'],
  hashingAlgorithms: ['SHA-256', 'bcrypt'],
  tlsVersion: '1.3',
  certificatePinning: true,
  biometricAuth: true
};