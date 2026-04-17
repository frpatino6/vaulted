import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../data/models/user_model.dart';
import '../domain/current_user_jwt.dart';
import '../domain/users_notifier.dart';
import 'invite_user_sheet.dart';
import 'user_detail_sheet.dart';

/// Team members list with invite and detail sheets.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  static Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return AppColors.accent;
      case 'manager':
        return Colors.blue;
      case 'staff':
        return Colors.green;
      case 'auditor':
        return Colors.purple;
      case 'guest':
        return AppColors.onSurfaceVariant;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  /// Derives a display name from email (e.g. fernando@x.com → Fernando).
  static String _displayNameFromEmail(String email) {
    if (email.isEmpty) return 'Member';
    final part = email.split('@').first;
    if (part.isEmpty) return 'Member';
    return part[0].toUpperCase() + part.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersState = ref.watch(usersNotifierProvider);
    final currentRole = currentUserRole();
    final canInvite = currentRole == 'owner' || currentRole == 'manager';
    final canOpenDetail = currentRole == 'owner' || currentRole == 'manager';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Team',
          style: AppTypography.displaySerif.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.onBackground,
          ),
        ),
        actions: [
          if (canInvite)
            IconButton(
              icon: const Icon(
                Icons.person_add_outlined,
                color: AppColors.catalogGold,
              ),
              onPressed: () => _openInviteSheet(context),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(usersNotifierProvider.notifier).refresh(),
        color: AppColors.accent,
        child: usersState.when(
          data: (users) {
            if (users.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: Center(
                      child: Text(
                        'No team members yet. Invite someone.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Text(
                      'Only authorized members can access vault data.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: users.length + 1,
              itemBuilder: (context, index) {
                if (index == users.length) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.lg,
                      bottom: AppSpacing.xl,
                    ),
                    child: Center(
                      child: Text(
                        'Only authorized members can access vault data.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: 0.8,
                          ),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final user = users[index];
                final initial =
                    user.email.isNotEmpty ? user.email[0].toUpperCase() : '?';
                final roleColor = _roleColor(user.role);
                return _TeamMemberCard(
                  user: user,
                  displayName: _displayNameFromEmail(user.email),
                  initial: initial,
                  roleColor: roleColor,
                  canTap: canOpenDetail,
                  onTap: () => _openUserDetailSheet(context, user),
                );
              },
            );
          },
          loading: () => const AppScreenSkeleton(showHeader: false),
          error:
              (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        UsersNotifier.message(err),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.background,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed:
                            () =>
                                ref
                                    .read(usersNotifierProvider.notifier)
                                    .refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
  }

  void _openInviteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const InviteUserSheet(),
    );
  }

  void _openUserDetailSheet(BuildContext context, UserModel user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder:
          (context) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  child: UserDetailSheet(user: user),
                ),
              ),
            ],
          ),
    );
  }
}

/// Premium team member card: gradient avatar, name + email, role/status badges.
class _TeamMemberCard extends StatelessWidget {
  const _TeamMemberCard({
    required this.user,
    required this.displayName,
    required this.initial,
    required this.roleColor,
    required this.canTap,
    required this.onTap,
  });

  final UserModel user;
  final String displayName;
  final String initial;
  final Color roleColor;
  final bool canTap;
  final VoidCallback onTap;

  static const Color _avatarGradientStart = Color(0xFF2C2C2C);
  static const Color _avatarGradientEnd = Color(0xFF121212);
  static const Color _neonGreen = Color(0xFF39FF14);

  @override
  Widget build(BuildContext context) {
    final isOwner = user.role.toLowerCase() == 'owner';
    final isActive = user.status.toLowerCase() == 'active';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canTap ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: Row(
              children: [
                _buildAvatar(context),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: AppColors.onBackground,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _neonGreen,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _neonGreen.withValues(alpha: 0.6),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.54),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (!isActive && user.status.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.status.toUpperCase(),
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildRoleBadge(context, isOwner),
                if (canTap)
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.catalogGold.withValues(alpha: 0.5),
          width: 1,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_avatarGradientStart, _avatarGradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTypography.displaySerif.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onBackground,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context, bool isOwner) {
    if (isOwner) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.catalogGold.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        child: Text(
          'OWNER',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.catalogGold,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        user.role.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: roleColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
