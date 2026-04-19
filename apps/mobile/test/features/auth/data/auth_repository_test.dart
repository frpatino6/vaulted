import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/core/storage/auth_token_store.dart';
import 'package:vaulted/core/storage/secure_storage.dart';
import 'package:vaulted/features/auth/data/auth_remote_data_source.dart';
import 'package:vaulted/features/auth/data/auth_repository.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockSecureStorage extends Mock implements SecureStorage {}

// ---------------------------------------------------------------------------
// Helpers — build the record types that AuthRemoteDataSource returns
// ---------------------------------------------------------------------------

typedef _LoginResult = ({Map<String, dynamic> data, String? setCookie});

_LoginResult _loginResult({
  required Map<String, dynamic> data,
  String? setCookie,
}) =>
    (data: data, setCookie: setCookie);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockAuthRemoteDataSource mockRemote;
  late MockSecureStorage mockSecureStorage;
  late AuthTokenStore tokenStore;
  late AuthRepository repository;

  setUp(() {
    mockRemote = MockAuthRemoteDataSource();
    mockSecureStorage = MockSecureStorage();
    // Use a fresh instance for each test to avoid cross-test contamination.
    // AuthTokenStore is a singleton, so we call clear() instead.
    tokenStore = AuthTokenStore.instance;
    tokenStore.clear();

    repository = AuthRepository(
      remote: mockRemote,
      secureStorage: mockSecureStorage,
      tokenStore: tokenStore,
    );
  });

  // Stub SecureStorage to do nothing by default (most tests don't care).
  void stubSecureStorageSave() {
    when(
      () => mockSecureStorage.saveRefreshToken(any()),
    ).thenAnswer((_) async {});
  }

  void stubSecureStorageDelete() {
    when(
      () => mockSecureStorage.deleteRefreshToken(),
    ).thenAnswer((_) async {});
  }

  // -------------------------------------------------------------------------
  // login()
  // -------------------------------------------------------------------------
  group('AuthRepository.login', () {
    test('stores accessToken in AuthTokenStore on success (no MFA)', () async {
      stubSecureStorageSave();

      when(() => mockRemote.login(any(), any())).thenAnswer(
        (_) async => _loginResult(
          data: {'accessToken': 'access.jwt', 'mfaRequired': false},
          setCookie: 'refresh_token=refresh123; Path=/; HttpOnly',
        ),
      );

      final result = await repository.login('owner@test.com', 'Test1234!');

      expect(result['accessToken'], 'access.jwt');
      expect(result['mfaRequired'], false);
      expect(tokenStore.getToken(), 'access.jwt');
    });

    test('saves refresh token to SecureStorage when Set-Cookie present', () async {
      stubSecureStorageSave();

      when(() => mockRemote.login(any(), any())).thenAnswer(
        (_) async => _loginResult(
          data: {'accessToken': 'access.jwt', 'mfaRequired': false},
          setCookie: 'refresh_token=myRefreshValue; Path=/; HttpOnly',
        ),
      );

      await repository.login('owner@test.com', 'Test1234!');

      verify(() => mockSecureStorage.saveRefreshToken('myRefreshValue')).called(1);
    });

    test('does not call saveRefreshToken when Set-Cookie is absent', () async {
      when(() => mockRemote.login(any(), any())).thenAnswer(
        (_) async => _loginResult(
          data: {'accessToken': 'access.jwt', 'mfaRequired': false},
          setCookie: null,
        ),
      );

      await repository.login('owner@test.com', 'Test1234!');

      verifyNever(() => mockSecureStorage.saveRefreshToken(any()));
    });

    test('returns mfaRequired=true when server responds with MFA flag', () async {
      stubSecureStorageSave();

      when(() => mockRemote.login(any(), any())).thenAnswer(
        (_) async => _loginResult(
          data: {'accessToken': 'temp.jwt', 'mfaRequired': true},
          setCookie: 'refresh_token=mfa_refresh; Path=/; HttpOnly',
        ),
      );

      final result = await repository.login('owner@test.com', 'Test1234!');

      expect(result['mfaRequired'], true);
      expect(tokenStore.getToken(), 'temp.jwt');
    });

    test('throws Exception when accessToken is missing from response', () async {
      when(() => mockRemote.login(any(), any())).thenAnswer(
        (_) async => _loginResult(
          data: {'mfaRequired': false}, // no accessToken key
        ),
      );

      expect(
        () => repository.login('owner@test.com', 'Test1234!'),
        throwsA(isA<Exception>()),
      );
    });

    test('propagates exceptions from remote data source', () async {
      when(() => mockRemote.login(any(), any())).thenThrow(Exception('network failure'));

      expect(
        () => repository.login('owner@test.com', 'Test1234!'),
        throwsA(isA<Exception>()),
      );
    });

    test('parses refresh_token from a multi-directive Set-Cookie string', () async {
      stubSecureStorageSave();

      when(() => mockRemote.login(any(), any())).thenAnswer(
        (_) async => _loginResult(
          data: {'accessToken': 'access.jwt', 'mfaRequired': false},
          setCookie: 'refresh_token=tokenValue; Path=/; HttpOnly; SameSite=Strict',
        ),
      );

      await repository.login('owner@test.com', 'Test1234!');

      verify(() => mockSecureStorage.saveRefreshToken('tokenValue')).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // verifyMfa()
  // -------------------------------------------------------------------------
  group('AuthRepository.verifyMfa', () {
    test('stores final accessToken in AuthTokenStore on success', () async {
      stubSecureStorageSave();

      when(() => mockRemote.verifyMfa(any())).thenAnswer(
        (_) async => _loginResult(
          data: {'accessToken': 'final.jwt'},
          setCookie: 'refresh_token=full_refresh; Path=/; HttpOnly',
        ),
      );

      final result = await repository.verifyMfa('123456');

      expect(result['accessToken'], 'final.jwt');
      expect(tokenStore.getToken(), 'final.jwt');
    });

    test('saves new refresh token from MFA Set-Cookie', () async {
      stubSecureStorageSave();

      when(() => mockRemote.verifyMfa(any())).thenAnswer(
        (_) async => _loginResult(
          data: {'accessToken': 'final.jwt'},
          setCookie: 'refresh_token=full_refresh; Path=/; HttpOnly',
        ),
      );

      await repository.verifyMfa('123456');

      verify(() => mockSecureStorage.saveRefreshToken('full_refresh')).called(1);
    });

    test('throws Exception when accessToken is missing', () async {
      when(() => mockRemote.verifyMfa(any())).thenAnswer(
        (_) async => _loginResult(
          data: {'someOtherField': 'value'},
        ),
      );

      expect(
        () => repository.verifyMfa('123456'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws Exception when accessToken is empty string', () async {
      when(() => mockRemote.verifyMfa(any())).thenAnswer(
        (_) async => _loginResult(
          data: {'accessToken': ''},
        ),
      );

      expect(
        () => repository.verifyMfa('123456'),
        throwsA(isA<Exception>()),
      );
    });

    test('propagates exceptions from remote data source', () async {
      when(() => mockRemote.verifyMfa(any())).thenThrow(Exception('invalid code'));

      expect(
        () => repository.verifyMfa('000000'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // logout()
  // -------------------------------------------------------------------------
  group('AuthRepository.logout', () {
    test('clears token store and calls deleteRefreshToken on success', () async {
      stubSecureStorageDelete();
      tokenStore.setToken('some.jwt');

      when(() => mockRemote.logout()).thenAnswer((_) async {});

      await repository.logout();

      expect(tokenStore.getToken(), isNull);
      verify(() => mockSecureStorage.deleteRefreshToken()).called(1);
    });

    test('still clears token store (via finally) even when remote logout throws', () async {
      stubSecureStorageDelete();
      tokenStore.setToken('some.jwt');

      when(() => mockRemote.logout()).thenThrow(Exception('server unavailable'));

      // AuthRepository.logout uses try/finally — the finally always runs and
      // clears local state, but the exception is still rethrown to the caller.
      await expectLater(
        () => repository.logout(),
        throwsA(isA<Exception>()),
      );

      expect(tokenStore.getToken(), isNull);
      verify(() => mockSecureStorage.deleteRefreshToken()).called(1);
    });

    test('calls remote.logout once', () async {
      stubSecureStorageDelete();
      when(() => mockRemote.logout()).thenAnswer((_) async {});

      await repository.logout();

      verify(() => mockRemote.logout()).called(1);
    });
  });
}
