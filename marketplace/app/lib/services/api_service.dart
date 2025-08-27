import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// Secure API service with comprehensive error handling and token management
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _initializeDio();
  }

  late final Dio _dio;
  String? _accessToken;
  String? _refreshToken;
  Timer? _tokenRefreshTimer;

  /// Initialize Dio with secure configuration
  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: Duration(milliseconds: ApiConfig.timeout('connect')),
        receiveTimeout: Duration(milliseconds: ApiConfig.timeout('receive')),
        sendTimeout: Duration(milliseconds: ApiConfig.timeout('send')),
        headers: ApiConfig.defaultHeaders,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _setupInterceptors();
    _setupErrorHandling();
  }

  /// Setup request/response interceptors
  void _setupInterceptors() {
    _dio.interceptors.clear();
    
    // Request interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add authentication token
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }

          // Add request ID for tracing
          options.headers['X-Request-ID'] = _generateRequestId();

          // Log request in debug mode
          if (ApiConfig.enableLogging) {
            debugPrint('🚀 API Request: ${options.method} ${options.path}');
            if (options.data != null) {
              debugPrint('📤 Request Data: ${options.data}');
            }
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response in debug mode
          if (ApiConfig.enableLogging) {
            debugPrint('✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
          }

          handler.next(response);
        },
        onError: (error, handler) async {
          // Handle token refresh for 401 errors
          if (error.response?.statusCode == 401 && _refreshToken != null) {
            try {
              final refreshed = await _refreshAccessToken();
              if (refreshed) {
                // Retry original request with new token
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $_accessToken';
                
                try {
                  final response = await _dio.fetch(options);
                  return handler.resolve(response);
                } catch (retryError) {
                  // If retry fails, continue with original error
                }
              }
            } catch (refreshError) {
              debugPrint('Token refresh failed: $refreshError');
            }
          }

          // Log error in debug mode
          if (ApiConfig.enableLogging) {
            debugPrint('❌ API Error: ${error.response?.statusCode} ${error.requestOptions.path}');
            debugPrint('Error message: ${error.message}');
          }

          handler.next(error);
        },
      ),
    );

    // Add logging interceptor in debug mode
    if (ApiConfig.enableDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        error: true,
      ));
    }
  }

  /// Setup comprehensive error handling
  void _setupErrorHandling() {
    // Handle certificate pinning in production
    if (ApiConfig.isProduction && ApiConfig.securityConfig('enable_certificate_pinning')) {
      // Note: Certificate pinning configuration for production
      // (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
      //   client.badCertificateCallback = (cert, host, port) {
      //     // Implement certificate pinning logic here
      //     return false; // Reject invalid certificates
      //   };
      //   return client;
      // };
    }
  }

  /// Set authentication tokens
  void setTokens(String? accessToken, [String? refreshToken]) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    
    // Schedule token refresh if needed
    if (accessToken != null) {
      _scheduleTokenRefresh();
    } else {
      _cancelTokenRefresh();
    }
  }

  /// Set only access token (for backward compatibility)
  void setToken(String? token) {
    setTokens(token);
  }

  /// Get current access token
  String? get accessToken => _accessToken;

  /// Get current refresh token
  String? get refreshToken => _refreshToken;

  /// Clear all tokens
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    _cancelTokenRefresh();
  }

  /// Get Dio client instance
  Dio get client => _dio;

  /// Make authenticated GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Make authenticated POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Make authenticated PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Make authenticated DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Upload file with progress tracking
  Future<Response> uploadFile(
    String path,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    final formData = FormData();
    
    // Add file
    formData.files.add(MapEntry(
      fieldName,
      await MultipartFile.fromFile(file.path),
    ));
    
    // Add additional data
    if (additionalData != null) {
      additionalData.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });
    }

    return await _dio.post(
      path,
      data: formData,
      options: Options(headers: ApiConfig.uploadHeaders),
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
  }

  /// Refresh access token using refresh token
  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await _dio.post(
        ApiConfig.endpoint('auth_refresh'),
        data: {'refreshToken': _refreshToken},
        options: Options(headers: ApiConfig.defaultHeaders),
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        _accessToken = data['token'] ?? data['accessToken'];
        _refreshToken = data['refreshToken'] ?? _refreshToken;
        
        _scheduleTokenRefresh();
        return true;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      clearTokens();
    }

    return false;
  }

  /// Schedule automatic token refresh
  void _scheduleTokenRefresh() {
    _cancelTokenRefresh();
    
    if (_accessToken != null) {
      // Schedule refresh 5 minutes before token expires
      final refreshDelay = Duration(
        seconds: ApiConfig.securityConfig('token_refresh_threshold'),
      );
      
      _tokenRefreshTimer = Timer(refreshDelay, () {
        _refreshAccessToken();
      });
    }
  }

  /// Cancel scheduled token refresh
  void _cancelTokenRefresh() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }

  /// Generate unique request ID for tracing
  String _generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Check if service is healthy
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get API configuration info
  Map<String, dynamic> getConfigInfo() {
    return {
      'baseUrl': ApiConfig.baseUrl,
      'environment': ApiConfig.environment,
      'hasAccessToken': _accessToken != null,
      'hasRefreshToken': _refreshToken != null,
      ...ApiConfig.debugInfo,
    };
  }

  /// Dispose resources
  void dispose() {
    _cancelTokenRefresh();
    _dio.close();
  }
}



