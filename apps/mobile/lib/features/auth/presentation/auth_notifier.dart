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
      state = AsyncData(AuthState.error(_mapError(e)));
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
    final msg = e.toString().toLowerCase();
    if (msg.contains('401') || msg.contains('invalid credentials') || msg.contains('unauthorized')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('mfa') || msg.contains('code') || msg.contains('totp')) {
      return 'Invalid verification code. Please try again.';
    }
    if (msg.contains('network') || msg.contains('socket') || msg.contains('connection') ||
        msg.contains('connection refused') || msg.contains('failed host lookup') ||
        msg.contains('connection reset')) {
      return 'Cannot reach API. Is the backend running on port 3000?';
    }
    return 'Something went wrong. Please try again.';
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
