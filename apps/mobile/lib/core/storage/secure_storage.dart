import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around flutter_secure_storage for token persistence.
/// Access token is NOT stored here — it lives only in memory (AuthTokenStore).
class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  static const _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  static const _privacyModeKey = 'privacy_mode';

  Future<void> savePrivacyMode(bool enabled) async {
    await _storage.write(key: _privacyModeKey, value: enabled.toString());
  }

  Future<bool> getPrivacyMode() async {
    return (await _storage.read(key: _privacyModeKey)) == 'true';
  }

  Future<void> deletePrivacyMode() async {
    await _storage.delete(key: _privacyModeKey);
  }
}
