import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/environment_secure.dart';
import '../exceptions/api_exceptions.dart';

/// Base API service with common functionality
/// All specialized API services should extend this class
abstract class BaseApiService {
  late final http.Client _client;
  late final String _baseUrl;
  late final Duration _timeout;
  late final int _retryAttempts;

  BaseApiService() {
    _baseUrl = EnvironmentSecure.apiBaseUrl;
    _timeout = EnvironmentSecure.apiTimeout;
    _retryAttempts = EnvironmentSecure.apiRetryAttempts;
    _client = http.Client();
  }

  /// Make HTTP GET request
  Future<T> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return await _makeRequestWithRetry<T>(
      method: 'GET',
      endpoint: endpoint,
      headers: headers,
      queryParameters: queryParameters,
      fromJson: fromJson,
    );
  }

  /// Make HTTP POST request
  Future<T> post<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return await _makeRequestWithRetry<T>(
      method: 'POST',
      endpoint: endpoint,
      headers: headers,
      body: body,
      fromJson: fromJson,
    );
  }

  /// Make HTTP PUT request
  Future<T> put<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return await _makeRequestWithRetry<T>(
      method: 'PUT',
      endpoint: endpoint,
      headers: headers,
      body: body,
      fromJson: fromJson,
    );
  }

  /// Make HTTP DELETE request
  Future<T> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return await _makeRequestWithRetry<T>(
      method: 'DELETE',
      endpoint: endpoint,
      headers: headers,
      queryParameters: queryParameters,
      fromJson: fromJson,
    );
  }

  /// Core request method with retry logic
  Future<T> _makeRequestWithRetry<T>({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    // Check connectivity
    await _checkConnectivity();

    final uri = _buildUri(endpoint, queryParameters);
    final requestHeaders = _buildHeaders(headers);

    Exception? lastException;

    for (int attempt = 0; attempt <= _retryAttempts; attempt++) {
      try {
        final response = await _makeRequest(
          method,
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );

        return _handleResponse<T>(response, fromJson);
      } on SocketException catch (e) {
        lastException =
            NetworkException('No internet connection: ${e.message}');
        if (attempt == _retryAttempts) break;
        await Future.delayed(Duration(milliseconds: 1000 * (attempt + 1)));
      } on HttpException catch (e) {
        lastException = NetworkException('HTTP error: ${e.message}');
        if (attempt == _retryAttempts) break;
        await Future.delayed(Duration(milliseconds: 1000 * (attempt + 1)));
      } on FormatException catch (e) {
        lastException =
            ParsingException('Invalid response format: ${e.message}');
        break; // Don't retry format errors
      } catch (e) {
        lastException = ServerException('Unexpected error: $e');
        if (attempt == _retryAttempts) break;
        await Future.delayed(Duration(milliseconds: 1000 * (attempt + 1)));
      }
    }

    throw lastException ??
        ServerException('Request failed after $_retryAttempts attempts');
  }

  /// Make HTTP request based on method
  Future<http.Response> _makeRequest(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) async {
    switch (method.toUpperCase()) {
      case 'GET':
        return await _client.get(uri, headers: headers).timeout(_timeout);
      case 'POST':
        return await _client
            .post(uri, headers: headers, body: body)
            .timeout(_timeout);
      case 'PUT':
        return await _client
            .put(uri, headers: headers, body: body)
            .timeout(_timeout);
      case 'PATCH':
        return await _client
            .patch(uri, headers: headers, body: body)
            .timeout(_timeout);
      case 'DELETE':
        return await _client
            .delete(uri, headers: headers, body: body)
            .timeout(_timeout);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  /// Build URI with query parameters
  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParameters) {
    final uri = Uri.parse('$_baseUrl$endpoint');

    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(
        queryParameters: queryParameters.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
    }

    return uri;
  }

  /// Build headers with authentication
  Map<String, String> _buildHeaders(Map<String, String>? additionalHeaders) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'MarketplaceApp/1.0.0',
    };

    // Add authentication token if available
    final authToken = _getAuthToken();
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    // Add additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Get authentication token (to be implemented by subclasses)
  String? _getAuthToken() {
    // This should be implemented by subclasses or injected
    return null;
  }

  /// Handle HTTP response
  T _handleResponse<T>(
      http.Response response, T Function(Map<String, dynamic>)? fromJson) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (T == String) {
        return response.body as T;
      }

      if (response.body.isEmpty) {
        throw const ParsingException('Empty response body');
      }

      try {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        if (fromJson != null) {
          return fromJson(jsonData);
        }

        return jsonData as T;
      } catch (e) {
        throw ParsingException('Failed to parse response: $e');
      }
    } else {
      _handleErrorResponse(response);
      // This line should never be reached due to _handleErrorResponse throwing
      throw const ServerException('Unexpected error in response handling');
    }
  }

  /// Handle error responses
  void _handleErrorResponse(http.Response response) {
    String message = 'Request failed';

    try {
      final Map<String, dynamic> errorData = jsonDecode(response.body);
      message = errorData['message'] ?? errorData['error'] ?? message;
    } catch (e) {
      message = response.body.isNotEmpty ? response.body : message;
    }

    switch (response.statusCode) {
      case 400:
        throw ValidationException(message);
      case 401:
        throw UnauthorizedException(message);
      case 403:
        throw ForbiddenException(message);
      case 404:
        throw NotFoundException(message);
      case 409:
        throw ConflictException(message);
      case 422:
        throw ValidationException(message);
      case 429:
        throw RateLimitException(message);
      case 500:
        throw ServerException(message);
      case 502:
      case 503:
      case 504:
        throw const ServerException('Server temporarily unavailable');
      default:
        throw ServerException('HTTP ${response.statusCode}: $message');
    }
  }

  /// Check network connectivity
  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw const NetworkException('No internet connection');
    }
  }

  /// Upload file
  Future<T> uploadFile<T>(
    String endpoint,
    String filePath, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    await _checkConnectivity();

    final uri = Uri.parse('$_baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);

    // Add headers
    final requestHeaders = _buildHeaders(headers);
    request.headers.addAll(requestHeaders);

    // Add file
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    // Add fields
    if (fields != null) {
      request.fields.addAll(fields);
    }

    try {
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      throw ServerException('File upload failed: $e');
    }
  }

  /// Download file
  Future<List<int>> downloadFile(String endpoint) async {
    await _checkConnectivity();

    final uri = Uri.parse('$_baseUrl$endpoint');
    final requestHeaders = _buildHeaders({});

    try {
      final response =
          await _client.get(uri, headers: requestHeaders).timeout(_timeout);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw ServerException('Download failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException('File download failed: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
