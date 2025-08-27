import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'validation_service.dart';

/// Authentication service following Single Responsibility Principle
class AuthService {
  final ApiService _apiService;
  final ValidationService _validationService;

  AuthService({
    ApiService? apiService,
    ValidationService? validationService,
  }) : _apiService = apiService ?? ApiService(),
        _validationService = validationService ?? ValidationService();

  /// Register a new user with comprehensive validation
  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Input validation and sanitization
      final sanitizedData = _validationService.sanitizeRegistrationData({
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'email': email,
        'password': password,
      });

      // Validate all fields
      final validationResult = _validationService.validateRegistration(sanitizedData);
      if (!validationResult.isValid) {
        return AuthResult.failure(validationResult.errors.first);
      }

      final response = await _apiService.client.post('/auth/register', data: {
        'firstName': sanitizedData['firstName'],
        'lastName': sanitizedData['lastName'],
        'username': sanitizedData['username'],
        'email': sanitizedData['email'],
        'password': sanitizedData['password'],
      });

      if (response.data['success'] == true) {
        final userData = response.data['data'];
        final user = User.fromJson(userData['user']);
        final tokens = AuthTokens(
          accessToken: userData['token'] ?? userData['accessToken'],
          refreshToken: userData['refreshToken'],
        );
        return AuthResult.success(user, tokens);
      } else {
        return AuthResult.failure(response.data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      if (e is DioException) {
        final code = e.response?.data is Map ? e.response?.data['code'] as String? : null;
        final message = _getLocalizedError(code) ?? 'Registration failed';
        return AuthResult.failure(message);
      }
      return AuthResult.failure('Network error occurred');
    }
  }

  /// Login user with validation
  Future<AuthResult> login(String email, String password) async {
    try {
      // Sanitize and validate inputs
      final sanitizedEmail = _validationService.sanitizeEmail(email);
      final validationResult = _validationService.validateLogin(sanitizedEmail, password);
      
      if (!validationResult.isValid) {
        return AuthResult.failure(validationResult.errors.first);
      }

      final response = await _apiService.client.post('/auth/login', data: {
        'email': sanitizedEmail,
        'password': password,
      });

      if (response.data['success'] == true) {
        final userData = response.data['data'];
        final user = User.fromJson(userData['user']);
        final tokens = AuthTokens(
          accessToken: userData['token'] ?? userData['accessToken'],
          refreshToken: userData['refreshToken'],
        );
        return AuthResult.success(user, tokens);
      } else {
        return AuthResult.failure(response.data['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (e is DioException) {
        final code = e.response?.data is Map ? e.response?.data['code'] as String? : null;
        final message = _getLocalizedError(code) ?? 'Login failed';
        return AuthResult.failure(message);
      }
      return AuthResult.failure('Network error occurred');
    }
  }

  /// Logout user
  Future<void> logout(String? token) async {
    try {
      if (token != null) {
        await _apiService.client.post('/auth/logout');
      }
    } catch (e) {
      // Log error but don't throw - logout should always succeed locally
      debugPrint('Server logout failed: $e');
    }
  }

  /// Verify current user session
  Future<AuthResult> verifySession(String token) async {
    try {
      _apiService.setToken(token);
      final response = await _apiService.client.get('/auth/me');
      
      if (response.data['success'] == true) {
        final user = User.fromJson(response.data['data']);
        return AuthResult.success(user, null);
      } else {
        return AuthResult.failure('Session invalid');
      }
    } catch (e) {
      return AuthResult.failure('Session verification failed');
    }
  }

  /// Refresh authentication tokens
  Future<AuthResult> refreshTokens(String refreshToken) async {
    try {
      final response = await _apiService.client.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response.data['success'] == true) {
        final userData = response.data['data'];
        final user = User.fromJson(userData['user']);
        final tokens = AuthTokens(
          accessToken: userData['token'] ?? userData['accessToken'],
          refreshToken: userData['refreshToken'],
        );
        return AuthResult.success(user, tokens);
      } else {
        return AuthResult.failure('Token refresh failed');
      }
    } catch (e) {
      return AuthResult.failure('Token refresh failed');
    }
  }

  String? _getLocalizedError(String? code) {
    switch (code) {
      case 'INVALID_CREDENTIALS':
        return 'Email ou mot de passe incorrect';
      case 'EMAIL_EXISTS':
        return 'Cet email est déjà utilisé';
      case 'USERNAME_EXISTS':
        return 'Ce nom d\'utilisateur est déjà pris';
      case 'WEAK_PASSWORD':
        return 'Mot de passe trop faible';
      case 'TOKEN_REVOKED':
        return 'Session expirée';
      case 'ACCOUNT_DISABLED':
        return 'Compte désactivé';
      case 'VALIDATION_ERROR':
        return 'Données invalides';
      case 'RATE_LIMITED':
        return 'Trop de tentatives. Réessayez plus tard.';
      default:
        return null;
    }
  }
}

/// Authentication result wrapper
class AuthResult {
  final bool isSuccess;
  final User? user;
  final AuthTokens? tokens;
  final String? error;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.tokens,
    this.error,
  });

  factory AuthResult.success(User user, AuthTokens? tokens) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      tokens: tokens,
    );
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(
      isSuccess: false,
      error: error,
    );
  }
}

/// Authentication tokens data class
class AuthTokens {
  final String accessToken;
  final String? refreshToken;

  AuthTokens({
    required this.accessToken,
    this.refreshToken,
  });
}