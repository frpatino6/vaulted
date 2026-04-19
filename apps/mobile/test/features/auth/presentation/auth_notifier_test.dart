import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vaulted/core/router/auth_redirect_notifier.dart';
import 'package:vaulted/core/router/auth_redirect_notifier_provider.dart';
import 'package:vaulted/core/storage/auth_token_store.dart';
import 'package:vaulted/core/storage/secure_storage_provider.dart';
import 'package:vaulted/features/auth/data/auth_repository.dart';
import 'package:vaulted/features/auth/data/auth_repository_provider.dart';
import 'package:vaulted/features/auth/domain/auth_state.dart';
import 'package:vaulted/features/auth/presentation/auth_notifier.dart';
import 'package:vaulted/features/presence/presentation/providers/presence_provider.dart';
import 'package:vaulted/core/storage/secure_storage.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorage extends Mock implements SecureStorage {}

class _StubPresenceNotifier extends PresenceNotifier {
  @override
  Future<PresenceState> build() async {
    ref.onDispose(() {});
    return const PresenceState();
  }

  @override
  Future<void> initialize(String accessToken) async {}

  @override
  void pauseHeartbeat() {}
}

void main() {
  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    AuthTokenStore.instance.clear();
  });

  tearDown(() {
    AuthTokenStore.instance.clear();
  });

  ProviderContainer buildContainer({
    required AuthRepository authRepository,
    SecureStorage? secureStorage,
  }) {
    return ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        secureStorageProvider.overrideWithValue(secureStorage ?? MockSecureStorage()),
        presenceNotifierProvider.overrideWith(_StubPresenceNotifier.new),
      ],
    );
  }

  test('login() transitions to authenticated when MFA is not required', () async {
    final repo = MockAuthRepository();
    when(() => repo.login(any(), any())).thenAnswer(
      (_) async => {'accessToken': 'at', 'mfaRequired': false},
    );
    final container = buildContainer(authRepository: repo);
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.notifier).login('a@b.com', 'secret');

    expect(
      container.read(authNotifierProvider),
      isA<AsyncData<AuthState>>().having(
        (AsyncData<AuthState> d) => d.value,
        'value',
        const AuthState.authenticated(),
      ),
    );
    expect(AuthTokenStore.instance.isMfaPending, false);
    verify(() => repo.login(any(), any())).called(1);
  });

  test('login() transitions to mfaRequired and sets MFA pending', () async {
    final repo = MockAuthRepository();
    when(() => repo.login(any(), any())).thenAnswer(
      (_) async => {'accessToken': 'partial', 'mfaRequired': true},
    );
    final container = buildContainer(authRepository: repo);
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.notifier).login('a@b.com', 'secret');

    expect(
      container.read(authNotifierProvider).valueOrNull,
      const AuthState.mfaRequired(),
    );
    expect(AuthTokenStore.instance.isMfaPending, true);
  });

  test('login() maps 401 to invalid credentials message', () async {
    final repo = MockAuthRepository();
    when(() => repo.login(any(), any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/login'),
        response: Response(requestOptions: RequestOptions(path: '/login'), statusCode: 401),
        type: DioExceptionType.badResponse,
      ),
    );
    final container = buildContainer(authRepository: repo);
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.notifier).login('a@b.com', 'bad');

    final state = container.read(authNotifierProvider).valueOrNull;
    expect(state, isA<AuthState>());
    expect(
      state!.maybeWhen(error: (m) => m, orElse: () => ''),
      'Invalid email or password.',
    );
  });

  test('logout() clears auth and notifies redirect', () async {
    final repo = MockAuthRepository();
    when(() => repo.logout()).thenAnswer((_) async {});
    final secure = MockSecureStorage();
    when(() => secure.deletePrivacyMode()).thenAnswer((_) async {});

    final redirect = AuthRedirectNotifier();
    var lost = 0;
    redirect.addListener(() => lost++);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        secureStorageProvider.overrideWithValue(secure),
        presenceNotifierProvider.overrideWith(_StubPresenceNotifier.new),
        authRedirectNotifierProvider.overrideWithValue(redirect),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authNotifierProvider.notifier).logout();

    expect(
      container.read(authNotifierProvider).valueOrNull,
      const AuthState.initial(),
    );
    verify(() => repo.logout()).called(1);
    verify(() => secure.deletePrivacyMode()).called(1);
    expect(lost, 1);
  });
}
