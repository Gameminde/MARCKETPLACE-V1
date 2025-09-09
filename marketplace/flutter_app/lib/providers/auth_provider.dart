import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../core/config/app_constants.dart';

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

/// Enhanced Authentication Provider with JWT support, session management,
/// and comprehensive user state handling
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

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

  // Multi-factor authentication
  bool _isMfaEnabled = false;
  bool _isMfaRequired = false;
  String? _mfaToken;

  // Password policy
  Map<String, bool> _passwordRequirements = {
    'minLength': false,
    'hasUppercase': false,
    'hasLowercase': false,
    'hasDigits': false,
    'hasSpecialChars': false,
  };

  // Getters
  AuthState get authState => _authState;
  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  DateTime? get tokenExpiry => _tokenExpiry;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get rememberUser => _rememberUser;
  bool get isSessionActive => _isSessionActive;
  DateTime? get lastActivity => _lastActivity;
  bool get isMfaEnabled => _isMfaEnabled;
  bool get isMfaRequired => _isMfaRequired;
  String? get mfaToken => _mfaToken;
  Map<String, bool> get passwordRequirements =>
      Map.unmodifiable(_passwordRequirements);

  /// Check if user is authenticated
  bool get isAuthenticated =>
      _authState == AuthState.authenticated && _currentUser != null;

  /// Check if user is admin
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  /// Check if user is seller
  bool get isSeller => _currentUser?.role == UserRole.seller || isAdmin;

  /// Check if user is buyer
  bool get isBuyer => _currentUser?.role == UserRole.buyer || isAdmin;

  /// Check if email is verified
  bool get isEmailVerified => _currentUser?.isEmailVerified ?? false;

  /// Check if token is about to expire
  bool get isTokenNearExpiry {
    if (_tokenExpiry == null) return false;
    final now = DateTime.now();
    final timeUntilExpiry = _tokenExpiry!.difference(now);
    return timeUntilExpiry.inMinutes <= 5; // 5 minutes before expiry
  }

  /// Initialize authentication provider
  Future<void> initialize() async {
    _setLoading(true);

    try {
      await _loadStoredCredentials();
      await _loadUserPreferences();

      if (_accessToken != null) {
        if (await _validateStoredToken()) {
          await _loadUserProfile();
          _setAuthState(AuthState.authenticated);
          _startSessionManagement();
        } else {
          await _attemptTokenRefresh();
        }
      } else {
        _setAuthState(AuthState.unauthenticated);
      }
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with social provider (Google, Apple, Facebook)
  Future<bool> socialLogin(String provider) async {
    _setLoading(true);
    _clearError();

    try {
      // Mock token for social login
      final token = 'mock_${provider}_token';
      final response = await _authService.socialLogin(provider, token);

      if (response.success) {
        await _handleSuccessfulAuth(response);
        return true;
      } else {
        _setError(response.message ?? 'Social login failed');
        return false;
      }
    } catch (e) {
      _setError('Social login error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password,
      {bool rememberMe = false}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(email, password);

      if (response.success) {
        await _handleSuccessfulAuth(response);
        _rememberUser = rememberMe;

        if (rememberMe) {
          await _storeCredentials();
        }

        await _saveUserPreferences();
        return true;
      } else {
        _setError(response.message ?? 'Login failed');

        // Handle specific error cases
        if (response.requiresMfa) {
          _isMfaRequired = true;
          _mfaToken = response.mfaToken;
          _setAuthState(AuthState.unauthenticated);
        } else if (response.requiresEmailVerification) {
          _setAuthState(AuthState.emailVerificationRequired);
        }

        return false;
      }
    } catch (e) {
      _setError('Login error: $e');
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
      // Validate password
      if (!_validatePassword(password)) {
        _setError('Password does not meet requirements');
        return false;
      }

      final response = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        role: role,
      );

      if (response.success) {
        if (response.requiresEmailVerification) {
          _setAuthState(AuthState.emailVerificationRequired);
          _setError('Please check your email to verify your account');
        } else {
          await _handleSuccessfulAuth(response);
        }
        return true;
      } else {
        _setError(response.message ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Registration error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login with MFA code
  Future<bool> loginWithMfa(String mfaCode) async {
    if (_mfaToken == null) {
      _setError('MFA token not available');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.verifyMfa(_mfaToken!, mfaCode);

      if (response.success) {
        await _handleSuccessfulAuth(response);
        _isMfaRequired = false;
        _mfaToken = null;
        return true;
      } else {
        _setError(response.message ?? 'MFA verification failed');
        return false;
      }
    } catch (e) {
      _setError('MFA error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout user
  Future<void> logout({bool clearRememberedUser = false}) async {
    _setLoading(true);

    try {
      // Call logout API if authenticated
      if (_accessToken != null) {
        await _authService.logout(_accessToken!);
      }

      // Clear session
      await _clearSession(clearRememberedCredentials: clearRememberedUser);

      _setAuthState(AuthState.unauthenticated);
    } catch (e) {
      debugPrint('Logout error: $e');
      // Still clear local session even if API call fails
      await _clearSession(clearRememberedCredentials: clearRememberedUser);
      _setAuthState(AuthState.unauthenticated);
    } finally {
      _setLoading(false);
    }
  }

  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.forgotPassword(email);

      if (success) {
        _setAuthState(AuthState.passwordResetRequired);
      } else {
        _setError('Failed to send password reset email');
      }

      return success;
    } catch (e) {
      _setError('Forgot password error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password with token
  Future<bool> resetPassword(String token, String newPassword) async {
    _setLoading(true);
    _clearError();

    try {
      if (!_validatePassword(newPassword)) {
        _setError('Password does not meet requirements');
        return false;
      }

      final success = await _authService.resetPassword(token, newPassword);

      if (success) {
        _setAuthState(AuthState.unauthenticated);
      } else {
        _setError('Failed to reset password');
      }

      return success;
    } catch (e) {
      _setError('Reset password error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Change password for authenticated user
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    if (!isAuthenticated) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      if (!_validatePassword(newPassword)) {
        _setError('New password does not meet requirements');
        return false;
      }

      final success = await _authService.changePassword(
        _accessToken!,
        currentPassword,
        newPassword,
      );

      if (!success) {
        _setError('Failed to change password');
      }

      return success;
    } catch (e) {
      _setError('Change password error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (!isAuthenticated) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final updatedUser =
          await _authService.updateProfile(_accessToken!, updates);

      if (updatedUser != null) {
        _currentUser = updatedUser;
        await _saveUserProfile();
        notifyListeners();
        return true;
      } else {
        _setError('Failed to update profile');
        return false;
      }
    } catch (e) {
      _setError('Update profile error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Enable/disable MFA
  Future<bool> toggleMfa(bool enable) async {
    if (!isAuthenticated) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.toggleMfa(_accessToken!, enable);

      if (success) {
        _isMfaEnabled = enable;
        notifyListeners();
      } else {
        _setError('Failed to ${enable ? 'enable' : 'disable'} MFA');
      }

      return success;
    } catch (e) {
      _setError('MFA toggle error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify email with token
  Future<bool> verifyEmail(String token) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.verifyEmail(token);

      if (success) {
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(isEmailVerified: true);
          await _saveUserProfile();
        }
        _setAuthState(AuthState.authenticated);
        notifyListeners();
      } else {
        _setError('Failed to verify email');
      }

      return success;
    } catch (e) {
      _setError('Email verification error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Send email verification code for registration
  Future<bool> sendEmailVerification(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.sendEmailVerification(email);

      if (!success) {
        _setError('Failed to send verification email');
      }

      return success;
    } catch (e) {
      _setError('Send verification error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify email and complete registration
  Future<bool> verifyEmailAndRegister({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    required String verificationCode,
    bool subscribeToNewsletter = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.verifyEmailAndRegister(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        verificationCode: verificationCode,
        subscribeToNewsletter: subscribeToNewsletter,
      );

      if (response.success) {
        await _handleSuccessfulAuth(response);
        return true;
      } else {
        _setError(response.message ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Registration error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Resend email verification
  Future<bool> resendEmailVerification() async {
    if (_currentUser?.email == null) {
      _setError('No email address available');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final success =
          await _authService.resendEmailVerification(_currentUser!.email);

      if (!success) {
        _setError('Failed to resend verification email');
      }

      return success;
    } catch (e) {
      _setError('Resend verification error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh authentication token
  Future<bool> refreshAuthToken() async {
    if (_refreshToken == null) {
      await logout();
      return false;
    }

    try {
      final response = await _authService.refreshToken(_refreshToken!);

      if (response.success) {
        _accessToken = response.accessToken;
        _refreshToken = response.refreshToken;
        _tokenExpiry = response.tokenExpiry;

        await _storeCredentials();
        _setupTokenRefreshTimer();

        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
      await logout();
      return false;
    }
  }

  /// Check password requirements
  void checkPasswordRequirements(String password) {
    _passwordRequirements = {
      'minLength': password.length >= AppConstants.minPasswordLength,
      'hasUppercase': password.contains(RegExp(r'[A-Z]')),
      'hasLowercase': password.contains(RegExp(r'[a-z]')),
      'hasDigits': password.contains(RegExp(r'[0-9]')),
      'hasSpecialChars': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
    notifyListeners();
  }

  /// Validate password against requirements
  bool _validatePassword(String password) {
    checkPasswordRequirements(password);
    return _passwordRequirements.values.every((requirement) => requirement);
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _authState = AuthState.error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _setAuthState(AuthState state) {
    _authState = state;
    notifyListeners();
  }

  /// Handle successful authentication
  Future<void> _handleSuccessfulAuth(AuthResponse response) async {
    _accessToken = response.accessToken;
    _refreshToken = response.refreshToken;
    _tokenExpiry = response.tokenExpiry;
    _currentUser = response.user;
    _isMfaEnabled = response.user?.isMfaEnabled ?? false;

    await _storeCredentials();
    await _saveUserProfile();

    _setAuthState(AuthState.authenticated);
    _startSessionManagement();
    _setupTokenRefreshTimer();
  }

  /// Session management
  void _startSessionManagement() {
    _isSessionActive = true;
    _lastActivity = DateTime.now();

    // Start session timeout timer
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkSessionTimeout(),
    );
  }

  void _checkSessionTimeout() {
    if (_lastActivity == null) return;

    final now = DateTime.now();
    final timeSinceLastActivity = now.difference(_lastActivity!);

    if (timeSinceLastActivity >= AppConstants.sessionTimeout) {
      logout();
    }
  }

  void updateLastActivity() {
    _lastActivity = DateTime.now();
  }

  /// Token refresh timer
  void _setupTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();

    if (_tokenExpiry != null) {
      final now = DateTime.now();
      final timeUntilRefresh = _tokenExpiry!
          .subtract(AppConstants.tokenRefreshBuffer)
          .difference(now);

      if (timeUntilRefresh.isNegative) {
        // Token already expired, refresh immediately
        refreshAuthToken();
      } else {
        _tokenRefreshTimer = Timer(timeUntilRefresh, () {
          refreshAuthToken();
        });
      }
    }
  }

  /// Storage operations
  Future<void> _storeCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString('access_token', _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString('refresh_token', _refreshToken!);
    }
    if (_tokenExpiry != null) {
      await prefs.setString('token_expiry', _tokenExpiry!.toIso8601String());
    }
  }

  Future<void> _loadStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');

    final expiryString = prefs.getString('token_expiry');
    if (expiryString != null) {
      _tokenExpiry = DateTime.tryParse(expiryString);
    }
  }

  Future<void> _saveUserProfile() async {
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'user_profile', json.encode(_currentUser!.toJson()));
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_profile');

      if (userJson != null) {
        final userData = json.decode(userJson) as Map<String, dynamic>;
        _currentUser = User.fromJson(userData);
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> _saveUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_user', _rememberUser);
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberUser = prefs.getBool('remember_user') ?? false;
  }

  Future<bool> _validateStoredToken() async {
    if (_accessToken == null || _tokenExpiry == null) return false;

    final now = DateTime.now();
    if (_tokenExpiry!.isBefore(now)) {
      return false; // Token expired
    }

    // Optionally validate with server
    try {
      return await _authService.validateToken(_accessToken!);
    } catch (e) {
      return false;
    }
  }

  Future<void> _attemptTokenRefresh() async {
    if (await refreshAuthToken()) {
      await _loadUserProfile();
      _setAuthState(AuthState.authenticated);
      _startSessionManagement();
    } else {
      _setAuthState(AuthState.unauthenticated);
    }
  }

  Future<void> _clearSession({bool clearRememberedCredentials = false}) async {
    // Cancel timers
    _sessionTimer?.cancel();
    _tokenRefreshTimer?.cancel();

    // Clear state
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _isSessionActive = false;
    _lastActivity = null;
    _isMfaRequired = false;
    _mfaToken = null;
    _clearError();

    // Clear secure storage
    final prefsForClear = await SharedPreferences.getInstance();
    await prefsForClear.remove('access_token');
    await prefsForClear.remove('refresh_token');
    await prefsForClear.remove('token_expiry');

    // Clear user profile
    await prefsForClear.remove('user_profile');

    if (clearRememberedCredentials) {
      _rememberUser = false;
      await prefsForClear.remove('remember_user');
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _tokenRefreshTimer?.cancel();
    super.dispose();
  }
}

/// Authentication response model
class AuthResponse {
  final bool success;
  final String? message;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? tokenExpiry;
  final User? user;
  final bool requiresMfa;
  final bool requiresEmailVerification;
  final String? mfaToken;

  AuthResponse({
    required this.success,
    this.message,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiry,
    this.user,
    this.requiresMfa = false,
    this.requiresEmailVerification = false,
    this.mfaToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      tokenExpiry: json['tokenExpiry'] != null
          ? DateTime.tryParse(json['tokenExpiry'] as String)
          : null,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      requiresMfa: json['requiresMfa'] as bool? ?? false,
      requiresEmailVerification:
          json['requiresEmailVerification'] as bool? ?? false,
      mfaToken: json['mfaToken'] as String?,
    );
  }
}
