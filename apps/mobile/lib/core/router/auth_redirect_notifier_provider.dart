import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_redirect_notifier.dart';

final authRedirectNotifierProvider =
    Provider<AuthRedirectNotifier>((ref) => AuthRedirectNotifier());
