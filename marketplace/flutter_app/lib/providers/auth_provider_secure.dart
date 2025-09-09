import 'package:flutter/foundation.dart';
import 'dart:async';

import '../models/user.dart';
import '../services/auth_api_service.dart';
import '../core/services/secure_storage_service.dart';

/// Authentication states
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  sessionExpired,
  emailVerificationRequired,
  passwordResetRequired,
}

/// User roles
enum UserRole {
  buyer,
  seller,
  admin,
  moderator,
}

/// Secure Authentication Provider with proper security practices
class AuthProvider extends ChangeNotifier {
  final AuthApiService _authService;
  final SecureStorageService _storageService;

  // Authentication state
  AuthState _authState = AuthState.initial;
  User? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;
  String? _errorMessage;
  bool _isLoading = false;
  bool _rememberUser = false;

  // Session management
  bool _isSessionActive = false;
  DateTime? _lastActivity;
  Timer? _sessionTimer;
  Timer? _tokenRefreshTimer;

  // MFA state
  bool _isMfaEnabled = false;
  bool _isMfaVerified = false;
  String? _mfaSecret;

  AuthProvider({
    required AuthApiService authService,
    required SecureStorageService storageService,
  })  : _authService = authService,
        _storageService = storageService {
    _initializeAuth();
  }

  // Getters
  AuthState get authState => _authState;
  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  DateTime? get tokenExpiry => _tokenExpiry;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authState == AuthState.authenticated;
  bool get isSessionActive => _isSessionActive;
  bool get isMfaEnabled => _isMfaEnabled;
  bool get isMfaVerified => _isMfaVerified;
  bool get rememberUser => _rememberUser;

  /// Initialize authentication state
  Future<void> _initializeAuth() async {
    _setLoading(true);

    try {
      // Check if user is already authenticated
      final token = await _storageService.getAuthToken();
      final refreshToken = await _storageService.getRefreshToken();
      final tokenExpiry = await _storageService.getTokenExpiry();

      if (token != null && refreshToken != null && tokenExpiry != null) {
        // Check if token is still valid
        if (tokenExpiry.isAfter(DateTime.now())) {
          _accessToken = token;
          _refreshToken = refreshToken;
          _tokenExpiry = tokenExpiry;

          // Validate session with server
          final isValid = await _authService.validateSession();
          if (isValid) {
            await _loadUserProfile();
            _setAuthState(AuthState.authenticated);
            _startSessionManagement();
          } else {
            await _clearAuthData();
            _setAuthState(AuthState.unauthenticated);
          }
        } else {
          // Try to refresh token
          await _refreshAuthToken();
        }
      } else {
        _setAuthState(AuthState.unauthenticated);
      }
    } catch (e) {
      _setError('Failed to initialize authentication: ${e.toString()}');
      _setAuthState(AuthState.unauthenticated);
    } finally {
      _setLoading(false);
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (response.success && response.accessToken != null) {
        await _handleSuccessfulAuth(response);
        return true;
      } else {
        _setError(response.message ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    UserRole role = UserRole.buyer,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        role: role.name,
      );

      if (response.success) {
        if (response.requiresEmailVerification == true) {
          _setAuthState(AuthState.emailVerificationRequired);
          return true;
        } else if (response.accessToken != null) {
          await _handleSuccessfulAuth(response);
          return true;
        }
      }

      _setError(response.message ?? 'Registration failed');
      return false;
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout user
  Future<void> logout() async {
    _setLoading(true);

    try {
      if (_accessToken != null) {
        await _authService.logout();
      }
    } catch (e) {
      // Log error but continue with logout
      debugPrint('Logout error: $e');
    } finally {
      await _clearAuthData();
      _setAuthState(AuthState.unauthenticated);
      _setLoading(false);
    }
  }

  /// Refresh authentication token
  Future<bool> _refreshAuthToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await _authService.refreshToken(_refreshToken!);

      if (response.success && response.accessToken != null) {
        await _handleSuccessfulAuth(response);
        return true;
      } else {
        await _clearAuthData();
        _setAuthState(AuthState.sessionExpired);
        return false;
      }
    } catch (e) {
      await _clearAuthData();
      _setAuthState(AuthState.sessionExpired);
      return false;
    }
  }

  /// Handle successful authentication
  Future<void> _handleSuccessfulAuth(AuthResponse response) async {
    _accessToken = response.accessToken;
    _refreshToken = response.refreshToken;
    _tokenExpiry = response.tokenExpiry;
    _currentUser = response.user;

    // Save to secure storage
    if (_accessToken != null) {
      await _storageService.saveAuthToken(_accessToken!);
    }
    if (_refreshToken != null) {
      await _storageService.saveRefreshToken(_refreshToken!);
    }
    if (_tokenExpiry != null) {
      await _storageService.saveTokenExpiry(_tokenExpiry!);
    }
    if (_currentUser != null) {
      await _storageService.saveUserId(_currentUser!.id);
      await _storageService.saveUserEmail(_currentUser!.email);
    }

    _setAuthState(AuthState.authenticated);
    _startSessionManagement();
  }

  /// Load user profile
  Future<void> _loadUserProfile() async {
    try {
      final user = await _authService.getUserProfile();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
    }
  }

  /// Clear authentication data
  Future<void> _clearAuthData() async {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _currentUser = null;
    _isSessionActive = false;
    _isMfaVerified = false;

    // Clear secure storage
    await _storageService.clearAuthData();

    // Cancel timers
    _sessionTimer?.cancel();
    _tokenRefreshTimer?.cancel();
  }

  /// Start session management
  void _startSessionManagement() {
    _isSessionActive = true;
    _lastActivity = DateTime.now();

    // Start token refresh timer
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _refreshAuthToken(),
    );

    // Start session timeout timer
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkSessionTimeout(),
    );
  }

  /// Check session timeout
  void _checkSessionTimeout() {
    if (_lastActivity != null) {
      final timeSinceLastActivity = DateTime.now().difference(_lastActivity!);
      if (timeSinceLastActivity.inMinutes > 30) {
        // Session timeout
        logout();
      }
    }
  }

  /// Update last activity
  void updateLastActivity() {
    _lastActivity = DateTime.now();
  }

  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.forgotPassword(email);
      return success;
    } catch (e) {
      _setError('Failed to send password reset email: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password
  Future<bool> resetPassword(String token, String newPassword) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      return success;
    } catch (e) {
      _setError('Failed to reset password: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Change password
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return success;
    } catch (e) {
      _setError('Failed to change password: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Social login
  Future<bool> socialLogin(String provider, String token) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.socialLogin(
        provider: provider,
        token: token,
      );

      if (response.success && response.accessToken != null) {
        await _handleSuccessfulAuth(response);
        return true;
      } else {
        _setError(response.message ?? 'Social login failed');
        return false;
      }
    } catch (e) {
      _setError('Social login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle MFA
  Future<bool> toggleMfa(bool enable) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.toggleMfa(enable);
      if (success) {
        _isMfaEnabled = enable;
        await _storageService.saveMfaEnabled(enable);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Failed to toggle MFA: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify MFA
  Future<bool> verifyMfa(String mfaCode) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.verifyMfa(mfaCode);

      if (response.success) {
        _isMfaVerified = true;
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'MFA verification failed');
        return false;
      }
    } catch (e) {
      _setError('MFA verification failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.updateProfile(updates);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set authentication state
  void _setAuthState(AuthState state) {
    _authState = state;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    _setAuthState(AuthState.error);
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Set remember user preference
  void setRememberUser(bool remember) {
    _rememberUser = remember;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _tokenRefreshTimer?.cancel();
    super.dispose();
  }
}

/// Auth response model
class AuthResponse {
  final bool success;
  final String? message;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? tokenExpiry;
  final User? user;
  final bool? requiresEmailVerification;

  AuthResponse({
    required this.success,
    this.message,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiry,
    this.user,
    this.requiresEmailVerification,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'],
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      tokenExpiry: json['tokenExpiry'] != null
          ? DateTime.tryParse(json['tokenExpiry'])
          : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      requiresEmailVerification: json['requiresEmailVerification'],
    );
  }
}
