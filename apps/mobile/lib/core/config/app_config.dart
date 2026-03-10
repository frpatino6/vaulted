import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// App configuration — never hardcode API URLs or secrets.
class AppConfig {
  AppConfig._();

  /// API base URL. Uses localhost for web/iOS/desktop, 10.0.2.2 for Android emulator.
  static String get apiBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;
    // Android emulator: 10.0.2.2 = host machine's localhost
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }
}
