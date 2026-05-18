import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/notification_item.dart';
import '../providers/notifications_list_provider.dart';

class NotificationCenterPage extends ConsumerStatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  ConsumerState<NotificationCenterPage> createState() =>
      _NotificationCenterPageState();
}

class _NotificationCenterPageState
    extends ConsumerState<NotificationCenterPage> {
  bool _initialLoadCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(notificationsListProvider.future)
          .whenComplete(() {
        if (mounted) setState(() => _initialLoadCompleted = true);
      });
    });
  }

  Future<void> _markAllRead() async {
    try {
      await ref.read(notificationsListProvider.notifier).markAllRead();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to mark all as read. Try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncPage = ref.watch(notificationsListProvider);

    final showSkeleton = !_initialLoadCompleted &&
        (asyncPage is AsyncLoading || asyncPage is AsyncData);

    final unreadCount =
        asyncPage.whenData((p) => p.unreadCount).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.onBackground,
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onBackground,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (unreadCount > 0 && _initialLoadCompleted)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.accent,
                    ),
              ),
            ),
        ],
      ),
      body: asyncPage.when(
        loading: () => _buildSkeleton(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Could not load notifications.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.onBackground,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: () => ref.invalidate(notificationsListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (page) {
          if (showSkeleton) return _buildSkeleton();

          if (page.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_outlined,
                      size: 64,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No notifications yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.onBackground,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'You\'re all caught up. Alerts for maintenance, '
                      'item updates, and wardrobe reminders will appear here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: page.items.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 0.5,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.15),
              indent: AppSpacing.md,
              endIndent: AppSpacing.md,
            ),
            itemBuilder: (context, index) {
              final item = page.items[index];
              return _NotificationTile(
                item: item,
                onTap: () => _onTileTap(item),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _onTileTap(NotificationItem item) async {
    if (!item.isRead) {
      try {
        await ref.read(notificationsListProvider.notifier).markRead(item.id);
      } catch (_) {
        // Best-effort mark-as-read; proceed with navigation regardless.
      }
    }

    if (!mounted) return;

    switch (item.type) {
      case 'maintenance_due':
        context.push('/maintenance');
      case 'item_added':
        final itemId = item.data?['itemId'] as String?;
        if (itemId != null && itemId.isNotEmpty) {
          context.push('/items/$itemId');
        }
      case 'dry_cleaning_overdue':
        context.push('/wardrobe');
      default:
        break;
    }
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: 8,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.15),
        indent: AppSpacing.md,
        endIndent: AppSpacing.md,
      ),
      itemBuilder: (_, __) => _SkeletonTile(),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification tile
// ---------------------------------------------------------------------------

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
  });

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? AppColors.surfaceVariant.withValues(alpha: 0.6)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread indicator dot
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isUnread
                      ? AppColors.accent
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isUnread
                      ? null
                      : Border.all(
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
                        ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            // Type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isUnread
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconForType(item.type),
                size: 20,
                color: isUnread
                    ? AppColors.accent
                    : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.onBackground,
                                fontWeight: isUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _formatTime(item.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isUnread
                              ? AppColors.onBackground.withValues(alpha: 0.75)
                              : AppColors.onSurfaceVariant,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'maintenance_due':
        return Icons.build_outlined;
      case 'dry_cleaning_overdue':
        return Icons.local_laundry_service_outlined;
      case 'item_added':
        return Icons.add_circle_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}';
  }
}

// ---------------------------------------------------------------------------
// Skeleton tile
// ---------------------------------------------------------------------------

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot placeholder
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          // Icon placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Text placeholders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      width: 40,
                      height: 11,
                      decoration: BoxDecoration(
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 180,
                  decoration: BoxDecoration(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
