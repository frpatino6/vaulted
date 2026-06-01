import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, defaultTargetPlatform, TargetPlatform;

/// App configuration — never hardcode API URLs or secrets.
class AppConfig {
  AppConfig._();

  /// API base URL. Release builds must inject an HTTPS URL via --dart-define.
  static String get apiBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      _assertSecureUrl(
        envUrl,
        expectedReleaseScheme: 'https',
        name: 'API_BASE_URL',
      );
      return envUrl;
    }
    if (!kDebugMode) {
      throw StateError('API_BASE_URL is required for release builds.');
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/';
    }
    return 'http://localhost:3000/api/';
  }

  /// WebSocket base URL (root, no /api prefix) used by Socket.IO.
  static String get wsBaseUrl {
    const envUrl = String.fromEnvironment('WS_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      _assertSecureUrl(
        envUrl,
        expectedReleaseScheme: 'wss',
        name: 'WS_BASE_URL',
      );
      return envUrl;
    }
    if (!kDebugMode) {
      throw StateError('WS_BASE_URL is required for release builds.');
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static void _assertSecureUrl(
    String value, {
    required String expectedReleaseScheme,
    required String name,
  }) {
    if (kDebugMode) return;
    final uri = Uri.parse(value);
    if (uri.scheme != expectedReleaseScheme) {
      throw StateError(
        '$name must use $expectedReleaseScheme in release builds.',
      );
    }
  }
}
