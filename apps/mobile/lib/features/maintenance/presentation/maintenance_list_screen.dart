import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../users/domain/current_user_jwt.dart';
import '../data/models/maintenance_model.dart';
import '../domain/maintenance_notifier.dart';
import 'add_maintenance_sheet.dart';
import 'package:vaulted/shared/widgets/help_screen_button.dart';


class MaintenanceListScreen extends ConsumerStatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  ConsumerState<MaintenanceListScreen> createState() =>
      _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends ConsumerState<MaintenanceListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _initialLoadCompleted = false;

  static const _tabs = ['Overdue', 'This Week', 'Upcoming', 'Completed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(maintenanceListNotifierProvider.notifier).load().whenComplete(
        () {
          if (!mounted) return;
          setState(() => _initialLoadCompleted = true);
        },
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = currentUserRole() ?? 'guest';
    final canCreate = role == 'owner' || role == 'manager';
    final canComplete = role == 'owner' || role == 'manager' || role == 'staff';
    final state = ref.watch(maintenanceListNotifierProvider);
    final all = state.valueOrNull ?? const <MaintenanceModel>[];
    final overdue = all.where((r) => r.isOverdue).toList();
    final dueSoon = all.where((r) => r.isDueSoon).toList();
    final upcoming =
        all.where((r) => r.isPending && !r.isDueSoon && !r.isOverdue).toList();
    final completed = all.where((r) => r.isCompleted).toList();

    final showSkeleton =
        !_initialLoadCompleted &&
        !state.hasError &&
        (state.isLoading || (state.valueOrNull?.isEmpty ?? true));
    final renderState =
        showSkeleton ? const AsyncLoading<List<MaintenanceModel>>() : state;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Maintenance',
          style: AppTypography.displaySerif.copyWith(
            color: AppColors.onBackground,
            fontSize: 22,
          ),
        ),
        actions: [const HelpScreenButton(screenKey: 'maintenance')],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: overdue.isEmpty ? 'Overdue' : 'Overdue  ${overdue.length}'),
            Tab(text: dueSoon.isEmpty ? 'This Week' : 'This Week  ${dueSoon.length}'),
            Tab(text: upcoming.isEmpty ? 'Upcoming' : 'Upcoming  ${upcoming.length}'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              tooltip: 'Schedule maintenance',
              onPressed: () async {
                final record = await showAddMaintenanceSheet(context);
                if (record != null && mounted) {
                  ref.read(maintenanceListNotifierProvider.notifier).load();
                }
              },
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: renderState.when(
        data: (_) => TabBarView(
          controller: _tabController,
          children: [
            _MaintenanceList(
              records: overdue,
              canComplete: canComplete,
              emptyMessage: 'All caught up',
              emptySubtitle: 'No overdue maintenance at this time.',
              onRefresh: () =>
                  ref.read(maintenanceListNotifierProvider.notifier).load(),
            ),
            _MaintenanceList(
              records: dueSoon,
              canComplete: canComplete,
              emptyMessage: 'Nothing due this week',
              emptySubtitle: 'Upcoming tasks will appear here automatically.',
              onRefresh: () =>
                  ref.read(maintenanceListNotifierProvider.notifier).load(),
            ),
            _MaintenanceList(
              records: upcoming,
              canComplete: canComplete,
              emptyMessage: 'Schedule looks clear',
              emptySubtitle: 'Add tasks from item details to plan ahead.',
              onRefresh: () =>
                  ref.read(maintenanceListNotifierProvider.notifier).load(),
            ),
            _MaintenanceList(
              records: completed,
              canComplete: canComplete,
              emptyMessage: 'No history yet',
              emptySubtitle: 'Completed maintenance will appear here.',
              onRefresh: () =>
                  ref.read(maintenanceListNotifierProvider.notifier).load(),
            ),
          ],
        ),
        loading: () => const AppScreenSkeleton(showHeader: false, cardCount: 5),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.error, size: 40),
              const SizedBox(height: AppSpacing.sm),
              Text(
                MaintenanceListNotifier.errorMessage(e),
                style:
                    const TextStyle(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () =>
                    ref.read(maintenanceListNotifierProvider.notifier).load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List + empty state — Tarea 3: ConstrainedBox for tablet/web
// ---------------------------------------------------------------------------

class _MaintenanceList extends StatelessWidget {
  const _MaintenanceList({
    required this.records,
    required this.canComplete,
    required this.emptyMessage,
    required this.emptySubtitle,
    required this.onRefresh,
  });

  final List<MaintenanceModel> records;
  final bool canComplete;
  final String emptyMessage;
  final String emptySubtitle;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.build_circle_outlined,
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
      backgroundColor: AppColors.surfaceVariant,
      onRefresh: onRefresh,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 120),
            itemCount: records.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: MaintenanceCard(
                record: records[i],
                canComplete: canComplete,
                onTap: () => context.push(
                  '/maintenance/${records[i].id}',
                  extra: records[i],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card — Tarea 1 + 2: cleaned subtitle, risk badge, complete action, Slidable
// ---------------------------------------------------------------------------

class MaintenanceCard extends ConsumerWidget {
  const MaintenanceCard({
    super.key,
    required this.record,
    required this.canComplete,
    required this.onTap,
  });

  final MaintenanceModel record;
  final bool canComplete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = _statusInfo(record);
    final icon = _leadingIcon(record);

    return Slidable(
      key: ValueKey(record.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.45,
        children: [
          SlidableAction(
            onPressed: (_) => context.push(
              '/maintenance/${record.id}',
              extra: record,
            ),
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            icon: Icons.schedule_rounded,
            label: 'Reschedule',
          ),
          SlidableAction(
            onPressed: (_) => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Snooze coming soon'),
                duration: Duration(seconds: 2),
              ),
            ),
            backgroundColor: AppColors.surfaceVariant,
            foregroundColor: AppColors.onSurface,
            icon: Icons.snooze_rounded,
            label: 'Snooze',
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              top: AppSpacing.md,
              bottom: AppSpacing.md,
              right: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: info.color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                // Leading icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: info.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: info.color, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row + risk badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              record.title,
                              style: const TextStyle(
                                color: AppColors.onBackground,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (record.isAiSuggested &&
                              record.aiRiskScore != null) ...[
                            const SizedBox(width: 6),
                            _RiskBadge(score: record.aiRiskScore!),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Subtitle: single clean line
                      _SubtitleLine(record: record, statusColor: info.color),
                      // Recurrence tag
                      if (record.isRecurring) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.repeat_rounded,
                              size: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Every ${record.recurrenceIntervalDays ?? '?'}d',
                              style: const TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Trailing: quick complete button (owner/manager/staff only)
                if (canComplete || record.isCompleted)
                  IconButton(
                    icon: Icon(
                      record.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.check_circle_outline_rounded,
                      color: record.isCompleted
                          ? AppColors.accent
                          : AppColors.onSurfaceVariant.withValues(alpha: 0.45),
                    ),
                    iconSize: 26,
                    tooltip: record.isCompleted ? 'Completed' : 'Mark as done',
                    onPressed: record.isCompleted || !canComplete
                        ? null
                        : () async {
                            await ref
                                .read(maintenanceListNotifierProvider.notifier)
                                .complete(record.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Marked as completed'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _leadingIcon(MaintenanceModel r) {
    if (r.isCompleted) return Icons.check_circle_outline_rounded;
    if (r.isAiSuggested) return Icons.auto_awesome_rounded;
    if (r.isRecurring) return Icons.repeat_rounded;
    return Icons.build_outlined;
  }
}

// ---------------------------------------------------------------------------
// Risk badge — traffic-light coloring for aiRiskScore
// ---------------------------------------------------------------------------

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? const Color(0xFFCF6679)
        : score >= 50
        ? const Color(0xFFFF9800)
        : const Color(0xFF6DB86F);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.shield_outlined, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          '${score.toInt()}%',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Subtitle line — date + urgency on one clean line (Tarea 1)
// ---------------------------------------------------------------------------

class _SubtitleLine extends StatelessWidget {
  const _SubtitleLine({required this.record, required this.statusColor});

  final MaintenanceModel record;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final dateStr = _shortDate(record.scheduledDate);
    final urgency = _urgencyLabel(record);

    if (urgency == null) {
      return Text(
        dateStr,
        style: const TextStyle(
          color: AppColors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    final dateColor = record.isOverdue || record.isUrgent
        ? statusColor
        : AppColors.onSurfaceVariant;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$dateStr • ',
            style: TextStyle(
              color: dateColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: urgency,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('MMM d').format(dt);
  }

  String? _urgencyLabel(MaintenanceModel r) {
    final dt = DateTime.tryParse(r.scheduledDate);
    if (dt == null) return null;
    final now = DateTime.now();
    if (r.isOverdue) {
      final days = now.difference(dt).inDays;
      return days <= 0 ? 'due today' : '$days days overdue';
    }
    final diff = dt.difference(now).inDays;
    if (diff == 0) return 'due today';
    if (diff == 1) return 'tomorrow';
    if (diff <= 7) return 'in $diff days';
    return null;
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

_StatusInfo _statusInfo(MaintenanceModel r) {
  if (r.isOverdue) return const _StatusInfo(Color(0xFFCF6679), 'OVERDUE');
  if (r.isUrgent) return const _StatusInfo(Color(0xFFE07B39), 'URGENT');
  if (r.isDueSoon) return const _StatusInfo(Color(0xFFD4AF37), 'DUE SOON');
  if (r.isCompleted) return const _StatusInfo(Color(0xFF6DB86F), 'DONE');
  if (r.isCancelled) return const _StatusInfo(Color(0xFF9E9E9E), 'CANCELLED');
  return const _StatusInfo(Color(0xFF8A8AA8), 'PENDING');
}
