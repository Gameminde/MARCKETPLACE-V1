import 'dart:async';
import 'package:dio/dio.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000/api/v1'),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: { 'Content-Type': 'application/json' },
    ),
  );

  String? _accessToken;
  void setToken(String? token) { _accessToken = token; }

  void setupInterceptors({FutureOr<String?> Function()? onRefreshToken}) {
    _dio.interceptors.clear();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode == 401 && onRefreshToken != null) {
            try {
              final newToken = await onRefreshToken();
              if (newToken != null) {
                _accessToken = newToken;
                final opts = e.requestOptions;
                opts.headers['Authorization'] = 'Bearer $_accessToken';
                final cloneReq = await _dio.fetch(opts);
                return handler.resolve(cloneReq);
              }
            } catch (_) {}
          }
          handler.next(e);
        },
      ),
    );
  }

  Dio get client => _dio;
}



