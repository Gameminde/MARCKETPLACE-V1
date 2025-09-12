import '../models/user.dart';
import '../providers/auth_provider_secure.dart';

/// Auth API Service for backend communication
class AuthApiService {
  
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    
    return AuthResponse(
      success: true,
      accessToken: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
      tokenExpiry: DateTime.now().add(const Duration(hours: 1)),
      user: User(
        id: '1',
        email: email,
        firstName: 'User',
        lastName: 'Test',
      ),
    );
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    required String role,
  }) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    
    return AuthResponse(
      success: true,
      requiresEmailVerification: true,
    );
  }

  Future<bool> validateSession() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return AuthResponse(
      success: true,
      accessToken: 'new_access_token',
      refreshToken: 'new_refresh_token',
      tokenExpiry: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<User?> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return User(
      id: '1',
      email: 'user@example.com',
      firstName: 'User',
      lastName: 'Test',
    );
  }

  Future<bool> forgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  Future<AuthResponse> socialLogin({
    required String provider,
    required String token,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return AuthResponse(
      success: true,
      accessToken: 'social_access_token',
      refreshToken: 'social_refresh_token',
      tokenExpiry: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  Future<bool> toggleMfa(bool enable) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  Future<AuthResponse> verifyMfa(String mfaCode) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return AuthResponse(
      success: true,
      message: 'MFA verified successfully',
    );
  }

  Future<User?> updateProfile(Map<String, dynamic> updates) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return User(
      id: '1',
      email: updates['email'] ?? 'user@example.com',
      firstName: updates['firstName'] ?? 'User',
      lastName: updates['lastName'] ?? 'Test',
    );
  }
}