import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/privacy/privacy_mode_provider.dart';
import '../../../../core/storage/auth_token_store.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/auth_notifier.dart';
import '../../../notifications/presentation/providers/notifications_list_provider.dart';
import '../../../users/domain/current_user_jwt.dart';

/// Persistent dashboard header: "Welcome back," greeting, serif display name,
/// privacy toggle, and profile avatar that opens the user menu.
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = _emailFromJwt() ?? '';
    final role = currentUserRole() ?? 'guest';
    final displayName = _displayName();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome back,',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: AppTypography.displaySerif.copyWith(
                    color: AppColors.onBackground,
                  ),
                ),
              ],
            ),
          ),
          const _PrivacyToggleButton(),
          const SizedBox(width: 4),
          Consumer(
            builder: (context, ref, _) {
              final unread = ref.watch(unreadNotificationsCountProvider);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    iconSize: 22,
                    tooltip: 'Notifications',
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onPressed: () => context.push('/notifications'),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: GestureDetector(
                onTap: () => _showUserMenu(context, ref, email, role),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _displayName() {
    final token = AuthTokenStore.instance.getToken();
    if (token == null) return 'My Vault';
    final parts = token.split('.');
    if (parts.length != 3) return 'My Vault';
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      final name = decoded['name'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        final first = name.trim().split(' ').first;
        if (first.isNotEmpty) return first[0].toUpperCase() + first.substring(1);
      }
      final email = decoded['email'] as String?;
      final displayName = _displayNameFromEmail(email);
      if (displayName != null) return displayName;
    } catch (_) {}
    return 'My Vault';
  }

  String? _displayNameFromEmail(String? email) {
    if (email == null || email.trim().isEmpty) return null;
    final localPart = email.trim().split('@').first;
    if (localPart.isEmpty) return null;
    return localPart[0].toUpperCase() + localPart.substring(1);
  }

  String? _emailFromJwt() {
    final token = AuthTokenStore.instance.getToken();
    if (token == null) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      return jsonDecode(payload)['email'] as String?;
    } catch (_) {
      return null;
    }
  }

  void _showUserMenu(
    BuildContext context,
    WidgetRef ref,
    String email,
    String role,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withValues(alpha: 0.15),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            email.isNotEmpty ? email[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email,
                              style: Theme.of(ctx).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.onBackground,
                                    fontWeight: FontWeight.w500,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              role.isNotEmpty
                                  ? role[0].toUpperCase() + role.substring(1)
                                  : '',
                              style: Theme.of(ctx).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(color: Colors.white10),
                  ListTile(
                    leading: Icon(
                      Icons.build_circle_outlined,
                      color: AppColors.onSurfaceVariant,
                    ),
                    title: Text(
                      'Maintenance',
                      style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                        color: AppColors.onBackground,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push('/maintenance');
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.settings_outlined,
                      color: AppColors.onSurfaceVariant,
                    ),
                    title: Text(
                      'Settings',
                      style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                        color: AppColors.onBackground,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push('/settings');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, color: AppColors.error),
                    title: Text(
                      'Sign out',
                      style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await ref.read(authNotifierProvider.notifier).logout();
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class _PrivacyToggleButton extends ConsumerWidget {
  const _PrivacyToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPrivate = ref.watch(privacyModeProvider).valueOrNull ?? false;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          iconSize: 20,
          icon: Icon(
            isPrivate
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: isPrivate ? AppColors.accent : AppColors.onSurfaceVariant,
          ),
          tooltip: isPrivate ? 'Values hidden — tap to show' : 'Hide values',
          onPressed: () {
            HapticFeedback.selectionClick();
            ref.read(privacyModeProvider.notifier).toggle();
          },
        ),
        if (isPrivate)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.backgroundElevated,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
