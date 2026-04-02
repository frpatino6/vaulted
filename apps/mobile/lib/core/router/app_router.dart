import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../storage/auth_token_store.dart';
import 'auth_redirect_notifier.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/mfa_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/wardrobe/presentation/wardrobe_screen.dart';
import '../../features/wardrobe/presentation/outfit_detail_screen.dart';
import '../../features/wardrobe/presentation/create_outfit_screen.dart';
import '../../features/wardrobe/presentation/outfit_list_screen.dart';
import '../../features/inventory/presentation/item_detail_screen.dart';
import '../../features/inventory/presentation/qr_scanner_screen.dart';
import '../../features/inventory/presentation/room_detail_screen.dart';
import '../../features/inventory/presentation/search_screen.dart';
import '../../features/properties/presentation/property_detail_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/users/presentation/users_screen.dart';
import '../../features/ai_chat/presentation/chat_screen.dart';
import '../../features/maintenance/presentation/maintenance_list_screen.dart';
import '../../features/movements/presentation/movements_screen.dart';
import '../../features/movements/presentation/movement_scan_screen.dart';
import '../../features/movements/presentation/movement_detail_screen.dart';

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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/mfa', builder: (context, state) => const MfaScreen()),
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
      // Route used when navigating from a section QR scan — no propertyId known
      GoRoute(
        path: '/rooms/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          final roomName = state.uri.queryParameters['name'] ?? '';
          final section = state.uri.queryParameters['section'] ?? '';
          return RoomDetailScreen(
            propertyId: '',
            roomId: roomId,
            roomName: roomName.isNotEmpty ? roomName : 'Section',
            initialSection: section.isNotEmpty ? section : null,
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
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/wardrobe',
        builder: (context, state) => const WardrobeScreen(),
      ),

      GoRoute(
        path: '/wardrobe/outfits',
        builder: (context, state) => const OutfitListScreen(),
      ),
      GoRoute(
        path: '/wardrobe/outfits/new',
        builder: (context, state) => const CreateOutfitScreen(),
      ),
      GoRoute(
        path: '/wardrobe/outfits/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OutfitDetailScreen(outfitId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/users',
        builder: (context, state) => const UsersScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => const MaintenanceListScreen(),
      ),
      GoRoute(
        path: '/movements',
        builder: (context, state) => const MovementsScreen(),
      ),
      GoRoute(
        path: '/movements/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return MovementDetailScreen(movementId: id);
        },
      ),
      GoRoute(
        path: '/movements/:id/scan',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return MovementScanScreen(movementId: id);
        },
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
