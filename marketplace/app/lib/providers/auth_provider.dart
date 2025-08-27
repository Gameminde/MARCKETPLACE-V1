import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';
import '../services/api_service.dart';

/// Authentication provider following SOLID principles
/// Single Responsibility: Manages authentication state only
class AuthProvider extends ChangeNotifier {
  // Private state variables
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  User? _user;
  String? _token;
  String? _refreshToken;

  // Services (Dependency Injection)
  final AuthService _authService;
  final SecureStorageService _storageService;
  final ApiService _apiService;

  // Public getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;
  String? get token => _token;

  // Constructor with dependency injection
  AuthProvider({
    AuthService? authService,
    SecureStorageService? storageService,
    ApiService? apiService,
  }) : _authService = authService ?? AuthService(),
        _storageService = storageService ?? SecureStorageService(),
        _apiService = apiService ?? ApiService();

  /// Register new user with comprehensive validation
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    await _setLoading(true);

    try {
      final result = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        password: password,
      );

      if (result.isSuccess) {
        await _handleAuthSuccess(result.user!, result.tokens);
        return true;
      } else {
        _setError(result.error!);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      return false;
    } finally {
      await _setLoading(false);
    }
  }

  /// Login user with validation
  Future<bool> login(String email, String password) async {
    await _setLoading(true);

    try {
      final result = await _authService.login(email, password);

      if (result.isSuccess) {
        await _handleAuthSuccess(result.user!, result.tokens);
        return true;
      } else {
        _setError(result.error!);
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      await _setLoading(false);
    }
  }

  /// Logout user and clear all data
  Future<void> logout() async {
    await _setLoading(true);

    try {
      // Logout from server
      await _authService.logout(_token);
      
      // Clear local state and storage
      await _clearAuthState();
    } catch (e) {
      debugPrint('Logout error: $e');
      // Always clear local state even if server logout fails
      await _clearAuthState();
    } finally {
      await _setLoading(false);
    }
  }

  /// Check authentication status on app start
  Future<bool> checkAuthStatus() async {
    await _setLoading(true);

    try {
      // Check if we have stored credentials
      final isStored = await _storageService.isAuthenticated();
      if (!isStored) return false;

      // Get stored token and user data
      final storedToken = await _storageService.getAuthToken();
      final storedUserData = await _storageService.getUserData();

      if (storedToken != null && storedUserData != null) {
        // Restore user from storage
        _user = User.fromJson(storedUserData);
        _token = storedToken;
        _apiService.setToken(_token);
        _isAuthenticated = true;

        // Verify token with server
        final result = await _authService.verifySession(storedToken);
        if (result.isSuccess) {
          // Update user data if server returned newer data
          if (result.user != null) {
            _user = result.user;
            await _storageService.storeUserData(_user!.toJson());
          }
          return true;
        } else {
          // Token is invalid, clear stored data
          await _clearAuthState();
          return false;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Auth status check failed: $e');
      await _clearAuthState();
      return false;
    } finally {
      await _setLoading(false);
    }
  }

  /// Refresh authentication tokens
  Future<bool> refreshAuthToken() async {
    if (_refreshToken == null) return false;

    try {
      final result = await _authService.refreshTokens(_refreshToken!);
      
      if (result.isSuccess) {
        await _handleAuthSuccess(result.user!, result.tokens);
        return true;
      } else {
        // Refresh failed, logout user
        await logout();
        return false;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      await logout();
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    if (!_isAuthenticated) return false;

    await _setLoading(true);

    try {
      final response = await _apiService.client.put('/auth/profile', data: profileData);

      if (response.data['success'] == true) {
        _user = User.fromJson(response.data['data']);
        await _storageService.storeUserData(_user!.toJson());
        notifyListeners();
        return true;
      } else {
        _setError('Failed to update profile');
        return false;
      }
    } catch (e) {
      _setError('Profile update failed: ${e.toString()}');
      return false;
    } finally {
      await _setLoading(false);
    }
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Private helper methods
  Future<void> _handleAuthSuccess(User user, AuthTokens? tokens) async {
    _user = user;
    _isAuthenticated = true;
    _error = null;

    if (tokens != null) {
      _token = tokens.accessToken;
      _refreshToken = tokens.refreshToken;

      // Store tokens securely
      await _storageService.storeAuthToken(tokens.accessToken);
      if (tokens.refreshToken != null) {
        await _storageService.storeRefreshToken(tokens.refreshToken!);
      }
    }

    // Store user data
    await _storageService.storeUserData(user.toJson());
    
    // Set API token
    _apiService.setToken(_token);
    
    notifyListeners();
  }

  Future<void> _clearAuthState() async {
    _isAuthenticated = false;
    _user = null;
    _token = null;
    _refreshToken = null;
    _error = null;

    // Clear secure storage
    await _storageService.clearAuthData();
    
    // Clear API token
    _apiService.setToken(null);
    
    notifyListeners();
  }

  Future<void> _setLoading(bool loading) async {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
}