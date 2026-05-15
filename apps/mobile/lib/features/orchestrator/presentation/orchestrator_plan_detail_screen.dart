import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../users/domain/current_user_jwt.dart';
import '../data/models/orchestrator_plan_model.dart';
import '../domain/orchestrator_detail_notifier.dart';

class OrchestratorPlanDetailScreen extends ConsumerStatefulWidget {
  const OrchestratorPlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<OrchestratorPlanDetailScreen> createState() =>
      _OrchestratorPlanDetailScreenState();
}

class _OrchestratorPlanDetailScreenState
    extends ConsumerState<OrchestratorPlanDetailScreen> {
  bool _initialLoadCompleted = false;
  bool _publishing = false;
  bool _cancelling = false;

  String get _role => currentUserRole() ?? 'guest';
  bool get _isOwnerOrManager => _role == 'owner' || _role == 'manager';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(orchestratorDetailNotifierProvider.notifier)
          .load(widget.planId)
          .whenComplete(() {
        if (!mounted) return;
        setState(() => _initialLoadCompleted = true);
      });
    });
  }

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() => _publishing = true);
    try {
      await ref
          .read(orchestratorDetailNotifierProvider.notifier)
          .publish();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan published — staff notified!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(OrchestratorDetailNotifier.errorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: const Text('Cancel Plan'),
        content: const Text(
          'This plan will be marked cancelled and cannot be reactivated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Plan'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await ref
          .read(orchestratorDetailNotifierProvider.notifier)
          .cancel();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan cancelled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(OrchestratorDetailNotifier.errorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orchestratorDetailNotifierProvider);
    final showInitialSkeleton = !_initialLoadCompleted &&
        !state.hasError &&
        (state.isLoading || state.valueOrNull == null);
    final renderState =
        showInitialSkeleton ? const AsyncLoading<OrchestratorPlanModel?>() : state;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: renderState.when(
        loading: () => const AppScreenSkeleton(showHeader: true, cardCount: 4),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 40),
              const SizedBox(height: AppSpacing.sm),
              Text(
                OrchestratorDetailNotifier.errorMessage(e),
                style: const TextStyle(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => ref
                    .read(orchestratorDetailNotifierProvider.notifier)
                    .load(widget.planId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (plan) {
          if (plan == null) {
            return const Center(
              child: Text(
                'Plan not found',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            );
          }
          return _buildContent(context, plan);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, OrchestratorPlanModel plan) {
    final statusInfo = _planStatusInfo(plan.status);
    final progress = plan.percentComplete;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.onBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            plan.title,
            style: const TextStyle(
              color: AppColors.onBackground,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (_isOwnerOrManager && !plan.isCancelled)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.onBackground),
                color: AppColors.surfaceVariant,
                onSelected: (v) {
                  if (v == 'cancel') _cancel();
                  if (v == 'progress') {
                    context.push('/orchestrator/plans/${plan.id}/progress');
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'progress',
                    child: Row(
                      children: [
                        Icon(Icons.bar_chart_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Live Progress'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text(
                          'Cancel Plan',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + date row
                Row(
                  children: [
                    _StatusBadge(status: plan.status),
                    const SizedBox(width: AppSpacing.sm),
                    if (plan.targetDate != null) ...[
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(plan.targetDate),
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // AI summary
                if (plan.aiSummary.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border(
                        left: BorderSide(
                          color: AppColors.accent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      plan.aiSummary,
                      style: const TextStyle(
                        color: AppColors.onBackground,
                        fontSize: 14,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                // Overall progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'OVERALL PROGRESS',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: statusInfo.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor:
                        AppColors.onSurfaceVariant.withValues(alpha: 0.15),
                    color: statusInfo.color,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${plan.completedSteps} of ${plan.totalSteps} steps completed',
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Task groups header
                const Text(
                  'TASK GROUPS',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
        // Task group list
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final group = plan.taskGroups[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _TaskGroupCard(
                    group: group,
                    onTap: () => context.push(
                      '/orchestrator/plans/${plan.id}/groups/${group.groupId}',
                    ),
                  ),
                );
              },
              childCount: plan.taskGroups.length,
            ),
          ),
        ),
        // Publish button if draft
        if (plan.isDraft && _isOwnerOrManager)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _publishing ? null : _publish,
                  icon: _publishing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background,
                          ),
                        )
                      : const Icon(Icons.publish_rounded),
                  label: const Text('Publish Plan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return DateFormat('MMM d, yyyy').format(dt);
  }
}

// ---------------------------------------------------------------------------
// Task group card
// ---------------------------------------------------------------------------

class _TaskGroupCard extends StatelessWidget {
  const _TaskGroupCard({required this.group, required this.onTap});

  final OrchestratorTaskGroupModel group;
  final VoidCallback onTap;

  String get _initials {
    final name = group.assignedUserName ?? '';
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final done = group.completedSteps;
    final total = group.totalSteps;
    final progress = total == 0 ? 0.0 : done / total;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: group.assignedUserName != null
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.1),
                child: Text(
                  _initials,
                  style: TextStyle(
                    color: group.assignedUserName != null
                        ? AppColors.accent
                        : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.title,
                            style: const TextStyle(
                              color: AppColors.onBackground,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _GroupStatusChip(status: group.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.assignedUserName ?? 'Unassigned',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.onSurfaceVariant
                                  .withValues(alpha: 0.15),
                              color: AppColors.accent,
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '$done/$total',
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reused status helpers
// ---------------------------------------------------------------------------

class _StatusInfo {
  const _StatusInfo(this.color, this.label);
  final Color color;
  final String label;
}

_StatusInfo _planStatusInfo(String status) {
  switch (status) {
    case 'published':
      return const _StatusInfo(Color(0xFF2196F3), 'Published');
    case 'in_progress':
      return const _StatusInfo(Color(0xFFE07B39), 'In Progress');
    case 'completed':
      return const _StatusInfo(Color(0xFF6DB86F), 'Completed');
    case 'cancelled':
      return const _StatusInfo(Color(0xFF9E9E9E), 'Cancelled');
    default:
      return const _StatusInfo(Color(0xFF8A8AA8), 'Draft');
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final info = _planStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          color: info.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GroupStatusChip extends StatelessWidget {
  const _GroupStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'in_progress':
        color = const Color(0xFFE07B39);
        label = 'In Progress';
        break;
      case 'completed':
        color = const Color(0xFF6DB86F);
        label = 'Done';
        break;
      default:
        color = const Color(0xFF8A8AA8);
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
