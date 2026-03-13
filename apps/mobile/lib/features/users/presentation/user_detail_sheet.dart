import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../properties/domain/properties_notifier.dart';
import '../data/models/user_model.dart';
import '../domain/current_user_jwt.dart';
import '../domain/users_notifier.dart';

const List<String> _editableRoles = ['manager', 'staff', 'auditor', 'guest'];

/// Avatar gradient colors (match list card).
const Color _avatarGradientStart = Color(0xFF2C2C2C);
const Color _avatarGradientEnd = Color(0xFF121212);

/// Bottom sheet to view and edit a team member (role, property access, deactivate).
class UserDetailSheet extends ConsumerStatefulWidget {
  const UserDetailSheet({super.key, required this.user});

  final UserModel user;

  @override
  ConsumerState<UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends ConsumerState<UserDetailSheet> {
  late UserModel _user;
  bool _updating = false;
  final GlobalKey _roleSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  String _formatLastLogin(String? lastLogin) {
    if (lastLogin == null || lastLogin.isEmpty) return 'Never';
    try {
      final dt = DateTime.tryParse(lastLogin);
      if (dt == null) return 'Never';
      return 'Last seen: ${DateFormat('MMM d, y').format(dt)}';
    } catch (_) {
      return 'Never';
    }
  }

  Future<void> _updateRole(String newRole) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      await ref.read(usersNotifierProvider.notifier).updateUser(
            _user.id,
            role: newRole,
          );
      final newState = ref.read(usersNotifierProvider);
      if (newState.value != null) {
        for (final u in newState.value!) {
          if (u.id == _user.id && mounted) {
            setState(() => _user = u);
            break;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(UsersNotifier.message(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _updatePropertyIds(List<String> propertyIds) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      await ref.read(usersNotifierProvider.notifier).updateUser(
            _user.id,
            propertyIds: propertyIds,
          );
      final newState = ref.read(usersNotifierProvider);
      if (newState.value != null) {
        for (final u in newState.value!) {
          if (u.id == _user.id && mounted) {
            setState(() => _user = u);
            break;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(UsersNotifier.message(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _deactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate user'),
        content: Text(
          'Deactivate ${_user.email}? They will no longer be able to sign in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _updating = true);
    try {
      await ref.read(usersNotifierProvider.notifier).deactivateUser(_user.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deactivated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(UsersNotifier.message(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = currentUserRole();
    final currentId = currentUserId();
    final isOwner = currentRole == 'owner';
    final isSelf = currentId != null && currentId == _user.id;
    final isUserOwner = _user.role.toLowerCase() == 'owner';
    final canChangeRole = isOwner && !isSelf && !isUserOwner;
    final showPropertyAccess =
        (_user.role == 'staff' || _user.role == 'auditor') && !isUserOwner;
    final canDeactivate = isOwner && !isSelf && !isUserOwner;

    final propertiesState = ref.watch(propertiesNotifierProvider);
    final properties = propertiesState.valueOrNull ?? [];
    final selectedIds = Set<String>.from(_user.propertyIds);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.catalogGold.withValues(alpha: 0.85),
                    width: 2,
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_avatarGradientStart, _avatarGradientEnd],
                  ),
                ),
                child: Center(
                  child: Text(
                    _user.email.isNotEmpty
                        ? _user.email[0].toUpperCase()
                        : '?',
                    style: AppTypography.displaySerif.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                _user.email,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onBackground,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                _formatLastLogin(_user.lastLogin),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 12,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _user.status.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ),
            ),
            if (canChangeRole) ...[
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: _updating
                      ? null
                      : () {
                          final ctx = _roleSectionKey.currentContext;
                          if (ctx != null) {
                            Scrollable.ensureVisible(ctx);
                          }
                        },
                  child: Text(
                    'Edit Role',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.catalogGold,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (canChangeRole) ...[
              Text(
                'Role',
                key: _roleSectionKey,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.accent,
                      letterSpacing: 1,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<String>(
                segments: _editableRoles
                    .map(
                      (r) => ButtonSegment<String>(
                        value: r,
                        label: Text(r[0].toUpperCase() + r.substring(1)),
                      ),
                    )
                    .toList(),
                selected: {_user.role.toLowerCase()},
                onSelectionChanged: (selected) {
                  final value = selected.first;
                  if (value != _user.role.toLowerCase()) _updateRole(value);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (showPropertyAccess) ...[
              Text(
                'Property Access',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.accent,
                      letterSpacing: 1,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...properties.map(
                (p) => CheckboxListTile(
                  value: selectedIds.contains(p.id),
                  onChanged: _updating
                      ? null
                      : (checked) {
                          final next = Set<String>.from(selectedIds);
                          if (checked == true) {
                            next.add(p.id);
                          } else {
                            next.remove(p.id);
                          }
                          _updatePropertyIds(next.toList());
                        },
                  title: Text(
                    p.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onBackground,
                        ),
                  ),
                  activeColor: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (canDeactivate) ...[
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _updating
                      ? null
                      : () => _deactivate(),
                  icon: const Icon(Icons.person_off_outlined, size: 20),
                  label: const Text('Deactivate user'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: TextButton(
                onPressed: (canDeactivate && !_updating) ? () => _deactivate() : null,
                child: Text(
                  'Revoke Access',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: canDeactivate
                            ? Colors.redAccent.withValues(alpha: 0.8)
                            : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
