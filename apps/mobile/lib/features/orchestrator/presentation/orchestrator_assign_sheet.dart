import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../users/data/models/user_model.dart';
import '../../users/domain/users_notifier.dart';

/// Bottom sheet that lets the caller pick an assignee from the active staff/
/// manager list. Returns the selected [UserModel] via [Navigator.pop].
Future<UserModel?> showOrchestratorAssignSheet(BuildContext context) {
  return showModalBottomSheet<UserModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _OrchestratorAssignSheet(),
  );
}

class _OrchestratorAssignSheet extends ConsumerWidget {
  const _OrchestratorAssignSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersState = ref.watch(usersNotifierProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'Assign to Staff',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          usersState.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Could not load users.',
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
            data: (users) {
              final eligible = users
                  .where((u) =>
                      u.isActive &&
                      (u.role == 'staff' || u.role == 'manager'))
                  .toList();

              if (eligible.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Text(
                      'No staff or manager accounts found.',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                );
              }

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: eligible.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
                  ),
                  itemBuilder: (context, i) {
                    final user = eligible[i];
                    return _UserRow(
                      user: user,
                      onTap: () => Navigator.of(context).pop(user),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.onTap});

  final UserModel user;
  final VoidCallback onTap;

  String get _initials {
    final part = user.email.split('@').first;
    if (part.isEmpty) return '?';
    return part.substring(0, part.length.clamp(1, 2)).toUpperCase();
  }

  Color get _roleColor {
    switch (user.role.toLowerCase()) {
      case 'manager':
        return AppColors.info;
      case 'staff':
        return AppColors.statusActive;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.accent.withValues(alpha: 0.15),
              child: Text(
                _initials,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: AppColors.onBackground,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _roleColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                user.role[0].toUpperCase() + user.role.substring(1),
                style: TextStyle(
                  color: _roleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
