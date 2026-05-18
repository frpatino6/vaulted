import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../data/models/orchestrator_plan_model.dart';
import '../domain/orchestrator_detail_notifier.dart';
import '../domain/orchestrator_progress_notifier.dart';

class OrchestratorProgressDashboardScreen extends ConsumerStatefulWidget {
  const OrchestratorProgressDashboardScreen({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<OrchestratorProgressDashboardScreen> createState() =>
      _OrchestratorProgressDashboardScreenState();
}

class _OrchestratorProgressDashboardScreenState
    extends ConsumerState<OrchestratorProgressDashboardScreen> {
  bool _initialLoadCompleted = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load().whenComplete(() {
        if (!mounted) return;
        setState(() => _initialLoadCompleted = true);
        _startAutoRefresh();
      });
    });
  }

  Future<void> _load() async {
    await Future.wait([
      ref
          .read(orchestratorProgressNotifierProvider.notifier)
          .load(widget.planId),
      ref
          .read(orchestratorDetailNotifierProvider.notifier)
          .load(widget.planId),
    ]);
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      ref
          .read(orchestratorProgressNotifierProvider.notifier)
          .refresh(widget.planId);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressState = ref.watch(orchestratorProgressNotifierProvider);
    final detailState = ref.watch(orchestratorDetailNotifierProvider);

    final showSkeleton = !_initialLoadCompleted &&
        !progressState.hasError &&
        (progressState.isLoading || progressState.valueOrNull == null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Live Progress',
          style: TextStyle(
            color: AppColors.onBackground,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            onPressed: () => _load(),
          ),
        ],
      ),
      body: showSkeleton
          ? const Center(child: CircularProgressIndicator())
          : progressState.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 40,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      OrchestratorProgressNotifier.errorMessage(e),
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (progress) {
                if (progress == null) {
                  return const Center(
                    child: Text(
                      'No progress data',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  );
                }
                final plan = detailState.valueOrNull;
                return RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      // Overall circle
                      _OverallProgressRing(
                        percentComplete: progress.percentComplete,
                        completedSteps: progress.completedSteps,
                        totalSteps: progress.totalSteps,
                        status: progress.status,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Per-staff breakdown
                      if (progress.byGroup.isNotEmpty) ...[
                        const Text(
                          'BY STAFF',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...progress.byGroup.map(
                          (group) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _GroupProgressCard(group: group),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      // Completed steps timeline from plan detail
                      if (plan != null) ...[
                        const Text(
                          'COMPLETED STEPS',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _CompletedStepsTimeline(plan: plan),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overall progress ring
// ---------------------------------------------------------------------------

class _OverallProgressRing extends StatelessWidget {
  const _OverallProgressRing({
    required this.percentComplete,
    required this.completedSteps,
    required this.totalSteps,
    required this.status,
  });

  final double percentComplete;
  final int completedSteps;
  final int totalSteps;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: percentComplete,
                    backgroundColor:
                        AppColors.onSurfaceVariant.withValues(alpha: 0.15),
                    color: AppColors.accent,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(percentComplete * 100).toInt()}%',
                          style: const TextStyle(
                            color: AppColors.onBackground,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'complete',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '$completedSteps of $totalSteps steps',
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _StatusBadge(status: status),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-group progress card
// ---------------------------------------------------------------------------

class _GroupProgressCard extends StatelessWidget {
  const _GroupProgressCard({required this.group});

  final GroupProgressModel group;

  String get _initials {
    final name = group.assignedUserName;
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final progress = group.totalSteps == 0
        ? 0.0
        : group.completedSteps / group.totalSteps;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            child: Text(
              _initials,
              style: const TextStyle(
                color: AppColors.accent,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        group.title,
                        style: const TextStyle(
                          color: AppColors.onBackground,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${group.completedSteps}/${group.totalSteps}',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  group.assignedUserName.isNotEmpty
                      ? group.assignedUserName
                      : 'Unassigned',
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor:
                        AppColors.onSurfaceVariant.withValues(alpha: 0.15),
                    color: AppColors.accent,
                    minHeight: 5,
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

// ---------------------------------------------------------------------------
// Completed steps timeline from plan detail
// ---------------------------------------------------------------------------

class _CompletedStepsTimeline extends StatelessWidget {
  const _CompletedStepsTimeline({required this.plan});

  final OrchestratorPlanModel plan;

  @override
  Widget build(BuildContext context) {
    final doneSteps = <_TimelineEntry>[];
    for (final group in plan.taskGroups) {
      for (final step in group.steps) {
        if (step.isDone && step.completedAt != null) {
          doneSteps.add(
            _TimelineEntry(
              itemName: step.itemName,
              completedByUserId: step.completedByUserId,
              assignedUserName: group.assignedUserName,
              completedAt: step.completedAt!,
            ),
          );
        }
      }
    }

    // Sort by completedAt desc
    doneSteps.sort(
      (a, b) => b.completedAt.compareTo(a.completedAt),
    );

    if (doneSteps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text(
            'No steps completed yet',
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),
      );
    }

    return Column(
      children: doneSteps.map((entry) => _TimelineTile(entry: entry)).toList(),
    );
  }
}

class _TimelineEntry {
  const _TimelineEntry({
    required this.itemName,
    required this.completedByUserId,
    required this.assignedUserName,
    required this.completedAt,
  });

  final String itemName;
  final String? completedByUserId;
  final String? assignedUserName;
  final String completedAt;
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.entry});

  final _TimelineEntry entry;

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('MMM d · HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 32,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.itemName,
                    style: const TextStyle(
                      color: AppColors.onBackground,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        entry.assignedUserName ?? 'Staff',
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      const Text(
                        ' · ',
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                      Text(
                        _formatTime(entry.completedAt),
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
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'published':
        color = const Color(0xFF2196F3);
        label = 'Published';
        break;
      case 'in_progress':
        color = const Color(0xFFE07B39);
        label = 'In Progress';
        break;
      case 'completed':
        color = const Color(0xFF6DB86F);
        label = 'Completed';
        break;
      case 'cancelled':
        color = const Color(0xFF9E9E9E);
        label = 'Cancelled';
        break;
      default:
        color = const Color(0xFF8A8AA8);
        label = 'Draft';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
