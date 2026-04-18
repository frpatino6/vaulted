import 'package:flutter_test/flutter_test.dart';

import 'package:vaulted/core/storage/auth_token_store.dart';

// ---------------------------------------------------------------------------
// Tests for AuthTokenStore
//
// AuthTokenStore is a singleton that lives entirely in memory.
// There is no external dependency to mock — tests operate directly on the
// singleton instance, resetting state with clear() in setUp/tearDown.
// ---------------------------------------------------------------------------

void main() {
  late AuthTokenStore store;

  setUp(() {
    store = AuthTokenStore.instance;
    // Guarantee a clean slate for every test.
    store.clear();
  });

  tearDown(() {
    store.clear();
  });

  // -------------------------------------------------------------------------
  // Singleton identity
  // -------------------------------------------------------------------------
  group('AuthTokenStore — singleton', () {
    test('AuthTokenStore.instance always returns the same object', () {
      final a = AuthTokenStore.instance;
      final b = AuthTokenStore.instance;
      expect(identical(a, b), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Token (access token)
  // -------------------------------------------------------------------------
  group('AuthTokenStore — token', () {
    test('getToken() returns null before any token is set', () {
      expect(store.getToken(), isNull);
    });

    test('setToken() stores the token and getToken() retrieves it', () {
      store.setToken('my.access.jwt');
      expect(store.getToken(), 'my.access.jwt');
    });

    test('setToken() replaces a previously stored token', () {
      store.setToken('first.jwt');
      store.setToken('second.jwt');
      expect(store.getToken(), 'second.jwt');
    });

    test('clear() sets the token back to null', () {
      store.setToken('some.jwt');
      store.clear();
      expect(store.getToken(), isNull);
    });

    test('setToken() with empty string stores an empty string', () {
      store.setToken('');
      expect(store.getToken(), '');
    });
  });

  // -------------------------------------------------------------------------
  // MFA pending flag
  // -------------------------------------------------------------------------
  group('AuthTokenStore — MFA pending', () {
    test('isMfaPending is false by default', () {
      expect(store.isMfaPending, isFalse);
    });

    test('setMfaPending(true) sets the flag to true', () {
      store.setMfaPending(true);
      expect(store.isMfaPending, isTrue);
    });

    test('setMfaPending(false) sets the flag to false', () {
      store.setMfaPending(true);
      store.setMfaPending(false);
      expect(store.isMfaPending, isFalse);
    });

    test('clear() resets mfaPending to false', () {
      store.setMfaPending(true);
      store.clear();
      expect(store.isMfaPending, isFalse);
    });

    test('isMfaPending is independent from the stored token', () {
      store.setToken('token.jwt');
      store.setMfaPending(true);

      // Token is set, MFA is pending — both should be consistent.
      expect(store.getToken(), 'token.jwt');
      expect(store.isMfaPending, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // clear()
  // -------------------------------------------------------------------------
  group('AuthTokenStore.clear', () {
    test('clear() resets both token and mfaPending in a single call', () {
      store.setToken('tok.jwt');
      store.setMfaPending(true);

      store.clear();

      expect(store.getToken(), isNull);
      expect(store.isMfaPending, isFalse);
    });

    test('clear() is safe to call when store is already empty', () {
      // Should not throw.
      expect(() => store.clear(), returnsNormally);
    });

    test('clear() can be called multiple times without side effects', () {
      store.setToken('tok.jwt');
      store.clear();
      store.clear();

      expect(store.getToken(), isNull);
      expect(store.isMfaPending, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // State isolation between tests (regression guard)
  // -------------------------------------------------------------------------
  group('AuthTokenStore — state isolation', () {
    test('state set in one test does not leak into the next (token)', () {
      // This test relies on setUp calling clear() before each test.
      expect(store.getToken(), isNull,
          reason: 'setUp should have cleared the singleton');
    });

    test('state set in one test does not leak into the next (mfaPending)', () {
      expect(store.isMfaPending, isFalse,
          reason: 'setUp should have cleared the singleton');
    });
  });
}
