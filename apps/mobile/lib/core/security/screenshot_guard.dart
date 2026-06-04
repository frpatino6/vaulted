import 'dart:io';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';

class ScreenshotGuard {
  static Future<void> enableGlobal() async {
    if (Platform.isAndroid) {
      await FlutterWindowManagerPlus.addFlags(
        FlutterWindowManagerPlus.FLAG_SECURE,
      );
    }
  }

  static Future<void> disableGlobal() async {
    if (Platform.isAndroid) {
      await FlutterWindowManagerPlus.clearFlags(
        FlutterWindowManagerPlus.FLAG_SECURE,
      );
    }
  }
}
