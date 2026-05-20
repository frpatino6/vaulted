import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../storage/auth_token_store.dart';
import 'auth_redirect_notifier.dart';
import '../../features/users/domain/current_user_jwt.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/accept_invite_screen.dart';
import '../../features/auth/presentation/mfa_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/wardrobe/presentation/wardrobe_screen.dart';
import '../../features/wardrobe/presentation/at_laundry_screen.dart';
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
import '../../features/household_members/presentation/household_members_screen.dart';
import '../../features/ai_chat/presentation/chat_screen.dart';
import '../../features/maintenance/presentation/maintenance_list_screen.dart';
import '../../features/maintenance/presentation/maintenance_detail_screen.dart';
import '../../features/maintenance/data/models/maintenance_model.dart';
import '../../features/movements/presentation/movements_screen.dart';
import '../../features/movements/presentation/movement_scan_screen.dart';
import '../../features/movements/presentation/movement_detail_screen.dart';
import '../../features/ai_scan/data/models/ai_scan_result_model.dart';
import '../../features/ai_scan/presentation/ai_scan_screen.dart';
import '../../features/ai_scan/presentation/ai_item_review_screen.dart';
import '../../features/properties/data/models/floor_model.dart';
import '../../features/inventory/data/models/item_model.dart';
import '../../features/inventory/presentation/asset_browser_screen.dart';
import '../../features/inventory/presentation/qr_list_screen.dart';
import '../../features/insurance/presentation/insurance_list_screen.dart';
import '../../features/insurance/presentation/insurance_detail_screen.dart';
import '../../features/insurance/presentation/insurance_form_screen.dart';
import '../../features/insurance/presentation/coverage_gaps_screen.dart';
import '../../features/insurance/presentation/claim_draft_screen.dart';
import '../../features/notifications/presentation/pages/notification_center_page.dart';
import '../../features/notifications/presentation/pages/notification_preferences_page.dart';
import '../../features/orchestrator/data/models/orchestrator_plan_model.dart';
import '../../features/orchestrator/presentation/orchestrator_list_screen.dart';
import '../../features/orchestrator/presentation/orchestrator_new_command_screen.dart';
import '../../features/orchestrator/presentation/orchestrator_plan_detail_screen.dart';
import '../../features/orchestrator/presentation/orchestrator_plan_review_screen.dart';
import '../../features/orchestrator/presentation/orchestrator_progress_dashboard_screen.dart';
import '../../features/orchestrator/presentation/orchestrator_task_group_screen.dart';
import '../../features/orchestrator/presentation/orchestrator_step_guide_screen.dart';

GoRouter createAppRouter(AuthRedirectNotifier authRedirectNotifier) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authRedirectNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final hasToken = AuthTokenStore.instance.getToken()?.isNotEmpty ?? false;
      final isMfaPending = AuthTokenStore.instance.isMfaPending;
      final isLogin = state.matchedLocation == '/login';
      final isMfa = state.matchedLocation == '/mfa';
      final isAcceptInvite = state.matchedLocation == '/accept-invite';

      // /properties removed — redirect to dashboard
      if (state.matchedLocation == '/properties') return '/dashboard';

      // Not authenticated → force login (allow public invite acceptance)
      if (!hasToken && !isLogin && !isAcceptInvite) return '/login';

      // Authenticated but MFA not yet verified → force MFA screen
      if (hasToken && isMfaPending && !isMfa) return '/mfa';

      // Fully authenticated → skip login/mfa screens
      if (hasToken && !isMfaPending && (isLogin || isMfa)) return '/dashboard';

      // Role-based route guards (only runs when authenticated and MFA done)
      if (hasToken && !isMfaPending) {
        final role = currentUserRole() ?? 'guest';
        final loc = state.matchedLocation;

        // Only owner/manager can manage team or household members
        if ((loc == '/settings/users' || loc == '/settings/household-members') &&
            role != 'owner' && role != 'manager') {
          return '/unauthorized';
        }

        // Only owner/manager can create operations or access the scan workflow
        if ((loc == '/orchestrator/new' ||
                loc.startsWith('/movements/') && loc.endsWith('/scan')) &&
            role != 'owner' && role != 'manager') {
          return '/unauthorized';
        }

        // Only owner/manager/auditor can access AI chat
        if (loc == '/chat' &&
            role != 'owner' && role != 'manager' && role != 'auditor') {
          return '/unauthorized';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/accept-invite',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return AcceptInviteScreen(token: token);
        },
      ),
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
          final sectionId = state.uri.queryParameters['sectionId'] ?? '';
          final section = state.uri.queryParameters['section'] ?? '';
          return RoomDetailScreen(
            propertyId: propertyId,
            roomId: roomId,
            roomName: roomName,
            initialSection: section.isNotEmpty ? section : null,
            initialSectionId: sectionId.isNotEmpty ? sectionId : null,
          );
        },
      ),
      // Route used when navigating from a section QR scan — no propertyId known
      GoRoute(
        path: '/rooms/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          final roomName = state.uri.queryParameters['name'] ?? '';
          final sectionId = state.uri.queryParameters['sectionId'] ?? '';
          final section = state.uri.queryParameters['section'] ?? '';
          return RoomDetailScreen(
            propertyId: '',
            roomId: roomId,
            roomName: roomName.isNotEmpty ? roomName : 'Section',
            initialSection: section.isNotEmpty ? section : null,
            initialSectionId: sectionId.isNotEmpty ? sectionId : null,
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
        path: '/assets',
        builder: (context, state) => const AssetBrowserScreen(),
      ),
      GoRoute(
        path: '/qr-codes',
        builder: (context, state) {
          final extra = state.extra;
          final items = extra is List<ItemModel> ? extra : null;
          return QrListScreen(items: items);
        },
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
        path: '/wardrobe/at-laundry',
        builder: (context, state) => const AtLaundryScreen(),
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
        path: '/settings/household-members',
        builder: (context, state) => const HouseholdMembersScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterPage(),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (context, state) => const NotificationPreferencesPage(),
      ),
      GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => const MaintenanceListScreen(),
      ),
      GoRoute(
        path: '/maintenance/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final record = state.extra;
          return MaintenanceDetailScreen(
            maintenanceId: id,
            initialRecord: record is MaintenanceModel ? record : null,
          );
        },
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
      // ── AI Scan routes ─────────────────────────────────────────────────────
      GoRoute(
        path: '/properties/:propertyId/ai-scan',
        builder: (context, state) {
          final propertyId = state.pathParameters['propertyId'] ?? '';
          final floors = (state.extra as List<FloorModel>?) ?? [];
          return AiScanScreen(propertyId: propertyId, floors: floors);
        },
      ),
      GoRoute(
        path: '/properties/:propertyId/ai-scan/review',
        builder: (context, state) {
          final propertyId = state.pathParameters['propertyId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final result = extra?['result'] as AiScanResult;
          final floors = (extra?['floors'] as List<FloorModel>?) ?? [];
          return AiItemReviewScreen(
            propertyId: propertyId,
            result: result,
            floors: floors,
          );
        },
      ),
      // ── Insurance routes ───────────────────────────────────────────────────
      GoRoute(
        path: '/insurance',
        builder: (context, state) => const InsuranceListScreen(),
      ),
      GoRoute(
        path: '/insurance/new',
        builder: (context, state) => const InsuranceFormScreen(),
      ),
      GoRoute(
        path: '/insurance/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return InsuranceDetailScreen(policyId: id);
        },
      ),
      GoRoute(
        path: '/insurance/:id/edit',
        builder: (context, state) {
          final policy = state.extra as dynamic;
          return InsuranceFormScreen(policy: policy);
        },
      ),
      GoRoute(
        path: '/insurance/:id/gaps',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CoverageGapsScreen(policyId: id);
        },
      ),
      GoRoute(
        path: '/insurance/:id/claim-draft',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ClaimDraftScreen(policyId: id);
        },
      ),
      // ── Orchestrator routes ────────────────────────────────────────────────
      GoRoute(
        path: '/orchestrator',
        builder: (context, state) => const OrchestratorListScreen(),
      ),
      GoRoute(
        path: '/orchestrator/new',
        builder: (context, state) => const OrchestratorNewCommandScreen(),
      ),
      GoRoute(
        path: '/orchestrator/review',
        builder: (context, state) {
          final parsed = state.extra as ParsedPlanModel;
          return OrchestratorPlanReviewScreen(parsed: parsed);
        },
      ),
      GoRoute(
        path: '/orchestrator/plans/:id',
        builder: (context, state) => OrchestratorPlanDetailScreen(
          planId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/orchestrator/plans/:id/progress',
        builder: (context, state) => OrchestratorProgressDashboardScreen(
          planId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/orchestrator/plans/:planId/groups/:groupId',
        builder: (context, state) => OrchestratorTaskGroupScreen(
          planId: state.pathParameters['planId']!,
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: '/orchestrator/plans/:planId/groups/:groupId/steps/:stepId',
        builder: (context, state) => OrchestratorStepGuideScreen(
          planId: state.pathParameters['planId']!,
          groupId: state.pathParameters['groupId']!,
          stepId: state.pathParameters['stepId']!,
        ),
      ),
      GoRoute(
        path: '/unauthorized',
        builder:
            (context, state) => Scaffold(
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
