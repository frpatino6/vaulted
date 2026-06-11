import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/help_screen_button.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../users/domain/current_user_jwt.dart';
import '../data/models/orchestrator_plan_model.dart';
import '../domain/orchestrator_detail_notifier.dart';
import 'orchestrator_status_helpers.dart';

class OrchestratorTaskGroupScreen extends ConsumerStatefulWidget {
  const OrchestratorTaskGroupScreen({
    super.key,
    required this.planId,
    required this.groupId,
  });

  final String planId;
  final String groupId;

  @override
  ConsumerState<OrchestratorTaskGroupScreen> createState() =>
      _OrchestratorTaskGroupScreenState();
}

class _OrchestratorTaskGroupScreenState
    extends ConsumerState<OrchestratorTaskGroupScreen> {
  bool _initialLoadCompleted = false;

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

  OrchestratorTaskGroupModel? _findGroup(OrchestratorPlanModel plan) {
    for (final g in plan.taskGroups) {
      if (g.groupId == widget.groupId) return g;
    }
    return null;
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
      appBar: showInitialSkeleton || state.isLoading
          ? AppBar(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.onBackground,
              elevation: 0,
            )
          : null,
      body: renderState.when(
        loading: () => const AppScreenSkeleton(showHeader: false, cardCount: 5),
        error: (e, _) => _buildErrorBody(e),
        data: (plan) {
          if (plan == null) {
            return _buildNotFoundBody('Plan not found');
          }
          final group = _findGroup(plan);
          if (group == null) {
            return _buildNotFoundBody('Task group not found');
          }
          return _buildContent(context, plan, group);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    OrchestratorPlanModel plan,
    OrchestratorTaskGroupModel group,
  ) {
    final doneCount = group.completedSteps;
    final totalCount = group.totalSteps;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () =>
          ref.read(orchestratorDetailNotifierProvider.notifier).load(widget.planId),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.onBackground,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              group.title,
              style: const TextStyle(
                color: AppColors.onBackground,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [const HelpScreenButton(screenKey: 'orchestrator')],
          ),
          // Header card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          group.assignedUserName != null
                              ? 'Assigned to: ${group.assignedUserName}'
                              : 'Unassigned',
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        OrchestratorGroupStatusChip(status: group.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: totalCount == 0
                                  ? 0
                                  : doneCount / totalCount,
                              backgroundColor:
                                  AppColors.onSurfaceVariant.withValues(alpha: 0.15),
                              color: AppColors.accent,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '$doneCount / $totalCount done',
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          // Steps list
          if (group.steps.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.checklist_rounded,
                      size: 56,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'No steps in this group',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                120,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final step = group.steps[i];
                    final role = currentUserRole();
                    final canRemove = !plan.isCompleted && !plan.isCancelled &&
                        (role == 'owner' || role == 'manager');
                    final tile = _StepTile(
                      step: step,
                      index: i + 1,
                      onTap: () => context.push(
                        '/orchestrator/plans/${widget.planId}/groups/${widget.groupId}/steps/${step.stepId}',
                      ),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: canRemove
                          ? Dismissible(
                              key: ValueKey(step.stepId),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.delete_outline,
                                    color: AppColors.error),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppColors.surfaceVariant,
                                    title: const Text('Remove step'),
                                    content: Text(
                                        'Remove "${step.itemName}" from this group?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: TextButton.styleFrom(
                                            foregroundColor: AppColors.error),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (_) async {
                                try {
                                  await ref
                                      .read(orchestratorDetailNotifierProvider
                                          .notifier)
                                      .removeStep(
                                        groupId: widget.groupId,
                                        stepId: step.stepId,
                                      );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        OrchestratorDetailNotifier.errorMessage(e),
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              },
                              child: tile,
                            )
                          : tile,
                    );
                  },
                  childCount: group.steps.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBody(Object e) {
    return Center(
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
    );
  }

  Widget _buildNotFoundBody(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step tile
// ---------------------------------------------------------------------------

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.step,
    required this.index,
    required this.onTap,
  });

  final OrchestratorStepModel step;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusInfo = stepStatusInfo(step.status);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: step.isOrphaned ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: statusInfo.color.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Index bubble
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: statusInfo.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: statusInfo.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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
                      step.itemName,
                      style: const TextStyle(
                        color: AppColors.onBackground,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.itemCategory,
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OrchestratorStepStatusChip(status: step.status),
            ],
          ),
        ),
      ),
    );
  }
}

