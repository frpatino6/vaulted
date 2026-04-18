import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/features/auth/data/auth_remote_data_source.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockDio extends Mock implements Dio {}

class MockHeaders extends Mock implements Headers {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a fake [Response] that Dio would return.
Response<Map<String, dynamic>> _makeResponse({
  required RequestOptions requestOptions,
  required Map<String, dynamic> data,
  int statusCode = 200,
  Headers? headers,
}) {
  return Response<Map<String, dynamic>>(
    requestOptions: requestOptions,
    data: data,
    statusCode: statusCode,
    headers: headers,
  );
}

/// A [Headers] implementation backed by a plain map, usable in tests without
/// needing a real HTTP response.
class FakeHeaders extends Fake implements Headers {
  FakeHeaders(this._map);

  final Map<String, List<String>> _map;

  @override
  String? value(String name) {
    final lower = name.toLowerCase();
    for (final key in _map.keys) {
      if (key.toLowerCase() == lower) {
        final values = _map[key];
        if (values != null && values.isNotEmpty) return values.first;
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockDio mockDio;
  late AuthRemoteDataSource dataSource;
  late RequestOptions fakeRequestOptions;

  setUp(() {
    mockDio = MockDio();
    dataSource = AuthRemoteDataSource(mockDio);
    fakeRequestOptions = RequestOptions(path: '/test');
  });

  // -------------------------------------------------------------------------
  // login()
  // -------------------------------------------------------------------------
  group('AuthRemoteDataSource.login', () {
    const email = 'owner@test.com';
    const password = 'Test1234!Secure';

    test('returns data and setCookie on success with mfaRequired=false', () async {
      final headers = FakeHeaders({
        'set-cookie': ['refresh_token=abc123; Path=/; HttpOnly'],
      });
      final response = _makeResponse(
        requestOptions: fakeRequestOptions,
        data: {
          'success': true,
          'data': {'accessToken': 'access.jwt', 'mfaRequired': false},
        },
        headers: headers,
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          'auth/login',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      final result = await dataSource.login(email, password);

      expect(result.data['accessToken'], 'access.jwt');
      expect(result.data['mfaRequired'], false);
      expect(result.setCookie, 'refresh_token=abc123; Path=/; HttpOnly');
    });

    test('returns data and setCookie on success with mfaRequired=true', () async {
      final headers = FakeHeaders({
        'set-cookie': ['refresh_token=mfa_pending_token; Path=/; HttpOnly'],
      });
      final response = _makeResponse(
        requestOptions: fakeRequestOptions,
        data: {
          'success': true,
          'data': {'accessToken': 'temp.jwt', 'mfaRequired': true},
        },
        headers: headers,
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          'auth/login',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      final result = await dataSource.login(email, password);

      expect(result.data['mfaRequired'], true);
      expect(result.setCookie, contains('refresh_token=mfa_pending_token'));
    });

    test('returns null setCookie when header is absent', () async {
      final headers = FakeHeaders({});
      final response = _makeResponse(
        requestOptions: fakeRequestOptions,
        data: {
          'success': true,
          'data': {'accessToken': 'access.jwt', 'mfaRequired': false},
        },
        headers: headers,
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          'auth/login',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      final result = await dataSource.login(email, password);

      expect(result.setCookie, isNull);
    });

    test('throws DioException when success=false with error message', () async {
      final headers = FakeHeaders({});
      final response = _makeResponse(
        requestOptions: fakeRequestOptions,
        data: {
          'success': false,
          'error': {'message': 'Invalid credentials'},
        },
        statusCode: 401,
        headers: headers,
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          'auth/login',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      expect(
        () => dataSource.login(email, password),
        throwsA(isA<DioException>()),
      );
    });

    test('throws DioException when response data is null', () async {
      final headers = FakeHeaders({});
      // Return a Response<Map> with null data.
      final response = Response<Map<String, dynamic>>(
        requestOptions: fakeRequestOptions,
        data: null,
        statusCode: 200,
        headers: headers,
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          'auth/login',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      expect(
        () => dataSource.login(email, password),
        throwsA(isA<DioException>()),
      );
    });

    test('propagates DioException from Dio (e.g. network error)', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          'auth/login',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: fakeRequestOptions,
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => dataSource.login(email, password),
        throwsA(isA<DioException>()),
      );
    });

    test('sends correct email and password in request body', () async {
      final headers = FakeHeaders({});
      final response = _makeResponse(
        requestOptions: fakeRequestOptions,
        data: {
          'success': true,
          'data': {'accessToken': 'access.jwt', 'mfaRequired': false},
        },
        headers: headers,
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          'auth/login',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      await dataSource.login(email, password);

      final captured = verify(
        () => mockDio.post<Map<String, dynamic>>(
          'auth/login',
          data: captureAny(named: 'data'),
        ),
      ).captured;

      final sentBody = captured.first as Map<String, dynamic>;
      expect(sentBody['email'], email);
      expect(sentBody['password'], password);
    });
  });

  // -------------------------------------------------------------------------
  // verifyMfa()
  // -------------------------------------------------------------------------
  group('AuthRemoteDataSource.verifyMfa', () {
    const code = '123456';

    test('returns data and setCookie on success', () async {
      final headers = FakeHeaders({
        'set-cookie': ['refresh_token=full_token; Path=/; HttpOnly'],
      });
      final response = _makeResponse(
        requestOptions: fakeRequestOptions,
        data: {
          'success': true,
          'data': {'accessToken': 'full.jwt'},
        },
        headers: headers,
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          'auth/mfa/verify',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      final result = await dataSource.verifyMfa(code);

      expect(result.data['accessToken'], 'full.jwt');
      expect(result.setCookie, contains('refresh_token=full_token'));
    });

    test('throws DioException on 401', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          'auth/mfa/verify',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: fakeRequestOptions,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: fakeRequestOptions,
            statusCode: 401,
          ),
        ),
      );

      expect(
        () => dataSource.verifyMfa(code),
        throwsA(isA<DioException>()),
      );
    });

    test('sends correct code in request body', () async {
      final headers = FakeHeaders({});
      final response = _makeResponse(
        requestOptions: fakeRequestOptions,
        data: {
          'success': true,
          'data': {'accessToken': 'full.jwt'},
        },
        headers: headers,
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          'auth/mfa/verify',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      await dataSource.verifyMfa(code);

      final captured = verify(
        () => mockDio.post<Map<String, dynamic>>(
          'auth/mfa/verify',
          data: captureAny(named: 'data'),
        ),
      ).captured;

      final sentBody = captured.first as Map<String, dynamic>;
      expect(sentBody['code'], code);
    });
  });

  // -------------------------------------------------------------------------
  // logout()
  //
  // AuthRemoteDataSource.logout() calls _dio.post('auth/logout') without a
  // type argument, so Dio infers Response<dynamic>.  The mock must be stubbed
  // with the dynamic type to match.
  // -------------------------------------------------------------------------
  group('AuthRemoteDataSource.logout', () {
    test('calls POST /auth/logout and completes without error', () async {
      when(
        () => mockDio.post<dynamic>('auth/logout'),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: fakeRequestOptions,
          statusCode: 200,
        ),
      );

      await expectLater(dataSource.logout(), completes);

      verify(() => mockDio.post<dynamic>('auth/logout')).called(1);
    });

    test('propagates DioException on network failure', () async {
      when(
        () => mockDio.post<dynamic>('auth/logout'),
      ).thenThrow(
        DioException(
          requestOptions: fakeRequestOptions,
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => dataSource.logout(),
        throwsA(isA<DioException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // refresh()
  // -------------------------------------------------------------------------
  group('AuthRemoteDataSource.refresh', () {
    test('returns unwrapped data on success', () async {
      final response = _makeResponse(
        requestOptions: fakeRequestOptions,
        data: {
          'success': true,
          'data': {'accessToken': 'refreshed.jwt'},
        },
      );

      when(
        () => mockDio.post<Map<String, dynamic>>('auth/refresh'),
      ).thenAnswer((_) async => response);

      final result = await dataSource.refresh();

      expect(result['accessToken'], 'refreshed.jwt');
    });

    test('throws DioException when response data is null', () async {
      final response = Response<Map<String, dynamic>>(
        requestOptions: fakeRequestOptions,
        data: null,
        statusCode: 200,
      );

      when(
        () => mockDio.post<Map<String, dynamic>>('auth/refresh'),
      ).thenAnswer((_) async => response);

      expect(
        () => dataSource.refresh(),
        throwsA(isA<DioException>()),
      );
    });

    test('throws DioException on 401', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>('auth/refresh'),
      ).thenThrow(
        DioException(
          requestOptions: fakeRequestOptions,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: fakeRequestOptions,
            statusCode: 401,
          ),
        ),
      );

      expect(
        () => dataSource.refresh(),
        throwsA(isA<DioException>()),
      );
    });
  });
}
