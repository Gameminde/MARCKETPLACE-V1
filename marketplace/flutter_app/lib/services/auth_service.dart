import 'dart:math';

import '../models/user.dart';
import '../providers/auth_provider.dart' show AuthResponse;

/// Mock authentication service for development
/// In production, this would connect to your actual backend API
class AuthService {
  // Mock delay to simulate network requests
  static const Duration _mockDelay = Duration(milliseconds: 800);
  
  // Mock storage for users (in production, this would be a real database)
  static final Map<String, Map<String, dynamic>> _mockUsers = {};
  static final Map<String, String> _mockVerificationCodes = {};
  static final Set<String> _mockVerifiedEmails = {};
  
  /// Login with email and password
  Future<AuthResponse> login(String email, String password) async {
    await Future.delayed(_mockDelay);
    
    // Mock validation
    if (email.isEmpty || password.isEmpty) {
      return AuthResponse(
        success: false,
        message: 'Email and password are required',
      );
    }
    
    // Check if user exists
    final userData = _mockUsers[email.toLowerCase()];
    if (userData == null) {
      return AuthResponse(
        success: false,
        message: 'User not found',
      );
    }
    
    // Check password (in production, this would be properly hashed)
    if (userData['password'] != password) {
      return AuthResponse(
        success: false,
        message: 'Invalid password',
      );
    }
    
    // Check email verification
    if (!_mockVerifiedEmails.contains(email.toLowerCase())) {
      return AuthResponse(
        success: false,
        message: 'Email not verified',
        requiresEmailVerification: true,
      );
    }
    
    // Generate mock tokens
    final accessToken = _generateMockToken();
    final refreshToken = _generateMockToken();
    final tokenExpiry = DateTime.now().add(const Duration(hours: 1));
    
    // Create user object
    final user = User.fromJson(userData);
    
    return AuthResponse(
      success: true,
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenExpiry: tokenExpiry,
      user: user,
    );
  }
  
  /// Register new user
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    UserRole role = UserRole.buyer,
  }) async {
    await Future.delayed(_mockDelay);
    
    final emailLower = email.toLowerCase();
    
    // Check if user already exists
    if (_mockUsers.containsKey(emailLower)) {
      return AuthResponse(
        success: false,
        message: 'User already exists',
      );
    }
    
    // Create user data
    final userData = {
      'id': _generateUserId(),
      'email': emailLower,
      'password': password, // In production, this would be hashed
      'firstName': firstName,
      'lastName': lastName,
      'phone': phoneNumber,
      'role': role.name,
      'isEmailVerified': false,
      'isMfaEnabled': false,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    _mockUsers[emailLower] = userData;
    
    // Send verification email (mock)
    await sendEmailVerification(emailLower);
    
    return AuthResponse(
      success: true,
      message: 'Registration successful. Please verify your email.',
      requiresEmailVerification: true,
    );
  }
  
  /// Send email verification code
  Future<bool> sendEmailVerification(String email) async {
    await Future.delayed(_mockDelay);
    
    final emailLower = email.toLowerCase();
    
    // Generate 6-digit verification code
    final verificationCode = _generateVerificationCode();
    _mockVerificationCodes[emailLower] = verificationCode;
    
    // In production, you would send this via email
    print('📧 Verification code for $email: $verificationCode');
    
    return true;
  }
  
  /// Verify email and complete registration
  Future<AuthResponse> verifyEmailAndRegister({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    required String verificationCode,
    bool subscribeToNewsletter = false,
  }) async {
    await Future.delayed(_mockDelay);
    
    final emailLower = email.toLowerCase();
    
    // Check verification code
    final storedCode = _mockVerificationCodes[emailLower];
    if (storedCode == null || storedCode != verificationCode) {
      return AuthResponse(
        success: false,
        message: 'Invalid or expired verification code',
      );
    }
    
    // Create user data
    final userData = {
      'id': _generateUserId(),
      'email': emailLower,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'role': UserRole.buyer.name,
      'isEmailVerified': true,
      'isMfaEnabled': false,
      'subscribeToNewsletter': subscribeToNewsletter,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    _mockUsers[emailLower] = userData;
    _mockVerifiedEmails.add(emailLower);
    _mockVerificationCodes.remove(emailLower);
    
    // Generate tokens and return authenticated response
    final accessToken = _generateMockToken();
    final refreshToken = _generateMockToken();
    final tokenExpiry = DateTime.now().add(const Duration(hours: 1));
    
    final user = User.fromJson(userData);
    
    return AuthResponse(
      success: true,
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenExpiry: tokenExpiry,
      user: user,
      message: 'Registration completed successfully',
    );
  }
  
  /// Verify MFA code
  Future<AuthResponse> verifyMfa(String mfaToken, String mfaCode) async {
    await Future.delayed(_mockDelay);
    
    // Mock MFA verification
    if (mfaCode == '123456') {
      final accessToken = _generateMockToken();
      final refreshToken = _generateMockToken();
      final tokenExpiry = DateTime.now().add(const Duration(hours: 1));
      
      return AuthResponse(
        success: true,
        accessToken: accessToken,
        refreshToken: refreshToken,
        tokenExpiry: tokenExpiry,
      );
    }
    
    return AuthResponse(
      success: false,
      message: 'Invalid MFA code',
    );
  }
  
  /// Social login (Google, Apple, Facebook)
  Future<AuthResponse> socialLogin(String provider, String token) async {
    await Future.delayed(_mockDelay);
    
    // Mock social login success
    final email = 'user@$provider.com';
    final userData = {
      'id': _generateUserId(),
      'email': email,
      'firstName': 'Social',
      'lastName': 'User',
      'role': UserRole.buyer.name,
      'isEmailVerified': true,
      'isMfaEnabled': false,
      'provider': provider,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    _mockUsers[email] = userData;
    _mockVerifiedEmails.add(email);
    
    final accessToken = _generateMockToken();
    final refreshToken = _generateMockToken();
    final tokenExpiry = DateTime.now().add(const Duration(hours: 1));
    
    final user = User.fromJson(userData);
    
    return AuthResponse(
      success: true,
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenExpiry: tokenExpiry,
      user: user,
    );
  }
  
  /// Refresh authentication token
  Future<AuthResponse> refreshToken(String refreshToken) async {
    await Future.delayed(_mockDelay);
    
    // In production, validate the refresh token
    final newAccessToken = _generateMockToken();
    final newRefreshToken = _generateMockToken();
    final tokenExpiry = DateTime.now().add(const Duration(hours: 1));
    
    return AuthResponse(
      success: true,
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      tokenExpiry: tokenExpiry,
    );
  }
  
  /// Logout
  Future<bool> logout(String accessToken) async {
    await Future.delayed(_mockDelay);
    // In production, invalidate the token on the server
    return true;
  }
  
  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    await Future.delayed(_mockDelay);
    
    final emailLower = email.toLowerCase();
    if (!_mockUsers.containsKey(emailLower)) {
      return false;
    }
    
    // In production, send password reset email
    print('📧 Password reset email sent to $email');
    return true;
  }
  
  /// Reset password
  Future<bool> resetPassword(String token, String newPassword) async {
    await Future.delayed(_mockDelay);
    
    // In production, validate token and update password
    return true;
  }
  
  /// Change password
  Future<bool> changePassword(String accessToken, String currentPassword, String newPassword) async {
    await Future.delayed(_mockDelay);
    
    // In production, validate current password and update
    return true;
  }
  
  /// Update user profile
  Future<User?> updateProfile(String accessToken, Map<String, dynamic> updates) async {
    await Future.delayed(_mockDelay);
    
    // In production, update user in database
    // For now, return a mock updated user
    return null;
  }
  
  /// Verify email with token
  Future<bool> verifyEmail(String token) async {
    await Future.delayed(_mockDelay);
    
    // In production, validate token and mark email as verified
    return true;
  }
  
  /// Resend email verification
  Future<bool> resendEmailVerification(String email) async {
    return await sendEmailVerification(email);
  }
  
  /// Toggle MFA
  Future<bool> toggleMfa(String accessToken, bool enable) async {
    await Future.delayed(_mockDelay);
    
    // In production, update MFA settings in database
    return true;
  }
  
  /// Validate token
  Future<bool> validateToken(String accessToken) async {
    await Future.delayed(_mockDelay);
    
    // In production, validate token with server
    return accessToken.isNotEmpty;
  }
  
  // Helper methods
  String _generateMockToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(32, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
  
  String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
  
  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
}