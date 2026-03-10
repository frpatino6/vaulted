/// In-memory singleton for the access token.
/// Used by the Dio interceptor to attach Bearer token.
/// Access token is NEVER persisted — only in memory.
class AuthTokenStore {
  AuthTokenStore._();
  static final AuthTokenStore instance = AuthTokenStore._();

  String? _token;

  /// True while the user has logged in but MFA is not yet verified.
  /// Prevents router bypass: token exists but /dashboard is still blocked.
  bool _mfaPending = false;

  void setToken(String token) {
    _token = token;
  }

  String? getToken() => _token;

  void setMfaPending(bool pending) {
    _mfaPending = pending;
  }

  bool get isMfaPending => _mfaPending;

  void clear() {
    _token = null;
    _mfaPending = false;
  }
}
