import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vaulted/core/storage/secure_storage.dart';

void main() {
  late FlutterSecureStoragePlatform originalPlatform;
  late Map<String, String> backing;

  setUp(() {
    originalPlatform = FlutterSecureStoragePlatform.instance;
    backing = <String, String>{};
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform(backing);
  });

  tearDown(() {
    FlutterSecureStoragePlatform.instance = originalPlatform;
  });

  group('SecureStorage', () {
    test('saveRefreshToken writes refresh_token key', () async {
      final secure = SecureStorage(
        storage: const FlutterSecureStorage(),
      );

      await secure.saveRefreshToken('rt-secret');

      expect(backing['refresh_token'], 'rt-secret');
    });

    test('getRefreshToken reads refresh_token key', () async {
      backing['refresh_token'] = 'stored';

      final secure = SecureStorage(
        storage: const FlutterSecureStorage(),
      );

      expect(await secure.getRefreshToken(), 'stored');
    });

    test('deleteRefreshToken removes refresh_token key', () async {
      backing['refresh_token'] = 'x';

      final secure = SecureStorage(
        storage: const FlutterSecureStorage(),
      );

      await secure.deleteRefreshToken();

      expect(backing.containsKey('refresh_token'), false);
    });
  });
}
