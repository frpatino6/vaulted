import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../domain/entities/notification_preference.dart';

// ---------------------------------------------------------------------------
// Data source provider
// ---------------------------------------------------------------------------

final notificationsDataSourceProvider =
    Provider<NotificationRemoteDatasource>((ref) {
  return NotificationRemoteDatasource(ref.watch(apiClientProvider).dio);
});

// ---------------------------------------------------------------------------
// Preferences notifier
// ---------------------------------------------------------------------------

class NotificationPreferencesNotifier
    extends AsyncNotifier<NotificationPreference> {
  @override
  Future<NotificationPreference> build() async {
    final json =
        await ref.read(notificationsDataSourceProvider).getPreferences();
    return NotificationPreference.fromJson(json);
  }

  Future<void> updatePreferences(Map<String, dynamic> updates) async {
    final previous = state;
    // Optimistic update
    state = state.whenData(
      (prefs) => prefs.copyWith(
        pushEnabled: updates['pushEnabled'] as bool? ?? prefs.pushEnabled,
        emailEnabled: updates['emailEnabled'] as bool? ?? prefs.emailEnabled,
        dryCleaningOverdue:
            updates['dryCleaningOverdue'] as bool? ?? prefs.dryCleaningOverdue,
        maintenanceDue:
            updates['maintenanceDue'] as bool? ?? prefs.maintenanceDue,
        itemAdded: updates['itemAdded'] as bool? ?? prefs.itemAdded,
      ),
    );
    try {
      final json = await ref
          .read(notificationsDataSourceProvider)
          .updatePreferences(updates);
      state = AsyncData(NotificationPreference.fromJson(json));
    } catch (e) {
      state = previous;
      rethrow;
    }
  }
}

final notificationPreferencesProvider = AsyncNotifierProvider<
    NotificationPreferencesNotifier, NotificationPreference>(
  NotificationPreferencesNotifier.new,
);

// ---------------------------------------------------------------------------
// FCM token registration provider
// Initialised once on app start; registers the token with the backend and
// re-registers whenever FCM rotates the token.
// ---------------------------------------------------------------------------

final fcmTokenRegistrationProvider = Provider<void>((ref) {
  _registerToken(ref);

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    _registerToken(ref, token: newToken);
  });
});

Future<void> _registerToken(Ref ref, {String? token}) async {
  try {
    final messaging = FirebaseMessaging.instance;
    final resolvedToken = token ??
        await messaging.getToken(
          vapidKey: kIsWeb
              ? 'VNLMAPj51JhaAuqj_8s4SAOYVhuHT37VwEPnuF_Ptys'
              : null,
        );
    if (resolvedToken == null) return;

    final platform = kIsWeb ? 'web' : _mobilePlatform();
    await ref
        .read(notificationsDataSourceProvider)
        .registerDeviceToken(resolvedToken, platform);
  } catch (_) {
    // Token registration is best-effort; never crash the app.
  }
}

// dart:io is only available on mobile; the call site is already guarded by !kIsWeb.
String _mobilePlatform() {
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  return 'mobile';
}
