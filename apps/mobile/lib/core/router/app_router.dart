import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../storage/auth_token_store.dart';
import 'auth_redirect_notifier.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/mfa_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/inventory/presentation/item_detail_screen.dart';
import '../../features/inventory/presentation/room_detail_screen.dart';
import '../../features/properties/presentation/property_detail_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

GoRouter createAppRouter(AuthRedirectNotifier authRedirectNotifier) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authRedirectNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final hasToken = AuthTokenStore.instance.getToken()?.isNotEmpty ?? false;
      final isMfaPending = AuthTokenStore.instance.isMfaPending;
      final isLogin = state.matchedLocation == '/login';
      final isMfa = state.matchedLocation == '/mfa';

      // /properties removed — redirect to dashboard
      if (state.matchedLocation == '/properties') return '/dashboard';

      // Not authenticated → force login
      if (!hasToken && !isLogin) return '/login';

      // Authenticated but MFA not yet verified → force MFA screen
      if (hasToken && isMfaPending && !isMfa) return '/mfa';

      // Fully authenticated → skip login/mfa screens
      if (hasToken && !isMfaPending && (isLogin || isMfa)) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/mfa',
        builder: (context, state) => const MfaScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/properties/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PropertyDetailScreen(propertyId: id);
        },
      ),
      GoRoute(
        path: '/properties/:propertyId/rooms/:roomId',
        builder: (context, state) {
          final propertyId = state.pathParameters['propertyId'] ?? '';
          final roomId = state.pathParameters['roomId'] ?? '';
          final roomName = state.uri.queryParameters['name'] ?? '';
          return RoomDetailScreen(
            propertyId: propertyId,
            roomId: roomId,
            roomName: roomName,
          );
        },
      ),
      GoRoute(
        path: '/items/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ItemDetailScreen(itemId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text(
              'Unauthorized',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      ),
    ],
  );
}

