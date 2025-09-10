import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service de sécurité réseau pour certificate pinning et validation
class NetworkSecurityService {
  static final NetworkSecurityService _instance =
      NetworkSecurityService._internal();
  factory NetworkSecurityService() => _instance;
  NetworkSecurityService._internal();

  // Certificats approuvés (SPKI hashes)
  static const List<String> _trustedCertHashes = [
    'SHA256_HASH_1', // Remplacer par le vrai hash du certificat
    'SHA256_HASH_2', // Certificat de backup
  ];

  /// Valide le certificat SSL pour le certificate pinning
  bool validateCertificate(X509Certificate cert, String host, int port) {
    try {
      // Calculer le hash SHA256 du certificat
      final certHash = sha256.convert(cert.der).toString();

      // Vérifier si le hash est dans la liste des certificats approuvés
      final isValid = _trustedCertHashes.contains(certHash);

      if (!isValid) {
        print('⚠️ Certificate pinning failed for $host:$port');
        print('Expected: ${_trustedCertHashes.join(', ')}');
        print('Received: $certHash');
      }

      return isValid;
    } catch (e) {
      print('❌ Certificate validation error: $e');
      return false;
    }
  }

  /// Configure HttpClient avec certificate pinning
  HttpClient createSecureHttpClient() {
    final client = HttpClient();

    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      return validateCertificate(cert, host, port);
    };

    // Configuration de sécurité supplémentaire
    client.connectionTimeout = const Duration(seconds: 30);
    client.idleTimeout = const Duration(seconds: 60);

    return client;
  }

  /// Valide l'intégrité des données reçues
  bool validateDataIntegrity(String data, String expectedHash) {
    try {
      final bytes = utf8.encode(data);
      final hash = sha256.convert(bytes).toString();
      return hash == expectedHash;
    } catch (e) {
      print('❌ Data integrity validation error: $e');
      return false;
    }
  }

  /// Génère un hash sécurisé pour les données sensibles
  String generateSecureHash(String data) {
    final bytes = utf8.encode(data);
    return sha256.convert(bytes).toString();
  }
}
