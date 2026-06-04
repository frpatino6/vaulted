import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class DeviceSecurityService {
  static Future<bool> isDeviceCompromised() async {
    if (kDebugMode) return false;
    try {
      final jailbroken = await FlutterJailbreakDetection.jailbroken;
      return jailbroken;
    } catch (_) {
      return false;
    }
  }
}
