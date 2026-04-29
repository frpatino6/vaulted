import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB-HgQixM9sZG6MNzgpIQbJxzHsyQ7RmGE',
    authDomain: 'vaulted-prod-2026.firebaseapp.com',
    projectId: 'vaulted-prod-2026',
    storageBucket: 'vaulted-prod-2026.firebasestorage.app',
    messagingSenderId: '729564960430',
    appId: '1:729564960430:web:e502f79b1b66c7b8a47f3f',
  );

  // VAPID key used in getToken() calls for web push — not part of FirebaseOptions
  static const String webVapidKey = 'BB3s8Z0zRMs0rkLG7qh1nR3uKFqB0SerPCQcSr9YBE-BJdV6DMI3t84oSs6XMVKigeg0lLqPId4rAbgeA08oCSY';

  // TODO: replace with values from google-services.json once available
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_ANDROID_API_KEY',
    appId: 'REPLACE_WITH_ANDROID_APP_ID',
    messagingSenderId: '729564960430',
    projectId: 'vaulted-prod-2026',
    storageBucket: 'vaulted-prod-2026.firebasestorage.app',
  );

  // TODO: replace with values from GoogleService-Info.plist once available
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: 'REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '729564960430',
    projectId: 'vaulted-prod-2026',
    storageBucket: 'vaulted-prod-2026.firebasestorage.app',
    iosBundleId: 'com.vaulted.vaulted',
  );
}
