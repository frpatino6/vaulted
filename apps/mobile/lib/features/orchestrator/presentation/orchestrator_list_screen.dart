import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../users/domain/current_user_jwt.dart';
import '../data/models/orchestrator_plan_model.dart';
import '../domain/orchestrator_list_notifier.dart';

class OrchestratorListScreen extends ConsumerStatefulWidget {
  const OrchestratorListScreen({super.key});

  @override
  ConsumerState<OrchestratorListScreen> createState() =>
      _OrchestratorListScreenState();
}

class _OrchestratorListScreenState
    extends ConsumerState<OrchestratorListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _initialLoadCompleted = false;

  String get _role => currentUserRole() ?? 'guest';
  bool get _isOwnerOrManager => _role == 'owner' || _role == 'manager';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _isOwnerOrManager ? 2 : 1,
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(orchestratorListNotifierProvider.notifier)
          .load(status: null, propertyId: null)
          .whenComplete(() {
        if (!mounted) return;
        setState(() => _initialLoadCompleted = true);
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allState = ref.watch(orchestratorListNotifierProvider);
    final showInitialSkeleton = !_initialLoadCompleted &&
        !allState.hasError &&
        (allState.isLoading || (allState.valueOrNull?.isEmpty ?? true));
    final renderState = showInitialSkeleton
        ? const AsyncLoading<List<OrchestratorPlanModel>>()
        : allState;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Orchestrator',
          style: TextStyle(
            color: AppColors.onBackground,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            const Tab(text: 'My Tasks'),
            if (_isOwnerOrManager) const Tab(text: 'All Plans'),
          ],
        ),
      ),
      floatingActionButton: _isOwnerOrManager
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Plan'),
              onPressed: () => context.push('/orchestrator/new'),
            )
          : null,
      body: renderState.when(
        loading: () => const AppScreenSkeleton(showHeader: false, cardCount: 4),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 40),
              const SizedBox(height: AppSpacing.sm),
              Text(
                OrchestratorListNotifier.errorMessage(e),
                style: const TextStyle(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => ref
                    .read(orchestratorListNotifierProvider.notifier)
                    .load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (allPlans) => TabBarView(
          controller: _tabController,
          children: [
            // My Tasks tab — filter plans where current user is assignee
            _PlanList(
              plans: allPlans.where((p) => _isMyPlan(p)).toList(),
              emptyMessage: 'No active tasks',
              emptySubtitle: 'Plans assigned to you will appear here.',
              onRefresh: () =>
                  ref.read(orchestratorListNotifierProvider.notifier).load(),
              isMyTasks: true,
            ),
            if (_isOwnerOrManager)
              _PlanList(
                plans: allPlans,
                emptyMessage: 'No plans yet',
                emptySubtitle: 'Tap "New Plan" to generate your first AI plan.',
                onRefresh: () =>
                    ref.read(orchestratorListNotifierProvider.notifier).load(),
                isMyTasks: false,
              ),
          ],
        ),
      ),
    );
  }

  bool _isMyPlan(OrchestratorPlanModel plan) {
    // Simple: show all active/in-progress plans in my tasks tab
    return plan.status == 'in_progress' || plan.status == 'published';
  }
}

// ---------------------------------------------------------------------------
// Plan list view
// ---------------------------------------------------------------------------

class _PlanList extends StatelessWidget {
  const _PlanList({
    required this.plans,
    required this.emptyMessage,
    required this.emptySubtitle,
    required this.onRefresh,
    required this.isMyTasks,
  });

  final List<OrchestratorPlanModel> plans;
  final String emptyMessage;
  final String emptySubtitle;
  final Future<void> Function() onRefresh;
  final bool isMyTasks;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 56,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                emptyMessage,
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                emptySubtitle,
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          120,
        ),
        itemCount: plans.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _PlanCard(
            plan: plans[i],
            isMyTasks: isMyTasks,
            onTap: () => context.push('/orchestrator/plans/${plans[i].id}').then((_) {
                  ref.read(orchestratorListNotifierProvider.notifier).load();
                }),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plan card
// ---------------------------------------------------------------------------

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isMyTasks,
    required this.onTap,
  });

  final OrchestratorPlanModel plan;
  final bool isMyTasks;
  final VoidCallback onTap;

  static String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _planStatusInfo(plan.status);
    final progress = plan.percentComplete;
    final assigneeCount = plan.taskGroups
        .map((g) => g.assignedUserId)
        .whereType<String>()
        .toSet()
        .length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusInfo.color.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row + command type chip
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      plan.title,
                      style: const TextStyle(
                        color: AppColors.onBackground,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CommandTypeChip(commandType: plan.commandType),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // Status + target date
              Row(
                children: [
                  _StatusBadge(status: plan.status),
                  const SizedBox(width: AppSpacing.sm),
                  if (plan.targetDate != null) ...[
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(plan.targetDate),
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (!isMyTasks && assigneeCount > 0) ...[
                    const Icon(
                      Icons.people_outline,
                      size: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$assigneeCount staff',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor:
                      AppColors.onSurfaceVariant.withValues(alpha: 0.15),
                  color: statusInfo.color,
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toInt()}% complete · ${plan.completedSteps}/${plan.totalSteps} steps',
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status helpers
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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

class _CommandTypeChip extends StatelessWidget {
  const _CommandTypeChip({required this.commandType});

  final String commandType;

  @override
  Widget build(BuildContext context) {
    final label = commandType[0].toUpperCase() + commandType.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
