import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:marketplace_app/services/auth_service.dart';
import 'package:marketplace_app/services/api_service.dart';
import 'package:marketplace_app/services/validation_service.dart';
import 'package:marketplace_app/models/user.dart';

// Generate mocks
@GenerateMocks([ApiService, ValidationService, Dio])
import 'auth_service_test.mocks.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockApiService mockApiService;
    late MockValidationService mockValidationService;
    late MockDio mockDio;

    setUp(() {
      mockApiService = MockApiService();
      mockValidationService = MockValidationService();
      mockDio = MockDio();
      
      when(mockApiService.client).thenReturn(mockDio);
      
      authService = AuthService(
        apiService: mockApiService,
        validationService: mockValidationService,
      );
    });

    group('register', () {
      test('should register user successfully with valid data', () async {
        // Arrange
        const userData = {
          'firstName': 'John',
          'lastName': 'Doe',
          'username': 'johndoe',
          'email': 'john@example.com',
          'password': 'SecurePass123!',
        };

        final sanitizedData = {
          'firstName': 'John',
          'lastName': 'Doe',
          'username': 'johndoe',
          'email': 'john@example.com',
          'password': 'SecurePass123!',
        };

        final validationResult = ValidationResult(true, []);
        
        final responseData = {
          'success': true,
          'data': {
            'user': {
              'id': '123',
              'email': 'john@example.com',
              'firstName': 'John',
              'lastName': 'Doe',
              'username': 'johndoe',
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
              'role': 'user',
              'status': 'active',
              'preferences': {},
              'stats': {},
            },
            'token': 'access_token_123',
            'refreshToken': 'refresh_token_123',
          }
        };

        when(mockValidationService.sanitizeRegistrationData(userData))
            .thenReturn(sanitizedData);
        when(mockValidationService.validateRegistration(sanitizedData))
            .thenReturn(validationResult);
        when(mockDio.post('/auth/register', data: sanitizedData))
            .thenAnswer((_) async => Response(
                  data: responseData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/auth/register'),
                ));

        // Act
        final result = await authService.register(
          firstName: 'John',
          lastName: 'Doe',
          username: 'johndoe',
          email: 'john@example.com',
          password: 'SecurePass123!',
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.user, isNotNull);
        expect(result.user!.email, 'john@example.com');
        expect(result.tokens, isNotNull);
        expect(result.tokens!.accessToken, 'access_token_123');
      });

      test('should fail registration with validation errors', () async {
        // Arrange
        const userData = {
          'firstName': '',
          'lastName': 'Doe',
          'username': 'johndoe',
          'email': 'invalid-email',
          'password': 'weak',
        };

        final sanitizedData = userData;
        final validationResult = ValidationResult(false, ['First name is required', 'Invalid email']);

        when(mockValidationService.sanitizeRegistrationData(userData))
            .thenReturn(sanitizedData);
        when(mockValidationService.validateRegistration(sanitizedData))
            .thenReturn(validationResult);

        // Act
        final result = await authService.register(
          firstName: '',
          lastName: 'Doe',
          username: 'johndoe',
          email: 'invalid-email',
          password: 'weak',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, 'First name is required');
      });

      test('should handle server errors gracefully', () async {
        // Arrange
        const userData = {
          'firstName': 'John',
          'lastName': 'Doe',
          'username': 'johndoe',
          'email': 'john@example.com',
          'password': 'SecurePass123!',
        };

        final sanitizedData = userData;
        final validationResult = ValidationResult(true, []);

        when(mockValidationService.sanitizeRegistrationData(userData))
            .thenReturn(sanitizedData);
        when(mockValidationService.validateRegistration(sanitizedData))
            .thenReturn(validationResult);
        when(mockDio.post('/auth/register', data: sanitizedData))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/auth/register'),
              response: Response(
                data: {'code': 'EMAIL_EXISTS', 'message': 'Email already exists'},
                statusCode: 409,
                requestOptions: RequestOptions(path: '/auth/register'),
              ),
            ));

        // Act
        final result = await authService.register(
          firstName: 'John',
          lastName: 'Doe',
          username: 'johndoe',
          email: 'john@example.com',
          password: 'SecurePass123!',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, 'Cet email est déjà utilisé');
      });
    });

    group('login', () {
      test('should login user successfully with valid credentials', () async {
        // Arrange
        const email = 'john@example.com';
        const password = 'SecurePass123!';
        const sanitizedEmail = 'john@example.com';

        final validationResult = ValidationResult(true, []);
        
        final responseData = {
          'success': true,
          'data': {
            'user': {
              'id': '123',
              'email': 'john@example.com',
              'firstName': 'John',
              'lastName': 'Doe',
              'username': 'johndoe',
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
              'role': 'user',
              'status': 'active',
              'preferences': {},
              'stats': {},
            },
            'token': 'access_token_123',
            'refreshToken': 'refresh_token_123',
          }
        };

        when(mockValidationService.sanitizeEmail(email))
            .thenReturn(sanitizedEmail);
        when(mockValidationService.validateLogin(sanitizedEmail, password))
            .thenReturn(validationResult);
        when(mockDio.post('/auth/login', data: {
          'email': sanitizedEmail,
          'password': password,
        })).thenAnswer((_) async => Response(
              data: responseData,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/auth/login'),
            ));

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result.isSuccess, true);
        expect(result.user, isNotNull);
        expect(result.user!.email, 'john@example.com');
        expect(result.tokens, isNotNull);
        expect(result.tokens!.accessToken, 'access_token_123');
      });

      test('should fail login with invalid credentials', () async {
        // Arrange
        const email = 'john@example.com';
        const password = 'wrongpassword';
        const sanitizedEmail = 'john@example.com';

        final validationResult = ValidationResult(true, []);

        when(mockValidationService.sanitizeEmail(email))
            .thenReturn(sanitizedEmail);
        when(mockValidationService.validateLogin(sanitizedEmail, password))
            .thenReturn(validationResult);
        when(mockDio.post('/auth/login', data: {
          'email': sanitizedEmail,
          'password': password,
        })).thenThrow(DioException(
              requestOptions: RequestOptions(path: '/auth/login'),
              response: Response(
                data: {'code': 'INVALID_CREDENTIALS', 'message': 'Invalid credentials'},
                statusCode: 401,
                requestOptions: RequestOptions(path: '/auth/login'),
              ),
            ));

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, 'Email ou mot de passe incorrect');
      });
    });

    group('logout', () {
      test('should logout successfully', () async {
        // Arrange
        const token = 'access_token_123';
        
        when(mockDio.post('/auth/logout'))
            .thenAnswer((_) async => Response(
                  data: {'success': true},
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/auth/logout'),
                ));

        // Act & Assert
        expect(() => authService.logout(token), returnsNormally);
      });

      test('should handle logout server errors gracefully', () async {
        // Arrange
        const token = 'access_token_123';
        
        when(mockDio.post('/auth/logout'))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/auth/logout'),
            ));

        // Act & Assert
        expect(() => authService.logout(token), returnsNormally);
      });
    });

    group('verifySession', () {
      test('should verify valid session successfully', () async {
        // Arrange
        const token = 'valid_token_123';
        
        final responseData = {
          'success': true,
          'data': {
            'id': '123',
            'email': 'john@example.com',
            'firstName': 'John',
            'lastName': 'Doe',
            'username': 'johndoe',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'role': 'user',
            'status': 'active',
            'preferences': {},
            'stats': {},
          }
        };

        when(mockApiService.setToken(token)).thenReturn(null);
        when(mockDio.get('/auth/me'))
            .thenAnswer((_) async => Response(
                  data: responseData,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/auth/me'),
                ));

        // Act
        final result = await authService.verifySession(token);

        // Assert
        expect(result.isSuccess, true);
        expect(result.user, isNotNull);
        expect(result.user!.email, 'john@example.com');
        verify(mockApiService.setToken(token)).called(1);
      });

      test('should fail verification with invalid token', () async {
        // Arrange
        const token = 'invalid_token';
        
        when(mockApiService.setToken(token)).thenReturn(null);
        when(mockDio.get('/auth/me'))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/auth/me'),
              response: Response(
                statusCode: 401,
                requestOptions: RequestOptions(path: '/auth/me'),
              ),
            ));

        // Act
        final result = await authService.verifySession(token);

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, 'Session verification failed');
      });
    });
  });
}