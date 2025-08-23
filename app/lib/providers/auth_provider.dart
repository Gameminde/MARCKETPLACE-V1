import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import 'package:dio/dio.dart';

class User {
  final String id;
  final String email;
  const User({required this.id, required this.email});
}

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;
  User? _currentUser;
  User? get currentUser => _currentUser;
  String? _token;

  final _storage = const FlutterSecureStorage();
  final _api = ApiService();

  Future<bool> register(String email, String password) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final res = await _api.client.post('/auth/register', data: {
        'email': email,
        'password': password,
      });
      final data = res.data['data'];
      _token = data['accessToken'];
      await _storage.write(key: 'accessToken', value: _token);
      _api.setToken(_token);
      _currentUser = User(id: data['user']['id'], email: data['user']['email']);
      _isAuthenticated = true;
      return true;
    } catch (e) {
      _error = 'Registration failed';
      return false;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final res = await _api.client.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = res.data['data'];
      _token = data['accessToken'];
      await _storage.write(key: 'accessToken', value: _token);
      _api.setToken(_token);
      _currentUser = User(id: data['user']['id'], email: data['user']['email']);
      _isAuthenticated = true;
      return true;
    } catch (e) {
      if (e is DioException) {
        final code = e.response?.data is Map ? e.response?.data['code'] as String? : null;
        _error = _getLocalizedError(code) ?? 'Erreur de connexion';
      } else {
        _error = 'Erreur de connexion';
      }
      return false;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _api.client.post('/auth/logout');
    } catch (_) {}
    _isAuthenticated = false;
    _currentUser = null;
    _token = null;
    await _storage.delete(key: 'accessToken');
    _api.setToken(null);
    notifyListeners();
  }

  Future<bool> checkAuthStatus() async {
    _isLoading = true; notifyListeners();
    try {
      final stored = await _storage.read(key: 'accessToken');
      if (stored != null) {
        _token = stored; _api.setToken(_token);
        // Optionally ping /auth/me
        final res = await _api.client.get('/auth/me');
        final data = res.data['data'];
        _currentUser = User(id: data['_id'] ?? data['id'] ?? '', email: data['email']);
        _isAuthenticated = true;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  String? _getLocalizedError(String? code) {
    switch (code) {
      case 'INVALID_CREDENTIALS':
        return 'Email ou mot de passe incorrect';
      case 'EMAIL_EXISTS':
        return 'Cet email est déjà utilisé';
      case 'WEAK_PASSWORD':
        return 'Mot de passe trop faible';
      case 'TOKEN_REVOKED':
        return 'Session expirée';
      default:
        return null;
    }
  }
}


