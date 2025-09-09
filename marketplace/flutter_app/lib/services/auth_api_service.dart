import '../core/services/base_api_service.dart';
import '../core/exceptions/api_exceptions.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart' show AuthResponse;

/// Specialized API service for authentication operations
class AuthApiService extends BaseApiService {
  @override
  String? _getAuthToken() {
    // This would be injected or retrieved from a service
    // For now, we'll return null and handle it in the provider
    return null;
  }

  /// Login with email and password
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      return AuthResponse.fromJson(response);
    } on ValidationException catch (e) {
      return AuthResponse(
        success: false,
        message: e.message,
      );
    } on UnauthorizedException {
      return AuthResponse(
        success: false,
        message: 'Invalid email or password',
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  /// Register new user
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String role = 'buyer',
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/auth/register',
        body: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
          'role': role,
        },
      );

      return AuthResponse.fromJson(response);
    } on ValidationException catch (e) {
      return AuthResponse(
        success: false,
        message: e.message,
      );
    } on ConflictException {
      return AuthResponse(
        success: false,
        message: 'User already exists',
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Registration failed: ${e.toString()}',
      );
    }
  }

  /// Refresh authentication token
  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/auth/refresh',
        body: {
          'refreshToken': refreshToken,
        },
      );

      return AuthResponse.fromJson(response);
    } on UnauthorizedException {
      return AuthResponse(
        success: false,
        message: 'Invalid refresh token',
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Token refresh failed: ${e.toString()}',
      );
    }
  }

  /// Logout user
  Future<bool> logout() async {
    try {
      await post('/auth/logout');
      return true;
    } catch (e) {
      // Even if logout fails on server, we should clear local data
      return false;
    }
  }

  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    try {
      await post('/auth/forgot-password', body: {'email': email});
      return true;
    } on NotFoundException {
      return false; // Don't reveal if email exists
    } catch (e) {
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await post('/auth/reset-password', body: {
        'token': token,
        'newPassword': newPassword,
      });
      return true;
    } on ValidationException {
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await post('/auth/change-password', body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return true;
    } on ValidationException {
      return false;
    } on UnauthorizedException {
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Verify email
  Future<bool> verifyEmail(String token) async {
    try {
      await post('/auth/verify-email', body: {'token': token});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Resend email verification
  Future<bool> resendEmailVerification(String email) async {
    try {
      await post('/auth/resend-verification', body: {'email': email});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Social login (Google, Apple, Facebook)
  Future<AuthResponse> socialLogin({
    required String provider,
    required String token,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/auth/social-login',
        body: {
          'provider': provider,
          'token': token,
        },
      );

      return AuthResponse.fromJson(response);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Social login failed: ${e.toString()}',
      );
    }
  }

  /// Enable/disable MFA
  Future<bool> toggleMfa(bool enable) async {
    try {
      await post('/auth/toggle-mfa', body: {'enable': enable});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verify MFA code
  Future<AuthResponse> verifyMfa(String mfaCode) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/auth/verify-mfa',
        body: {'mfaCode': mfaCode},
      );

      return AuthResponse.fromJson(response);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'MFA verification failed: ${e.toString()}',
      );
    }
  }

  /// Get user profile
  Future<User?> getUserProfile() async {
    try {
      final response = await get<Map<String, dynamic>>('/user/profile');
      return User.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update user profile
  Future<User?> updateProfile(Map<String, dynamic> updates) async {
    try {
      final response = await put<Map<String, dynamic>>(
        '/user/profile',
        body: updates,
      );
      return User.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Delete user account
  Future<bool> deleteAccount(String password) async {
    try {
      await delete('/user/account', queryParameters: {'password': password});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate current session
  Future<bool> validateSession() async {
    try {
      await get('/auth/validate');
      return true;
    } catch (e) {
      return false;
    }
  }
}
