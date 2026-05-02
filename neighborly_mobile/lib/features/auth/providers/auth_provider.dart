import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neighborly/core/network/dio_client.dart';
import 'package:neighborly/core/network/api_constants.dart';
import 'package:neighborly/features/auth/models/user.dart';

/// Auth state: Loading | Authenticated | Unauthenticated | Error
sealed class AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  Authenticated(this.user);
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

/// Auth state notifier — manages login, register, logout, and session restore.
class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;
  final TokenStorage _storage;

  AuthNotifier(this._dio, this._storage) : super(AuthLoading()) {
    _restoreSession();
  }

  /// Try to restore session from stored token.
  Future<void> _restoreSession() async {
    final hasToken = await hasValidToken(_storage);
    if (!hasToken) {
      state = Unauthenticated();
      return;
    }
    try {
      final response = await _dio.get(ApiConstants.me);
      state = Authenticated(User.fromJson(response.data));
    } on DioException {
      state = Unauthenticated();
    }
  }

  /// Login with email, password, and community_id.
  Future<void> login(String email, String password, String communityId) async {
    state = AuthLoading();
    try {
      final response = await _dio.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
        'community_id': communityId,
      });
      await saveTokens(_storage, response.data);

      // Fetch user profile
      final meResponse = await _dio.get(ApiConstants.me);
      state = Authenticated(User.fromJson(meResponse.data));
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Login failed';
      state = AuthError(detail.toString());
    }
  }

  /// Register a new user.
  Future<void> register({
    required String communityId,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    state = AuthLoading();
    try {
      await _dio.post(ApiConstants.register, data: {
        'community_id': communityId,
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        if (phone != null) 'phone': phone,
      });

      // After registration, auto-login.
      await login(email, password, communityId);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? 'Registration failed';
      state = AuthError(detail.toString());
    }
  }

  /// Logout.
  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } catch (_) {
      // Best-effort server-side logout
    }
    await clearTokens(_storage);
    state = Unauthenticated();
  }
}

/// Global auth state provider.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  );
});

/// Convenience: get current user or null.
final currentUserProvider = Provider<User?>((ref) {
  final auth = ref.watch(authProvider);
  return auth is Authenticated ? auth.user : null;
});
