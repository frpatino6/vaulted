import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router_provider.dart';
import 'core/storage/auth_token_store.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/presence/presentation/providers/presence_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _tryRestoreSession();
  runApp(
    const ProviderScope(
      child: VaultedApp(),
    ),
  );
}

/// Attempts to restore a previous authenticated session using the stored refresh token.
/// Runs before the widget tree is built, so the router sees a valid token from
/// the first frame and navigates directly to /dashboard — no login or MFA prompt.
///
/// On any failure (expired token, network error, server down) the function
/// returns silently and the user proceeds through the normal login flow.
Future<void> _tryRestoreSession() async {
  try {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
      extra: {'withCredentials': kIsWeb},
    ));

    final Options refreshOptions;
    FlutterSecureStorage? storage;
    if (kIsWeb) {
      // On web, browser sends the httpOnly cookie automatically.
      // Setting Cookie manually is blocked by browsers (forbidden header).
      refreshOptions = Options(extra: {'withCredentials': true});
    } else {
      storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      final refreshToken = await storage.read(key: 'refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) return;
      refreshOptions = Options(
        headers: {'Cookie': 'refresh_token=$refreshToken'},
      );
    }

    final response = await dio.post<Map<String, dynamic>>(
      'auth/refresh',
      options: refreshOptions,
    );

    final body = response.data;
    if (body?['success'] != true) return;

    final accessToken = body?['data']?['accessToken'] as String?;
    if (accessToken == null || accessToken.isEmpty) return;

    AuthTokenStore.instance.setToken(accessToken);
    AuthTokenStore.instance.setMfaPending(false);

    // Save the rotated refresh token (mobile only — web uses httpOnly cookie)
    if (storage != null) {
      final setCookie = response.headers.value('set-cookie') ??
          response.headers.value('Set-Cookie');
      if (setCookie != null) {
        final newRefreshToken = _parseRefreshToken(setCookie);
        if (newRefreshToken != null) {
          await storage.write(key: 'refresh_token', value: newRefreshToken);
        }
      }
    }
  } catch (_) {
    // Token expired, network error, or server unreachable.
    // Fall through silently — user logs in manually.
  }
}

String? _parseRefreshToken(String setCookie) {
  const prefix = 'refresh_token=';
  final start = setCookie.indexOf(prefix);
  if (start == -1) return null;
  final valueStart = start + prefix.length;
  final end = setCookie.indexOf(';', valueStart);
  return end == -1
      ? setCookie.substring(valueStart).trim()
      : setCookie.substring(valueStart, end).trim();
}

class VaultedApp extends ConsumerStatefulWidget {
  const VaultedApp({super.key});

  @override
  ConsumerState<VaultedApp> createState() => _VaultedAppState();
}

class _VaultedAppState extends ConsumerState<VaultedApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(presenceNotifierProvider.notifier);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        notifier.pauseHeartbeat();
      case AppLifecycleState.resumed:
        notifier.resumeHeartbeat();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Vaulted',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
