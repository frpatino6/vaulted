import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/auth_token_store.dart';
import '../data/auth_repository_provider.dart';
import '../domain/auth_state.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  AuthState build() => const AuthState.initial();

  Future<void> login(String email, String password) async {
    state = const AsyncData(AuthState.loading());
    try {
      final result = await ref.read(authRepositoryProvider).login(email, password);
      final mfaRequired = result['mfaRequired'] as bool? ?? false;

      if (mfaRequired) {
        AuthTokenStore.instance.setMfaPending(true);
        state = const AsyncData(AuthState.mfaRequired());
      } else {
        AuthTokenStore.instance.setMfaPending(false);
        state = const AsyncData(AuthState.authenticated());
      }
    } catch (e) {
      state = AsyncData(AuthState.error(_mapError(e)));
    }
  }

  Future<void> verifyMfa(String code) async {
    state = const AsyncData(AuthState.loading());
    try {
      await ref.read(authRepositoryProvider).verifyMfa(code);
      AuthTokenStore.instance.setMfaPending(false);
      state = const AsyncData(AuthState.authenticated());
    } catch (e) {
      state = AsyncData(AuthState.error(_mapMfaError(e)));
    }
  }

  Future<void> logout() async {
    state = const AsyncData(AuthState.loading());
    try {
      await ref.read(authRepositoryProvider).logout();
    } finally {
      state = const AsyncData(AuthState.initial());
    }
  }

  String _mapError(Object e) {
    if (e is DioException) {
      // No connection to server
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Cannot reach server. Is the backend running on port 3000?';
      }

      final statusCode = e.response?.statusCode;
      if (statusCode == 401) return 'Invalid email or password.';
      if (statusCode == 429) return 'Too many attempts. Wait a moment and try again.';

      // Show the actual API error message if available
      final data = e.response?.data;
      if (data is Map) {
        final apiMsg = data['error']?['message'];
        if (apiMsg is String && apiMsg.isNotEmpty) return apiMsg;
        if (apiMsg is List) return apiMsg.join(', ');
      }
    }
    return 'Something went wrong. Please try again.';
  }

  String _mapMfaError(Object e) {
    if (e is DioException) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) return 'Invalid or expired verification code.';
      if (statusCode == 429) return 'Too many attempts. Wait a moment and try again.';
    }
    return 'Invalid verification code. Please try again.';
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
