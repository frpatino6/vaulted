import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vaulted/core/privacy/privacy_mode_provider.dart';
import 'package:vaulted/core/storage/secure_storage.dart';
import 'package:vaulted/core/storage/secure_storage_provider.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  setUpAll(() {
    registerFallbackValue(false);
  });

  test('build() exposes privacy flag from secure storage', () async {
    final secure = MockSecureStorage();
    when(() => secure.getPrivacyMode()).thenAnswer((_) async => true);

    final container = ProviderContainer(
      overrides: [secureStorageProvider.overrideWithValue(secure)],
    );
    addTearDown(container.dispose);

    final v = await container.read(privacyModeProvider.future);
    expect(v, true);
  });

  test('toggle() flips value and persists to secure storage', () async {
    final secure = MockSecureStorage();
    when(() => secure.getPrivacyMode()).thenAnswer((_) async => false);
    when(() => secure.savePrivacyMode(any())).thenAnswer((_) async {});

    final container = ProviderContainer(
      overrides: [secureStorageProvider.overrideWithValue(secure)],
    );
    addTearDown(container.dispose);

    await container.read(privacyModeProvider.future);
    await container.read(privacyModeProvider.notifier).toggle();

    expect(container.read(privacyModeProvider).valueOrNull, true);
    verify(() => secure.savePrivacyMode(true)).called(1);
  });

  test('reset() forces false and deletes stored preference', () async {
    final secure = MockSecureStorage();
    when(() => secure.getPrivacyMode()).thenAnswer((_) async => true);
    when(() => secure.deletePrivacyMode()).thenAnswer((_) async {});

    final container = ProviderContainer(
      overrides: [secureStorageProvider.overrideWithValue(secure)],
    );
    addTearDown(container.dispose);

    await container.read(privacyModeProvider.future);
    await container.read(privacyModeProvider.notifier).reset();

    expect(container.read(privacyModeProvider).valueOrNull, false);
    verify(() => secure.deletePrivacyMode()).called(1);
  });
}
