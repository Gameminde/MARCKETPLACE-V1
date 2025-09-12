import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/providers/auth_provider_secure.dart';
import '../../lib/models/user.dart';

void main() {
  group('AuthProvider Tests', () {
    late AuthProvider authProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      authProvider = AuthProvider();
    });

    test('should initialize with no authenticated user', () {
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isLoading, isFalse);
    });

    group('Login Tests', () {
      test('should login with valid credentials', () async {
        authProvider.setLoading(true);
        expect(authProvider.isLoading, isTrue);
        
        final result = await authProvider.login(
          email: 'test@example.com',
          password: 'password123',
        );
        
        expect(result.isSuccess, isTrue);
        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.currentUser, isNotNull);
        expect(authProvider.currentUser?.email, equals('test@example.com'));
        expect(authProvider.isLoading, isFalse);
      });

      test('should fail login with invalid email', () async {
        final result = await authProvider.login(
          email: 'invalid-email',
          password: 'password123',
        );
        
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Invalid email format'));
        expect(authProvider.isAuthenticated, isFalse);
      });

      test('should fail login with empty password', () async {
        final result = await authProvider.login(
          email: 'test@example.com',
          password: '',
        );
        
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Password cannot be empty'));
        expect(authProvider.isAuthenticated, isFalse);
      });

      test('should fail login with incorrect credentials', () async {
        final result = await authProvider.login(
          email: 'test@example.com',
          password: 'wrongpassword',
        );
        
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Invalid credentials'));
        expect(authProvider.isAuthenticated, isFalse);
      });
    });

    group('Registration Tests', () {
      test('should register with valid data', () async {
        final result = await authProvider.register(
          email: 'newuser@example.com',
          password: 'password123',
          firstName: 'John',
          lastName: 'Doe',
        );
        
        expect(result.isSuccess, isTrue);
        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.currentUser?.email, equals('newuser@example.com'));
        expect(authProvider.currentUser?.firstName, equals('John'));
        expect(authProvider.currentUser?.lastName, equals('Doe'));
      });

      test('should fail registration with existing email', () async {
        // First registration
        await authProvider.register(
          email: 'existing@example.com',
          password: 'password123',
          firstName: 'John',
          lastName: 'Doe',
        );
        
        // Logout to test registration again
        await authProvider.logout();
        
        // Try to register with same email
        final result = await authProvider.register(
          email: 'existing@example.com',
          password: 'password456',
          firstName: 'Jane',
          lastName: 'Smith',
        );
        
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Email already exists'));
      });

      test('should fail registration with weak password', () async {
        final result = await authProvider.register(
          email: 'test@example.com',
          password: '123',
          firstName: 'John',
          lastName: 'Doe',
        );
        
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Password must be at least 6 characters'));
      });

      test('should fail registration with invalid email', () async {
        final result = await authProvider.register(
          email: 'invalid-email',
          password: 'password123',
          firstName: 'John',
          lastName: 'Doe',
        );
        
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Invalid email format'));
      });

      test('should fail registration with empty required fields', () async {
        final result = await authProvider.register(
          email: 'test@example.com',
          password: 'password123',
          firstName: '',
          lastName: 'Doe',
        );
        
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('First name cannot be empty'));
      });
    });

    group('Logout Tests', () {
      test('should logout successfully', () async {
        // First login
        await authProvider.login(
          email: 'test@example.com',
          password: 'password123',
        );
        
        expect(authProvider.isAuthenticated, isTrue);
        
        // Then logout
        await authProvider.logout();
        
        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.currentUser, isNull);
      });
    });

    group('Password Reset Tests', () {
      test('should send password reset email', () async {
        final result = await authProvider.resetPassword('test@example.com');
        
        expect(result.isSuccess, isTrue);
        expect(result.message, contains('Password reset email sent'));
      });

      test('should fail password reset with invalid email', () async {
        final result = await authProvider.resetPassword('invalid-email');
        
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Invalid email format'));
      });

      test('should fail password reset with non-existent email', () async {
        final result = await authProvider.resetPassword('nonexistent@example.com');
        
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Email not found'));
      });
    });

    group('Email Verification Tests', () {
      test('should send verification email', () async {
        // Login first
        await authProvider.login(
          email: 'test@example.com',
          password: 'password123',
        );
        
        final result = await authProvider.sendVerificationEmail();
        
        expect(result.isSuccess, isTrue);
        expect(result.message, contains('Verification email sent'));
      });

      test('should verify email with valid token', () async {
        // Login first
        await authProvider.login(
          email: 'test@example.com',
          password: 'password123',
        );
        
        final result = await authProvider.verifyEmail('valid_token_123');
        
        expect(result.isSuccess, isTrue);
        expect(authProvider.currentUser?.isEmailVerified, isTrue);
      });

      test('should fail email verification with invalid token', () async {
        // Login first
        await authProvider.login(
          email: 'test@example.com',
          password: 'password123',
        );
        
        final result = await authProvider.verifyEmail('invalid_token');
        
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Invalid verification token'));
      });
    });

    group('Profile Update Tests', () {
      test('should update user profile', () async {
        // Login first
        await authProvider.login(
          email: 'test@example.com',
          password: 'password123',
        );
        
        final result = await authProvider.updateProfile(
          firstName: 'Updated',
          lastName: 'Name',
          phoneNumber: '+1234567890',
        );
        
        expect(result.isSuccess, isTrue);
        expect(authProvider.currentUser?.firstName, equals('Updated'));
        expect(authProvider.currentUser?.lastName, equals('Name'));
        expect(authProvider.currentUser?.phoneNumber, equals('+1234567890'));
      });

      test('should change password', () async {
        // Login first
        await authProvider.login(
          email: 'test@example.com',
          password: 'password123',
        );
        
        final result = await authProvider.changePassword(
          currentPassword: 'password123',
          newPassword: 'newpassword123',
        );
        
        expect(result.isSuccess, isTrue);
      });

      test('should fail password change with wrong current password', () async {
        // Login first
        await authProvider.login(
          email: 'test@example.com',
          password: 'password123',
        );
        
        final result = await authProvider.changePassword(
          currentPassword: 'wrongpassword',
          newPassword: 'newpassword123',
        );
        
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Current password is incorrect'));
      });
    });

    group('Social Login Tests', () {
      test('should login with Google', () async {
        final result = await authProvider.loginWithGoogle();
        
        expect(result.isSuccess, isTrue);
        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.currentUser?.provider, equals('google'));
      });

      test('should login with Apple', () async {
        final result = await authProvider.loginWithApple();
        
        expect(result.isSuccess, isTrue);
        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.currentUser?.provider, equals('apple'));
      });

      test('should login with Facebook', () async {
        final result = await authProvider.loginWithFacebook();
        
        expect(result.isSuccess, isTrue);
        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.currentUser?.provider, equals('facebook'));
      });
    });

    group('Session Management Tests', () {
      test('should check if user session is valid', () async {
        // Login first
        await authProvider.login(
          email: 'test@example.com',
          password: 'password123',
        );
        
        final isValid = await authProvider.isSessionValid();
        expect(isValid, isTrue);
      });

      test('should refresh token when expired', () async {
        // Login first
        await authProvider.login(
          email: 'test@example.com',
          password: 'password123',
        );
        
        final result = await authProvider.refreshToken();
        expect(result.isSuccess, isTrue);
      });

      test('should auto-login on app startup', () async {
        // Simulate stored credentials
        SharedPreferences.setMockInitialValues({
          'auth_token': 'stored_token',
          'refresh_token': 'stored_refresh_token',
          'user_data': '{"id":"1","email":"stored@example.com"}',
        });
        
        final newAuthProvider = AuthProvider();
        await newAuthProvider.initializeAuth();
        
        expect(newAuthProvider.isAuthenticated, isTrue);
      });
    });

    group('Validation Tests', () {
      test('should validate email format', () {
        expect(authProvider.validateEmail('test@example.com'), isTrue);
        expect(authProvider.validateEmail('invalid-email'), isFalse);
        expect(authProvider.validateEmail(''), isFalse);
        expect(authProvider.validateEmail('test@'), isFalse);
        expect(authProvider.validateEmail('@example.com'), isFalse);
      });

      test('should validate password strength', () {
        expect(authProvider.validatePassword('password123'), isTrue);
        expect(authProvider.validatePassword('123'), isFalse);
        expect(authProvider.validatePassword(''), isFalse);
        expect(authProvider.validatePassword('pass'), isFalse);
      });

      test('should validate phone number format', () {
        expect(authProvider.validatePhoneNumber('+1234567890'), isTrue);
        expect(authProvider.validatePhoneNumber('1234567890'), isTrue);
        expect(authProvider.validatePhoneNumber('123'), isFalse);
        expect(authProvider.validatePhoneNumber('abc'), isFalse);
      });
    });

    group('Error Handling Tests', () {
      test('should handle network errors gracefully', () async {
        // Simulate network error
        authProvider.simulateNetworkError = true;
        
        final result = await authProvider.login(
          email: 'test@example.com',
          password: 'password123',
        );
        
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Network error'));
      });

      test('should notify listeners on state changes', () {
        var notificationCount = 0;
        authProvider.addListener(() {
          notificationCount++;
        });
        
        authProvider.setLoading(true);
        authProvider.setLoading(false);
        
        expect(notificationCount, equals(2));
      });
    });
  });
}