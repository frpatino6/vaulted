import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../users/domain/current_user_jwt.dart';
import '../data/models/movement_model.dart';
import '../domain/movement_detail_notifier.dart';
import '../domain/movement_list_notifier.dart';
import 'movements_screen.dart' show movementTypeInfo, movementStatusInfo;
import 'movement_checkin_screen.dart';

class MovementDetailScreen extends ConsumerStatefulWidget {
  const MovementDetailScreen({super.key, required this.movementId});

  final String movementId;

  @override
  ConsumerState<MovementDetailScreen> createState() =>
      _MovementDetailScreenState();
}

class _MovementDetailScreenState
    extends ConsumerState<MovementDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(movementDetailNotifierProvider.notifier)
          .load(widget.movementId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(movementDetailNotifierProvider);
    final role = currentUserRole() ?? 'guest';
    final canOperate = role == 'owner' || role == 'manager';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: state.when(
        data: (movement) {
          if (movement == null) {
            return Center(
              child: Text('Movement not found',
                  style: TextStyle(color: AppColors.onSurfaceVariant)),
            );
          }
          return _buildContent(context, movement, canOperate);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.accent, strokeWidth: 2),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 40),
              const SizedBox(height: AppSpacing.sm),
              Text(MovementDetailNotifier.message(e),
                  style: TextStyle(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => ref
                    .read(movementDetailNotifierProvider.notifier)
                    .load(widget.movementId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, MovementModel movement, bool canOperate) {
    final typeInfo = movementTypeInfo(movement.operationType);
    final statusInfo = movementStatusInfo(movement.status);
    final isActive = movement.isActive;
    final isDraft = movement.isDraft;

    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          backgroundColor: AppColors.background,
          pinned: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.onBackground, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Row(
            children: [
              Icon(typeInfo.icon, color: typeInfo.color, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  movement.title,
                  style: TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            if (canOperate && !movement.isFinished)
              PopupMenuButton<String>(
                color: AppColors.surfaceVariant,
                icon: Icon(Icons.more_vert_rounded,
                    color: AppColors.onBackground),
                onSelected: (v) => _handleMenu(context, v, movement),
                itemBuilder: (_) => [
                  if (isDraft)
                    PopupMenuItem(
                      value: 'resume',
                      child: Row(
                        children: [
                          Icon(Icons.qr_code_scanner_rounded,
                              color: AppColors.accent, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Resume scanning',
                              style:
                                  TextStyle(color: AppColors.onBackground)),
                        ],
                      ),
                    ),
                  if (isActive)
                    PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: AppColors.accent, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Mark as complete',
                              style:
                                  TextStyle(color: AppColors.onBackground)),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel_outlined,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Cancel operation',
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                _HeaderCard(movement: movement, statusInfo: statusInfo),

                // Progress bar (active only)
                if (isActive) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ProgressCard(
                    movement: movement,
                    canOperate: canOperate,
                    onCheckin: () => _openCheckin(context, movement),
                  ),
                ],

                // Items section
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'ITEMS (${movement.items.length})',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),

        // Items list
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, 120),
          sliver: movement.items.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Text(
                        'No items in this operation',
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ItemCard(item: movement.items[i]),
                    ),
                    childCount: movement.items.length,
                  ),
                ),
        ),
      ],
    );
  }

  void _openCheckin(BuildContext context, MovementModel movement) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MovementCheckinScreen(movementId: movement.id),
    ).then((_) {
      ref
          .read(movementDetailNotifierProvider.notifier)
          .load(widget.movementId);
      ref.read(movementListNotifierProvider.notifier).load();
    });
  }

  void _handleMenu(
      BuildContext context, String action, MovementModel movement) async {
    switch (action) {
      case 'resume':
        context.push('/movements/${movement.id}/scan');
      case 'complete':
        _confirmComplete(context, movement);
      case 'cancel':
        _confirmCancel(context, movement);
    }
  }

  void _confirmComplete(BuildContext context, MovementModel movement) async {
    final pending = movement.outCount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: Text('Complete operation?',
            style: TextStyle(color: AppColors.onBackground)),
        content: Text(
          pending > 0
              ? '$pending item(s) haven\'t been checked in. They will be marked as MISSING.'
              : 'All items accounted for. Mark as complete?',
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  pending > 0 ? AppColors.error : AppColors.accent,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(movementDetailNotifierProvider.notifier).complete();
        ref.read(movementListNotifierProvider.notifier).load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(MovementDetailNotifier.message(e)),
            backgroundColor: AppColors.error,
          ));
        }
      }
    }
  }

  void _confirmCancel(BuildContext context, MovementModel movement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: Text('Cancel operation?',
            style: TextStyle(color: AppColors.onBackground)),
        content: Text(
          movement.isActive
              ? 'Active items will be restored to their previous status.'
              : 'The draft will be permanently cancelled.',
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Keep',
                style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Cancel operation',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(movementDetailNotifierProvider.notifier).cancel();
        ref.read(movementListNotifierProvider.notifier).load();
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(MovementDetailNotifier.message(e)),
            backgroundColor: AppColors.error,
          ));
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  const _HeaderCard(
      {required this.movement, required this.statusInfo});

  final MovementModel movement;
  final dynamic statusInfo;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, y');
    String? fmtDate(String? iso) {
      if (iso == null) return null;
      try {
        return fmt.format(DateTime.parse(iso));
      } catch (_) {
        return null;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (movement.destination.isNotEmpty)
                      _InfoRow(
                          icon: Icons.place_outlined,
                          text: movement.destination),
                    if (movement.description.isNotEmpty)
                      _InfoRow(
                          icon: Icons.notes_rounded,
                          text: movement.description),
                    if (movement.dueDate != null)
                      _InfoRow(
                          icon: Icons.event_outlined,
                          text:
                              'Due ${fmtDate(movement.dueDate) ?? movement.dueDate!}',
                          color: AppColors.accent),
                    if (fmtDate(movement.createdAt) != null)
                      _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          text: 'Started ${fmtDate(movement.createdAt)!}'),
                    if (movement.isCompleted &&
                        fmtDate(movement.completedAt) != null)
                      _InfoRow(
                          icon: Icons.check_circle_outline,
                          text: 'Completed ${fmtDate(movement.completedAt)!}',
                          color: const Color(0xFF4CAF50)),
                    if (movement.notes.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        movement.notes,
                        style: TextStyle(
                            color: AppColors.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon,
              size: 14,
              color: color ?? AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: color ?? AppColors.onSurface, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.movement,
    required this.canOperate,
    required this.onCheckin,
  });

  final MovementModel movement;
  final bool canOperate;
  final VoidCallback onCheckin;

  @override
  Widget build(BuildContext context) {
    final total = movement.items.length;
    final returned = movement.returnedCount;
    final progress = total > 0 ? returned / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF2196F3).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Check-in Progress',
                style: TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                '$returned / $total returned',
                style: TextStyle(
                    color: AppColors.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF4CAF50)),
              minHeight: 6,
            ),
          ),
          if (movement.missingCount > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.error, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${movement.missingCount} item(s) missing',
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
            ),
          ],
          if (canOperate) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCheckin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text('Scan Check-in',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final MovementItemModel item;

  @override
  Widget build(BuildContext context) {
    final statusColor = _itemStatusColor(item.status);
    final statusLabel = _itemStatusLabel(item.status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: statusColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.itemPhoto.isNotEmpty
                ? Image.network(item.itemPhoto,
                    width: 48, height: 48, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholder())
                : _placeholder(),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: TextStyle(
                      color: AppColors.onBackground,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (item.fromRoomName.isNotEmpty) item.fromRoomName,
                    if (item.fromPropertyName.isNotEmpty)
                      item.fromPropertyName,
                  ].join(' · '),
                  style: TextStyle(
                      color: AppColors.onSurfaceVariant, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.checkedInAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Returned ${_fmt(item.checkedInAt)}',
                    style: TextStyle(
                        color: const Color(0xFF4CAF50), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 48,
        height: 48,
        color: AppColors.surface,
        child: Icon(Icons.inventory_2_outlined,
            size: 22, color: AppColors.onSurfaceVariant),
      );

  String? _fmt(String? iso) {
    if (iso == null) return null;
    try {
      return DateFormat('MMM d, HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return null;
    }
  }
}

Color _itemStatusColor(String status) => switch (status) {
      'returned' => const Color(0xFF4CAF50),
      'missing' => const Color(0xFFCF6679),
      _ => const Color(0xFF2196F3),
    };

String _itemStatusLabel(String status) => switch (status) {
      'returned' => 'RETURNED',
      'missing' => 'MISSING',
      _ => 'OUT',
    };
