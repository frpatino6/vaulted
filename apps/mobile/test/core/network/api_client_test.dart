import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vaulted/core/config/app_config.dart';
import 'package:vaulted/core/network/api_client.dart';
import 'package:vaulted/core/storage/auth_token_store.dart';
import 'package:vaulted/core/storage/secure_storage.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

/// Returns canned [ResponseBody] sequences so Dio never hits the network.
class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._onFetch);

  final ResponseBody Function(RequestOptions options) _onFetch;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _onFetch(options);
  }
}

ResponseBody _jsonResponse(int statusCode, Object json) {
  return ResponseBody.fromString(
    jsonEncode(json),
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

void main() {
  late MockSecureStorage mockSecure;
  late AuthTokenStore tokenStore;
  var authFailureCalls = 0;
  var mfaRequiredCalls = 0;
  String? lastRefreshedToken;

  setUp(() {
    mockSecure = MockSecureStorage();
    tokenStore = AuthTokenStore.instance;
    tokenStore.clear();
    authFailureCalls = 0;
    mfaRequiredCalls = 0;
    lastRefreshedToken = null;

    when(() => mockSecure.getRefreshToken()).thenAnswer((_) async => 'refresh-secret');
    when(() => mockSecure.deleteRefreshToken()).thenAnswer((_) async {});
  });

  tearDown(() {
    tokenStore.clear();
  });

  group('ApiClient', () {
    test('dio uses AppConfig base URL and JSON headers', () {
      final client = ApiClient(
        secureStorage: mockSecure,
        tokenStore: tokenStore,
      );

      expect(client.dio.options.baseUrl, AppConfig.apiBaseUrl);
      expect(client.dio.options.headers['Content-Type'], 'application/json');
      expect(client.dio.options.headers['Accept'], 'application/json');
    });

    test('onRequest attaches Bearer when token is set', () async {
      tokenStore.setToken('access.one');

      late RequestOptions seen;
      final client = ApiClient(
        secureStorage: mockSecure,
        tokenStore: tokenStore,
      );
      client.dio.httpClientAdapter = _FakeHttpClientAdapter((options) {
        seen = options;
        return _jsonResponse(200, <String, dynamic>{});
      });

      await client.dio.get<Object>('ping');

      expect(seen.headers['Authorization'], 'Bearer access.one');
    });

    test('onRequest omits Authorization when token is absent', () async {
      late RequestOptions seen;
      final client = ApiClient(
        secureStorage: mockSecure,
        tokenStore: tokenStore,
      );
      client.dio.httpClientAdapter = _FakeHttpClientAdapter((options) {
        seen = options;
        return _jsonResponse(200, <String, dynamic>{});
      });

      await client.dio.get<Object>('ping');

      expect(seen.headers['Authorization'], isNull);
    });

    test('401 on non-auth path refreshes token and retries original request', () async {
      tokenStore.setToken('old.jwt');
      var getCount = 0;

      final client = ApiClient(
        secureStorage: mockSecure,
        tokenStore: tokenStore,
        onTokenRefreshed: (t) => lastRefreshedToken = t,
      );

      client.dio.httpClientAdapter = _FakeHttpClientAdapter((options) {
        final path = options.uri.path;
        if (options.method == 'GET' && path.endsWith('/items')) {
          getCount++;
          if (getCount == 1) {
            return _jsonResponse(401, <String, dynamic>{'message': 'Unauthorized'});
          }
          return _jsonResponse(200, <String, dynamic>{'ok': true});
        }
        if (options.method == 'POST' && path.contains('auth/refresh')) {
          expect(options.headers['Cookie'], contains('refresh_token=refresh-secret'));
          return _jsonResponse(200, <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{'accessToken': 'new.jwt'},
          });
        }
        fail('Unexpected ${options.method} $path');
      });

      final response = await client.dio.get<Map<String, dynamic>>('items');

      expect(response.statusCode, 200);
      expect(response.data!['ok'], true);
      expect(tokenStore.getToken(), 'new.jwt');
      expect(lastRefreshedToken, 'new.jwt');
      expect(getCount, 2);
    });

    test('401 on path under auth/ does not attempt refresh', () async {
      tokenStore.setToken('t');
      var refreshPosts = 0;

      final client = ApiClient(
        secureStorage: mockSecure,
        tokenStore: tokenStore,
        onAuthFailure: () => authFailureCalls++,
      );

      client.dio.httpClientAdapter = _FakeHttpClientAdapter((options) {
        final path = options.uri.path;
        if (path.contains('auth/refresh')) {
          refreshPosts++;
        }
        return _jsonResponse(401, <String, dynamic>{'message': 'no'});
      });

      await expectLater(
        () => client.dio.get<Object>('auth/me'),
        throwsA(isA<DioException>()),
      );

      expect(refreshPosts, 0);
      expect(authFailureCalls, 0);
      expect(tokenStore.getToken(), 't');
    });

    test('401 on auth/refresh clears session and notifies', () async {
      tokenStore.setToken('t');
      tokenStore.setMfaPending(true);

      final client = ApiClient(
        secureStorage: mockSecure,
        tokenStore: tokenStore,
        onAuthFailure: () => authFailureCalls++,
      );

      client.dio.httpClientAdapter = _FakeHttpClientAdapter((options) {
        return _jsonResponse(401, <String, dynamic>{});
      });

      await expectLater(
        () => client.dio.post<Object>('auth/refresh'),
        throwsA(isA<DioException>()),
      );

      expect(authFailureCalls, 1);
      expect(tokenStore.getToken(), isNull);
      expect(tokenStore.isMfaPending, false);
      verify(() => mockSecure.deleteRefreshToken()).called(1);
    });

    test('401 with no refresh token clears session and notifies', () async {
      when(() => mockSecure.getRefreshToken()).thenAnswer((_) async => null);
      tokenStore.setToken('t');

      final client = ApiClient(
        secureStorage: mockSecure,
        tokenStore: tokenStore,
        onAuthFailure: () => authFailureCalls++,
      );

      client.dio.httpClientAdapter = _FakeHttpClientAdapter((_) {
        return _jsonResponse(401, <String, dynamic>{});
      });

      await expectLater(
        () => client.dio.get<Object>('items'),
        throwsA(isA<DioException>()),
      );

      expect(authFailureCalls, 1);
      expect(tokenStore.getToken(), isNull);
      verify(() => mockSecure.deleteRefreshToken()).called(1);
    });

    test('401 when refresh envelope lacks accessToken clears session', () async {
      tokenStore.setToken('t');

      final client = ApiClient(
        secureStorage: mockSecure,
        tokenStore: tokenStore,
        onAuthFailure: () => authFailureCalls++,
      );

      client.dio.httpClientAdapter = _FakeHttpClientAdapter((options) {
        final path = options.uri.path;
        if (options.method == 'GET' && path.endsWith('/items')) {
          return _jsonResponse(401, <String, dynamic>{});
        }
        if (options.method == 'POST' && path.contains('auth/refresh')) {
          return _jsonResponse(200, <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{},
          });
        }
        fail('Unexpected ${options.method} $path');
      });

      await expectLater(
        () => client.dio.get<Object>('items'),
        throwsA(isA<DioException>()),
      );

      expect(authFailureCalls, 1);
      expect(tokenStore.getToken(), isNull);
    });

    test('401 when refresh returns success false clears session', () async {
      tokenStore.setToken('t');

      final client = ApiClient(
        secureStorage: mockSecure,
        tokenStore: tokenStore,
        onAuthFailure: () => authFailureCalls++,
      );

      client.dio.httpClientAdapter = _FakeHttpClientAdapter((options) {
        final path = options.uri.path;
        if (options.method == 'GET' && path.endsWith('/items')) {
          return _jsonResponse(401, <String, dynamic>{});
        }
        if (options.method == 'POST' && path.contains('auth/refresh')) {
          return _jsonResponse(200, <String, dynamic>{
            'success': false,
            'error': <String, dynamic>{'message': 'invalid refresh'},
          });
        }
        fail('Unexpected ${options.method} $path');
      });

      await expectLater(
        () => client.dio.get<Object>('items'),
        throwsA(isA<DioException>()),
      );

      expect(authFailureCalls, 1);
      expect(tokenStore.getToken(), isNull);
    });

    test('401 when refresh request throws clears session', () async {
      tokenStore.setToken('t');

      final client = ApiClient(
        secureStorage: mockSecure,
        tokenStore: tokenStore,
        onAuthFailure: () => authFailureCalls++,
      );

      client.dio.httpClientAdapter = _FakeHttpClientAdapter((options) {
        final path = options.uri.path;
        if (options.method == 'GET' && path.endsWith('/items')) {
          return _jsonResponse(401, <String, dynamic>{});
        }
        if (options.method == 'POST' && path.contains('auth/refresh')) {
          throw StateError('adapter failure');
        }
        fail('Unexpected ${options.method} $path');
      });

      await expectLater(
        () => client.dio.get<Object>('items'),
        throwsA(isA<DioException>()),
      );

      expect(authFailureCalls, 1);
      expect(tokenStore.getToken(), isNull);
    });

    test('403 with MFA required message sets pending and invokes callback', () async {
      final client = ApiClient(
        secureStorage: mockSecure,
        tokenStore: tokenStore,
        onMfaRequired: () => mfaRequiredCalls++,
      );

      client.dio.httpClientAdapter = _FakeHttpClientAdapter((_) {
        return _jsonResponse(403, <String, dynamic>{
          'error': <String, dynamic>{'message': 'MFA verification required'},
        });
      });

      await expectLater(
        () => client.dio.get<Object>('items'),
        throwsA(isA<DioException>()),
      );

      expect(tokenStore.isMfaPending, true);
      expect(mfaRequiredCalls, 1);
    });

    test('non-401 errors pass through without refresh', () async {
      tokenStore.setToken('t');
      var refreshPosts = 0;

      final client = ApiClient(
        secureStorage: mockSecure,
        tokenStore: tokenStore,
      );

      client.dio.httpClientAdapter = _FakeHttpClientAdapter((options) {
        if (options.uri.path.contains('auth/refresh')) {
          refreshPosts++;
        }
        return _jsonResponse(500, <String, dynamic>{'message': 'server'});
      });

      await expectLater(
        () => client.dio.get<Object>('items'),
        throwsA(isA<DioException>()),
      );

      expect(refreshPosts, 0);
      expect(tokenStore.getToken(), 't');
    });
  });
}
