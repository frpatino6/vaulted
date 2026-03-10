import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router_provider.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: VaultedApp(),
    ),
  );
}

class VaultedApp extends ConsumerWidget {
  const VaultedApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Vaulted',
      theme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
