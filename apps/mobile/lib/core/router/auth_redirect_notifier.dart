import 'package:flutter/foundation.dart';

/// Notifier that triggers GoRouter redirect when auth is lost (e.g. 401 + refresh failure).
class AuthRedirectNotifier extends ChangeNotifier {
  void notifyAuthLost() {
    notifyListeners();
  }
}
