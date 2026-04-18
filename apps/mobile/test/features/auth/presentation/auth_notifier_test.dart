import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:vaulted/core/router/auth_redirect_notifier.dart';
import 'package:vaulted/core/router/auth_redirect_notifier_provider.dart';
import 'package:vaulted/core/storage/auth_token_store.dart';
import 'package:vaulted/features/auth/data/auth_repository.dart';
import 'package:vaulted/features/auth/data/auth_repository_provider.dart';
import 'package:vaulted/features/auth/domain/auth_state.dart';
import 'package:vaulted/features/auth/presentation/auth_notifier.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAuthRedirectNotifier extends Mock implements AuthRedirectNotifier {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a [ProviderContainer] with test overrides.
ProviderContainer _makeContainer({
  required MockAuthRepository mockRepo,
  required MockAuthRedirectNotifier mockRedirect,
}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockRepo),
      authRedirectNotifierProvider.overrideWithValue(mockRedirect),
    ],
  );
}

/// Returns true when the [AuthState] value is the error variant carrying the
/// given [message].  Because Freezed generates a private `_Error` class we
/// can't import directly, we match via the Freezed `map` helper.
bool _isErrorWithMessage(AuthState? state, String message) {
  if (state == null) return false;
  return state.map(
    initial: (_) => false,
    loading: (_) => false,
    mfaRequired: (_) => false,
    authenticated: (_) => false,
    error: (e) => e.message == message,
  );
}

/// Returns true when [state] is any error variant.
bool _isError(AuthState? state) {
  if (state == null) return false;
  return state.map(
    initial: (_) => false,
    loading: (_) => false,
    mfaRequired: (_) => false,
    authenticated: (_) => false,
    error: (_) => true,
  );
}

/// Extracts the message from an error variant. Throws if not an error.
String _errorMessage(AuthState? state) {
  if (state == null) throw StateError('state is null');
  return state.map(
    initial: (_) => throw StateError('Not an error state'),
    loading: (_) => throw StateError('Not an error state'),
    mfaRequired: (_) => throw StateError('Not an error state'),
    authenticated: (_) => throw StateError('Not an error state'),
    error: (e) => e.message,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockAuthRepository mockRepo;
  late MockAuthRedirectNotifier mockRedirect;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockAuthRepository();
    mockRedirect = MockAuthRedirectNotifier();

    container = _makeContainer(
      mockRepo: mockRepo,
      mockRedirect: mockRedirect,
    );

    // Reset singleton token store before every test.
    AuthTokenStore.instance.clear();
  });

  tearDown(() {
    container.dispose();
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------
  group('AuthNotifier — initial state', () {
    test('starts as AsyncData containing AuthState.initial()', () {
      final asyncState = container.read(authNotifierProvider);
      expect(asyncState, isA<AsyncData<AuthState>>());
      expect(asyncState.value, const AuthState.initial());
    });
  });

  // -------------------------------------------------------------------------
  // login()
  // -------------------------------------------------------------------------
  group('AuthNotifier.login', () {
    test('transitions to authenticated when mfaRequired=false', () async {
      when(() => mockRepo.login(any(), any())).thenAnswer(
        (_) async => {'accessToken': 'access.jwt', 'mfaRequired': false},
      );

      await container
          .read(authNotifierProvider.notifier)
          .login('owner@test.com', 'Test1234!');

      expect(
        container.read(authNotifierProvider).value,
        const AuthState.authenticated(),
      );
    });

    test('sets mfaPending=false in AuthTokenStore when mfaRequired=false', () async {
      when(() => mockRepo.login(any(), any())).thenAnswer(
        (_) async => {'accessToken': 'access.jwt', 'mfaRequired': false},
      );

      await container
          .read(authNotifierProvider.notifier)
          .login('owner@test.com', 'Test1234!');

      expect(AuthTokenStore.instance.isMfaPending, isFalse);
    });

    test('transitions to mfaRequired when mfaRequired=true', () async {
      when(() => mockRepo.login(any(), any())).thenAnswer(
        (_) async => {'accessToken': 'temp.jwt', 'mfaRequired': true},
      );

      await container
          .read(authNotifierProvider.notifier)
          .login('owner@test.com', 'Test1234!');

      expect(
        container.read(authNotifierProvider).value,
        const AuthState.mfaRequired(),
      );
    });

    test('sets mfaPending=true in AuthTokenStore when mfaRequired=true', () async {
      when(() => mockRepo.login(any(), any())).thenAnswer(
        (_) async => {'accessToken': 'temp.jwt', 'mfaRequired': true},
      );

      await container
          .read(authNotifierProvider.notifier)
          .login('owner@test.com', 'Test1234!');

      expect(AuthTokenStore.instance.isMfaPending, isTrue);
    });

    test('transitions to error state on generic exception', () async {
      when(() => mockRepo.login(any(), any())).thenThrow(Exception('boom'));

      await container
          .read(authNotifierProvider.notifier)
          .login('owner@test.com', 'bad');

      final state = container.read(authNotifierProvider).value;
      expect(_isError(state), isTrue);
    });

    test('returns "Invalid email or password." for 401 DioException', () async {
      when(() => mockRepo.login(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 401,
          ),
        ),
      );

      await container
          .read(authNotifierProvider.notifier)
          .login('owner@test.com', 'wrong');

      final state = container.read(authNotifierProvider).value;
      expect(_isErrorWithMessage(state, 'Invalid email or password.'), isTrue);
    });

    test('returns rate-limit message for 429 DioException', () async {
      when(() => mockRepo.login(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 429,
          ),
        ),
      );

      await container
          .read(authNotifierProvider.notifier)
          .login('owner@test.com', 'pass');

      final state = container.read(authNotifierProvider).value;
      expect(_isError(state), isTrue);
      expect(_errorMessage(state), contains('Too many attempts'));
    });

    test('returns connectivity message for connectionError DioException', () async {
      when(() => mockRepo.login(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          type: DioExceptionType.connectionError,
        ),
      );

      await container
          .read(authNotifierProvider.notifier)
          .login('owner@test.com', 'pass');

      final state = container.read(authNotifierProvider).value;
      expect(_isError(state), isTrue);
      expect(_errorMessage(state), contains('internet connection'));
    });

    test('returns connectivity message for connectionTimeout DioException', () async {
      when(() => mockRepo.login(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      await container
          .read(authNotifierProvider.notifier)
          .login('owner@test.com', 'pass');

      final state = container.read(authNotifierProvider).value;
      expect(_errorMessage(state), contains('internet connection'));
    });

    test('returns API error message from response body when available', () async {
      when(() => mockRepo.login(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 400,
            data: {
              'error': {'message': 'Account is suspended'},
            },
          ),
        ),
      );

      await container
          .read(authNotifierProvider.notifier)
          .login('owner@test.com', 'pass');

      final state = container.read(authNotifierProvider).value;
      expect(_errorMessage(state), 'Account is suspended');
    });

    test('joins list API error messages from response body', () async {
      when(() => mockRepo.login(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 400,
            data: {
              'error': {
                'message': ['Email is invalid', 'Password too short'],
              },
            },
          ),
        ),
      );

      await container
          .read(authNotifierProvider.notifier)
          .login('owner@test.com', 'pass');

      final state = container.read(authNotifierProvider).value;
      expect(_errorMessage(state), 'Email is invalid, Password too short');
    });

    test('returns generic fallback for unknown exception type', () async {
      when(() => mockRepo.login(any(), any())).thenThrow(Exception('unknown'));

      await container
          .read(authNotifierProvider.notifier)
          .login('owner@test.com', 'pass');

      final state = container.read(authNotifierProvider).value;
      expect(_errorMessage(state), contains('Something went wrong'));
    });
  });

  // -------------------------------------------------------------------------
  // verifyMfa()
  // -------------------------------------------------------------------------
  group('AuthNotifier.verifyMfa', () {
    test('transitions to authenticated on success', () async {
      when(() => mockRepo.verifyMfa(any())).thenAnswer(
        (_) async => {'accessToken': 'final.jwt'},
      );

      await container.read(authNotifierProvider.notifier).verifyMfa('123456');

      expect(
        container.read(authNotifierProvider).value,
        const AuthState.authenticated(),
      );
    });

    test('clears mfaPending flag on success', () async {
      AuthTokenStore.instance.setMfaPending(true);

      when(() => mockRepo.verifyMfa(any())).thenAnswer(
        (_) async => {'accessToken': 'final.jwt'},
      );

      await container.read(authNotifierProvider.notifier).verifyMfa('123456');

      expect(AuthTokenStore.instance.isMfaPending, isFalse);
    });

    test('transitions to error on 401 DioException with specific MFA message', () async {
      when(() => mockRepo.verifyMfa(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/mfa/verify'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/auth/mfa/verify'),
            statusCode: 401,
          ),
        ),
      );

      await container.read(authNotifierProvider.notifier).verifyMfa('000000');

      final state = container.read(authNotifierProvider).value;
      expect(
        _isErrorWithMessage(state, 'Invalid or expired verification code.'),
        isTrue,
      );
    });

    test('returns "Too many attempts..." for 429 on verifyMfa', () async {
      when(() => mockRepo.verifyMfa(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/mfa/verify'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/auth/mfa/verify'),
            statusCode: 429,
          ),
        ),
      );

      await container.read(authNotifierProvider.notifier).verifyMfa('000000');

      final state = container.read(authNotifierProvider).value;
      expect(_errorMessage(state), contains('Too many attempts'));
    });

    test('returns generic MFA message for non-DioException', () async {
      when(() => mockRepo.verifyMfa(any())).thenThrow(Exception('server error'));

      await container.read(authNotifierProvider.notifier).verifyMfa('000000');

      final state = container.read(authNotifierProvider).value;
      expect(
        _isErrorWithMessage(state, 'Invalid verification code. Please try again.'),
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------------
  // logout()
  // -------------------------------------------------------------------------
  group('AuthNotifier.logout', () {
    test('transitions back to initial state on success', () async {
      when(() => mockRepo.logout()).thenAnswer((_) async {});
      when(() => mockRedirect.notifyAuthLost()).thenReturn(null);

      await container.read(authNotifierProvider.notifier).logout();

      expect(
        container.read(authNotifierProvider).value,
        const AuthState.initial(),
      );
    });

    test('calls notifyAuthLost on the redirect notifier', () async {
      when(() => mockRepo.logout()).thenAnswer((_) async {});
      when(() => mockRedirect.notifyAuthLost()).thenReturn(null);

      await container.read(authNotifierProvider.notifier).logout();

      verify(() => mockRedirect.notifyAuthLost()).called(1);
    });

    test('resets state and calls notifyAuthLost via finally even when remote throws', () async {
      // AuthNotifier.logout has a try/finally — the exception from
      // repository.logout() propagates to the caller, but the finally block
      // still sets state to initial and calls notifyAuthLost.
      when(() => mockRepo.logout()).thenThrow(Exception('remote failure'));
      when(() => mockRedirect.notifyAuthLost()).thenReturn(null);

      // The notifier re-throws, so we expect the future to fail.
      await expectLater(
        container.read(authNotifierProvider.notifier).logout(),
        throwsA(isA<Exception>()),
      );

      // Despite the throw, the finally block has already executed.
      expect(
        container.read(authNotifierProvider).value,
        const AuthState.initial(),
      );
      verify(() => mockRedirect.notifyAuthLost()).called(1);
    });
  });
}
