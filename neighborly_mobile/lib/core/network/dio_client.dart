import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'api_constants.dart';

/// Secure token storage keys.
const _kAccessToken = 'access_token';
const _kRefreshToken = 'refresh_token';

/// Global Dio client provider with JWT interceptor.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  dio.interceptors.add(AuthInterceptor(dio, ref));
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (obj) => print('[DIO] $obj'),
  ));

  return dio;
});

/// Secure storage provider — uses SharedPreferences on web, FlutterSecureStorage on mobile.
final secureStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

/// Platform-agnostic token storage.
/// FlutterSecureStorage doesn't work reliably on web, so we use SharedPreferences there.
class TokenStorage {
  Future<String?> read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      const storage = FlutterSecureStorage();
      return storage.read(key: key);
    }
  }

  Future<void> write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      const storage = FlutterSecureStorage();
      await storage.write(key: key, value: value);
    }
  }

  Future<void> delete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      const storage = FlutterSecureStorage();
      await storage.delete(key: key);
    }
  }
}

/// JWT Auth interceptor that:
/// 1. Injects access_token on every request.
/// 2. On 401, attempts silent refresh using refresh_token.
/// 3. Retries the original request with the new token.
class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final Ref _ref;
  bool _isRefreshing = false;

  AuthInterceptor(this._dio, this._ref);

  TokenStorage get _storage => _ref.read(secureStorageProvider);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(_kAccessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _storage.read(_kRefreshToken);
        if (refreshToken == null) {
          _isRefreshing = false;
          return handler.next(err);
        }

        // Create a fresh Dio instance to avoid interceptor loop.
        final freshDio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {'Content-Type': 'application/json'},
        ));

        final response = await freshDio.post(
          ApiConstants.refresh,
          data: {'refresh_token': refreshToken},
        );

        final newAccess = response.data['access_token'];
        final newRefresh = response.data['refresh_token'];

        await _storage.write(_kAccessToken, newAccess);
        await _storage.write(_kRefreshToken, newRefresh);

        // Retry the original request with the new token.
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccess';

        final retryResponse = await _dio.fetch(opts);
        _isRefreshing = false;
        return handler.resolve(retryResponse);
      } on DioException {
        _isRefreshing = false;
        // Refresh also failed — clear tokens
        await _storage.delete(_kAccessToken);
        await _storage.delete(_kRefreshToken);
        return handler.next(err);
      }
    }
    handler.next(err);
  }
}

// ─── Token Helpers ────────────────────────────────────────────

Future<void> saveTokens(TokenStorage storage, Map<String, dynamic> data) async {
  await storage.write(_kAccessToken, data['access_token']);
  await storage.write(_kRefreshToken, data['refresh_token']);
}

Future<void> clearTokens(TokenStorage storage) async {
  await storage.delete(_kAccessToken);
  await storage.delete(_kRefreshToken);
}

Future<bool> hasValidToken(TokenStorage storage) async {
  final token = await storage.read(_kAccessToken);
  return token != null && token.isNotEmpty;
}
