import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/auth_token_store.dart';
import '../storage/secure_storage_provider.dart';
import '../router/auth_redirect_notifier_provider.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final authRedirectNotifier = ref.watch(authRedirectNotifierProvider);
  return ApiClient(
    secureStorage: secureStorage,
    tokenStore: AuthTokenStore.instance,
    onAuthFailure: authRedirectNotifier.notifyAuthLost,
  );
});
