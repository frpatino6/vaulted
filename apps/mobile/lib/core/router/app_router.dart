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
import '../../features/ai_help_chat/presentation/help_chat_screen.dart';
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
import '../../features/insurance/data/models/insurance_policy_model.dart';
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

Page<void> _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

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

        // Wardrobe is owner/manager only
        if (loc.startsWith('/wardrobe') &&
            role != 'owner' && role != 'manager') {
          return '/unauthorized';
        }

        // Insurance list/detail/gaps: owner/manager/auditor
        if (loc.startsWith('/insurance') &&
            role != 'owner' && role != 'manager' && role != 'auditor') {
          return '/unauthorized';
        }

        // Insurance create/edit/claim-draft: owner/manager only
        if ((loc == '/insurance/new' ||
                loc.endsWith('/edit') ||
                loc.endsWith('/claim-draft')) &&
            role != 'owner' && role != 'manager') {
          return '/unauthorized';
        }

        // Maintenance list: owner/manager/staff only (auditor uses per-item endpoint)
        if (loc == '/maintenance' &&
            role != 'owner' && role != 'manager' && role != 'staff') {
          return '/unauthorized';
        }

        // AI Scan is owner/manager only
        if (loc.contains('/ai-scan') &&
            role != 'owner' && role != 'manager') {
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
        pageBuilder: (context, state) => _fadePage(const DashboardScreen(), state),
      ),
      GoRoute(
        path: '/properties/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _fadePage(PropertyDetailScreen(propertyId: id), state);
        },
      ),
      GoRoute(
        path: '/properties/:propertyId/rooms/:roomId',
        pageBuilder: (context, state) {
          final propertyId = state.pathParameters['propertyId'] ?? '';
          final roomId = state.pathParameters['roomId'] ?? '';
          final roomName = state.uri.queryParameters['name'] ?? '';
          final sectionId = state.uri.queryParameters['sectionId'] ?? '';
          final section = state.uri.queryParameters['section'] ?? '';
          return _fadePage(RoomDetailScreen(
            propertyId: propertyId,
            roomId: roomId,
            roomName: roomName,
            initialSection: section.isNotEmpty ? section : null,
            initialSectionId: sectionId.isNotEmpty ? sectionId : null,
          ), state);
        },
      ),
      // Route used when navigating from a section QR scan — no propertyId known
      GoRoute(
        path: '/rooms/:roomId',
        pageBuilder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          final roomName = state.uri.queryParameters['name'] ?? '';
          final sectionId = state.uri.queryParameters['sectionId'] ?? '';
          final section = state.uri.queryParameters['section'] ?? '';
          return _fadePage(RoomDetailScreen(
            propertyId: '',
            roomId: roomId,
            roomName: roomName.isNotEmpty ? roomName : 'Section',
            initialSection: section.isNotEmpty ? section : null,
            initialSectionId: sectionId.isNotEmpty ? sectionId : null,
          ), state);
        },
      ),
      GoRoute(
        path: '/items/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _fadePage(ItemDetailScreen(itemId: id), state);
        },
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => _fadePage(const SearchScreen(), state),
      ),
      GoRoute(
        path: '/assets',
        pageBuilder: (context, state) => _fadePage(AssetBrowserScreen(
          initialStatus: state.uri.queryParameters['status'],
        ), state),
      ),
      GoRoute(
        path: '/qr-codes',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final items = extra is List<ItemModel> ? extra : null;
          return _fadePage(QrListScreen(items: items), state);
        },
      ),
      GoRoute(
        path: '/scanner',
        pageBuilder: (context, state) => _fadePage(const QrScannerScreen(), state),
      ),
      GoRoute(
        path: '/reports',
        pageBuilder: (context, state) => _fadePage(const ReportsScreen(), state),
      ),
      GoRoute(
        path: '/wardrobe',
        pageBuilder: (context, state) => _fadePage(const WardrobeScreen(), state),
      ),
      GoRoute(
        path: '/wardrobe/at-laundry',
        pageBuilder: (context, state) => _fadePage(const AtLaundryScreen(), state),
      ),
      GoRoute(
        path: '/wardrobe/outfits',
        pageBuilder: (context, state) => _fadePage(const OutfitListScreen(), state),
      ),
      GoRoute(
        path: '/wardrobe/outfits/new',
        pageBuilder: (context, state) => _fadePage(const CreateOutfitScreen(), state),
      ),
      GoRoute(
        path: '/wardrobe/outfits/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _fadePage(OutfitDetailScreen(outfitId: id), state);
        },
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _fadePage(const SettingsScreen(), state),
      ),
      GoRoute(
        path: '/settings/users',
        pageBuilder: (context, state) => _fadePage(const UsersScreen(), state),
      ),
      GoRoute(
        path: '/settings/household-members',
        pageBuilder: (context, state) => _fadePage(const HouseholdMembersScreen(), state),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => _fadePage(const NotificationCenterPage(), state),
      ),
      GoRoute(
        path: '/settings/notifications',
        pageBuilder: (context, state) => _fadePage(const NotificationPreferencesPage(), state),
      ),
      GoRoute(
        path: '/chat',
        pageBuilder: (context, state) => _fadePage(const ChatScreen(), state),
      ),
      GoRoute(
        path: '/help-chat',
        pageBuilder: (context, state) {
          final currentScreen = state.uri.queryParameters['screen'];
          final initialQuery = state.uri.queryParameters['ask'];
          return _fadePage(HelpChatScreen(
            currentScreen: currentScreen,
            initialQuery: initialQuery,
          ), state);
        },
      ),
      GoRoute(
        path: '/maintenance',
        pageBuilder: (context, state) => _fadePage(const MaintenanceListScreen(), state),
      ),
      GoRoute(
        path: '/maintenance/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final record = state.extra;
          return _fadePage(MaintenanceDetailScreen(
            maintenanceId: id,
            initialRecord: record is MaintenanceModel ? record : null,
          ), state);
        },
      ),
      GoRoute(
        path: '/movements',
        pageBuilder: (context, state) => _fadePage(const MovementsScreen(), state),
      ),
      GoRoute(
        path: '/movements/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _fadePage(MovementDetailScreen(movementId: id), state);
        },
      ),
      GoRoute(
        path: '/movements/:id/scan',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _fadePage(MovementScanScreen(movementId: id), state);
        },
      ),
      // ── AI Scan routes ─────────────────────────────────────────────────────
      GoRoute(
        path: '/properties/:propertyId/ai-scan',
        pageBuilder: (context, state) {
          final propertyId = state.pathParameters['propertyId'] ?? '';
          final floors = (state.extra as List<FloorModel>?) ?? [];
          return _fadePage(AiScanScreen(propertyId: propertyId, floors: floors), state);
        },
      ),
      GoRoute(
        path: '/properties/:propertyId/ai-scan/review',
        redirect: (context, state) {
          final propertyId = state.pathParameters['propertyId'] ?? '';
          final extra = state.extra;
          if (extra is! Map<String, dynamic> || extra['result'] is! AiScanResult) {
            return '/properties/$propertyId/ai-scan';
          }
          return null;
        },
        pageBuilder: (context, state) {
          final propertyId = state.pathParameters['propertyId'] ?? '';
          final extra = state.extra as Map<String, dynamic>;
          final result = extra['result'] as AiScanResult;
          final floors = (extra['floors'] as List<FloorModel>?) ?? [];
          return _fadePage(AiItemReviewScreen(
            propertyId: propertyId,
            result: result,
            floors: floors,
          ), state);
        },
      ),
      // ── Insurance routes ───────────────────────────────────────────────────
      GoRoute(
        path: '/insurance',
        pageBuilder: (context, state) => _fadePage(const InsuranceListScreen(), state),
      ),
      GoRoute(
        path: '/insurance/new',
        pageBuilder: (context, state) => _fadePage(const InsuranceFormScreen(), state),
      ),
      GoRoute(
        path: '/insurance/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _fadePage(InsuranceDetailScreen(policyId: id), state);
        },
      ),
      GoRoute(
        path: '/insurance/:id/edit',
        pageBuilder: (context, state) {
          final policy = state.extra as InsurancePolicyModel?;
          return _fadePage(InsuranceFormScreen(policy: policy), state);
        },
      ),
      GoRoute(
        path: '/insurance/:id/gaps',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _fadePage(CoverageGapsScreen(policyId: id), state);
        },
      ),
      GoRoute(
        path: '/insurance/:id/claim-draft',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _fadePage(ClaimDraftScreen(policyId: id), state);
        },
      ),
      // ── Orchestrator routes ────────────────────────────────────────────────
      GoRoute(
        path: '/orchestrator',
        pageBuilder: (context, state) => _fadePage(const OrchestratorListScreen(), state),
      ),
      GoRoute(
        path: '/orchestrator/new',
        pageBuilder: (context, state) => _fadePage(const OrchestratorNewCommandScreen(), state),
      ),
      GoRoute(
        path: '/orchestrator/review',
        redirect: (context, state) {
          return state.extra is ParsedPlanModel ? null : '/orchestrator';
        },
        pageBuilder: (context, state) {
          final parsed = state.extra as ParsedPlanModel;
          return _fadePage(OrchestratorPlanReviewScreen(parsed: parsed), state);
        },
      ),
      GoRoute(
        path: '/orchestrator/plans/:id',
        pageBuilder: (context, state) => _fadePage(OrchestratorPlanDetailScreen(
          planId: state.pathParameters['id']!,
        ), state),
      ),
      GoRoute(
        path: '/orchestrator/plans/:id/progress',
        pageBuilder: (context, state) => _fadePage(OrchestratorProgressDashboardScreen(
          planId: state.pathParameters['id']!,
        ), state),
      ),
      GoRoute(
        path: '/orchestrator/plans/:planId/groups/:groupId',
        pageBuilder: (context, state) => _fadePage(OrchestratorTaskGroupScreen(
          planId: state.pathParameters['planId']!,
          groupId: state.pathParameters['groupId']!,
        ), state),
      ),
      GoRoute(
        path: '/orchestrator/plans/:planId/groups/:groupId/steps/:stepId',
        pageBuilder: (context, state) => _fadePage(OrchestratorStepGuideScreen(
          planId: state.pathParameters['planId']!,
          groupId: state.pathParameters['groupId']!,
          stepId: state.pathParameters['stepId']!,
        ), state),
      ),
      GoRoute(
        path: '/unauthorized',
        pageBuilder: (context, state) => _fadePage(Scaffold(
          body: Center(
            child: Text('Unauthorized', style: Theme.of(context).textTheme.titleLarge),
          ),
        ), state),
      ),
    ],
  );
}
