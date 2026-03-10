import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'auth_redirect_notifier_provider.dart';

final appRouterProvider = Provider((ref) {
  final authRedirectNotifier = ref.watch(authRedirectNotifierProvider);
  return createAppRouter(authRedirectNotifier);
});
