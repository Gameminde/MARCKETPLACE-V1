import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

/// 🇩🇿 Algeria Banking Authentication Service
/// Supports CIB, EDAHABIA, and other Algerian banking systems
class BankingAuthService {
  static const String _baseUrl = 'https://api.algeria-marketplace.dz';
  static const Duration _timeout = Duration(seconds: 30);
  
  // Algeria Banking Partners
  static const Map<String, String> _bankingPartners = {
    'CIB': 'Crédit d\'Algérie',
    'EDAHABIA': 'Algérie Poste',
    'BNA': 'Banque Nationale d\'Algérie',
    'BEA': 'Banque Extérieure d\'Algérie',
    'BADR': 'Banque de l\'Agriculture et du Développement Rural',
    'BDL': 'Banque de Développement Local',
    'CNEP': 'Caisse Nationale d\'Épargne et de Prévoyance',
  };

  /// Initialize banking authentication
  Future<BankingAuthResult> initializeBankingAuth({
    required String bankCode,
    required String userId,
    required String deviceId,
  }) async {
    try {
      final payload = {
        'bankCode': bankCode,
        'userId': userId,
        'deviceId': deviceId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'country': 'DZ',
        'currency': 'DZD',
      };

      final signature = _generateSignature(payload);
      payload['signature'] = signature;

      final response = await _makeSecureRequest(
        '/banking/auth/initialize',
        payload,
      );

      return BankingAuthResult.fromJson(response);
    } catch (e) {
      return BankingAuthResult.error('Failed to initialize banking auth: $e');
    }
  }

  /// Authenticate with CIB (Crédit d'Algérie)
  Future<BankingAuthResult> authenticateWithCIB({
    required String cardNumber,
    required String pin,
    required String sessionId,
  }) async {
    try {
      // Validate CIB card format (16 digits starting with specific prefixes)
      if (!_validateCIBCard(cardNumber)) {
        return BankingAuthResult.error('Invalid CIB card format');
      }

      final payload = {
        'bankCode': 'CIB',
        'cardNumber': _encryptCardNumber(cardNumber),
        'pin': _hashPin(pin),
        'sessionId': sessionId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final response = await _makeSecureRequest(
        '/banking/auth/cib',
        payload,
      );

      return BankingAuthResult.fromJson(response);
    } catch (e) {
      return BankingAuthResult.error('CIB authentication failed: $e');
    }
  }

  /// Authenticate with EDAHABIA (Algérie Poste)
  Future<BankingAuthResult> authenticateWithEDAHABIA({
    required String accountNumber,
    required String password,
    required String sessionId,
  }) async {
    try {
      // Validate EDAHABIA account format
      if (!_validateEDAHABIAAccount(accountNumber)) {
        return BankingAuthResult.error('Invalid EDAHABIA account format');
      }

      final payload = {
        'bankCode': 'EDAHABIA',
        'accountNumber': _encryptAccountNumber(accountNumber),
        'password': _hashPassword(password),
        'sessionId': sessionId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final response = await _makeSecureRequest(
        '/banking/auth/edahabia',
        payload,
      );

      return BankingAuthResult.fromJson(response);
    } catch (e) {
      return BankingAuthResult.error('EDAHABIA authentication failed: $e');
    }
  }

  /// Verify banking transaction with OTP
  Future<BankingAuthResult> verifyBankingOTP({
    required String sessionId,
    required String otpCode,
    required String bankCode,
  }) async {
    try {
      final payload = {
        'sessionId': sessionId,
        'otpCode': otpCode,
        'bankCode': bankCode,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final response = await _makeSecureRequest(
        '/banking/auth/verify-otp',
        payload,
      );

      return BankingAuthResult.fromJson(response);
    } catch (e) {
      return BankingAuthResult.error('OTP verification failed: $e');
    }
  }

  /// Get supported banking partners
  Map<String, String> getSupportedBanks() => _bankingPartners;

  /// Validate banking session
  Future<bool> validateBankingSession(String sessionId) async {
    try {
      final response = await _makeSecureRequest(
        '/banking/auth/validate-session',
        {'sessionId': sessionId},
      );
      return response['valid'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Logout from banking session
  Future<void> logoutBankingSession(String sessionId) async {
    try {
      await _makeSecureRequest(
        '/banking/auth/logout',
        {'sessionId': sessionId},
      );
    } catch (e) {
      debugPrint('Banking logout error: $e');
    }
  }

  // Private helper methods

  bool _validateCIBCard(String cardNumber) {
    // Remove spaces and validate format
    final cleaned = cardNumber.replaceAll(' ', '');
    if (cleaned.length != 16) return false;
    
    // CIB cards typically start with specific prefixes
    final validPrefixes = ['4', '5', '6'];
    return validPrefixes.any((prefix) => cleaned.startsWith(prefix));
  }

  bool _validateEDAHABIAAccount(String accountNumber) {
    // EDAHABIA account validation (typically 10-12 digits)
    final cleaned = accountNumber.replaceAll(' ', '');
    return cleaned.length >= 10 && 
           cleaned.length <= 12 && 
           RegExp(r'^\d+$').hasMatch(cleaned);
  }

  String _encryptCardNumber(String cardNumber) {
    // In production, use proper encryption (AES-256)
    // This is a simplified version for demo
    final bytes = utf8.encode(cardNumber);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _encryptAccountNumber(String accountNumber) {
    // In production, use proper encryption (AES-256)
    final bytes = utf8.encode(accountNumber);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + 'algeria_salt_2025');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'edahabia_salt_2025');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateSignature(Map<String, dynamic> payload) {
    final sortedKeys = payload.keys.toList()..sort();
    final signatureString = sortedKeys
        .map((key) => '$key=${payload[key]}')
        .join('&');
    
    final bytes = utf8.encode(signatureString + 'algeria_secret_key');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>> _makeSecureRequest(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    // Simulate API call - replace with actual HTTP client
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mock successful response
    return {
      'success': true,
      'sessionId': 'mock_session_${DateTime.now().millisecondsSinceEpoch}',
      'bankCode': payload['bankCode'],
      'message': 'Authentication successful',
      'expiresAt': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    };
  }
}

/// Banking authentication result
class BankingAuthResult {
  final bool success;
  final String? sessionId;
  final String? bankCode;
  final String? message;
  final String? errorCode;
  final DateTime? expiresAt;
  final Map<String, dynamic>? metadata;

  BankingAuthResult({
    required this.success,
    this.sessionId,
    this.bankCode,
    this.message,
    this.errorCode,
    this.expiresAt,
    this.metadata,
  });

  factory BankingAuthResult.success({
    required String sessionId,
    required String bankCode,
    String? message,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) {
    return BankingAuthResult(
      success: true,
      sessionId: sessionId,
      bankCode: bankCode,
      message: message ?? 'Authentication successful',
      expiresAt: expiresAt,
      metadata: metadata,
    );
  }

  factory BankingAuthResult.error(String message, [String? errorCode]) {
    return BankingAuthResult(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }

  factory BankingAuthResult.fromJson(Map<String, dynamic> json) {
    return BankingAuthResult(
      success: json['success'] ?? false,
      sessionId: json['sessionId'],
      bankCode: json['bankCode'],
      message: json['message'],
      errorCode: json['errorCode'],
      expiresAt: json['expiresAt'] != null 
          ? DateTime.tryParse(json['expiresAt'])
          : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'sessionId': sessionId,
      'bankCode': bankCode,
      'message': message,
      'errorCode': errorCode,
      'expiresAt': expiresAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}