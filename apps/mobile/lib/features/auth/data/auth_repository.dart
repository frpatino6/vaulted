import '../../../core/storage/auth_token_store.dart';
import '../../../core/storage/secure_storage.dart';
import 'auth_remote_data_source.dart';

/// Parses refresh_token from Set-Cookie header.
String? _parseRefreshTokenFromCookie(String? setCookie) {
  if (setCookie == null || setCookie.isEmpty) return null;
  const prefix = 'refresh_token=';
  final start = setCookie.indexOf(prefix);
  if (start == -1) return null;
  final valueStart = start + prefix.length;
  final end = setCookie.indexOf(';', valueStart);
  if (end == -1) {
    return setCookie.substring(valueStart).trim();
  }
  return setCookie.substring(valueStart, end).trim();
}

class AuthRepository {
  AuthRepository({
    required AuthRemoteDataSource remote,
    required SecureStorage secureStorage,
    required AuthTokenStore tokenStore,
  })  : _remote = remote,
        _secureStorage = secureStorage,
        _tokenStore = tokenStore;

  final AuthRemoteDataSource _remote;
  final SecureStorage _secureStorage;
  final AuthTokenStore _tokenStore;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await _remote.login(email, password);

    final accessToken = result.data['accessToken'] as String?;
    final mfaRequired = result.data['mfaRequired'] as bool? ?? false;

    if (accessToken == null) {
      throw Exception('No access token in response');
    }

    final refreshToken = _parseRefreshTokenFromCookie(result.setCookie);
    if (refreshToken != null) {
      await _secureStorage.saveRefreshToken(refreshToken);
    }

    _tokenStore.setToken(accessToken);

    return {'accessToken': accessToken, 'mfaRequired': mfaRequired};
  }

  Future<Map<String, dynamic>> acceptInvite({
    required String token,
    required String password,
  }) async {
    final result = await _remote.acceptInvite(token: token, password: password);

    final accessToken = result.data['accessToken'] as String?;
    final mfaRequired = result.data['mfaRequired'] as bool? ?? false;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token in response');
    }

    final refreshToken = _parseRefreshTokenFromCookie(result.setCookie);
    if (refreshToken != null) {
      await _secureStorage.saveRefreshToken(refreshToken);
    }

    _tokenStore.setToken(accessToken);

    return {'accessToken': accessToken, 'mfaRequired': mfaRequired};
  }

  Future<Map<String, dynamic>> verifyMfa(String code) async {
    final result = await _remote.verifyMfa(code);
    final accessToken = result.data['accessToken'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token in MFA verification response');
    }
    // Save the new refresh token (mfaVerified=true encoded) — replaces the pre-MFA one
    final refreshToken = _parseRefreshTokenFromCookie(result.setCookie);
    if (refreshToken != null) {
      await _secureStorage.saveRefreshToken(refreshToken);
    }
    _tokenStore.setToken(accessToken);
    return result.data;
  }

  Future<void> logout() async {
    try {
      await _remote.logout();
    } finally {
      await _secureStorage.deleteRefreshToken();
      _tokenStore.clear();
    }
  }
}
