import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../data/models/maintenance_model.dart';
import '../domain/maintenance_notifier.dart';

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
    final state = ref.watch(maintenanceListNotifierProvider);
    final allRecords = state.valueOrNull ?? const <MaintenanceModel>[];
    final overdueRecords = allRecords.where((r) => r.isOverdue).toList();
    final dueSoonRecords = allRecords.where((r) => r.isDueSoon).toList();
    final upcomingRecords = allRecords
        .where((r) => r.isPending && !r.isDueSoon && !r.isOverdue)
        .toList();
    final completedRecords = allRecords.where((r) => r.isCompleted).toList();

    final showInitialSkeleton =
        !_initialLoadCompleted &&
        !state.hasError &&
        (state.isLoading || (state.valueOrNull?.isEmpty ?? true));
    final renderState = showInitialSkeleton
        ? const AsyncLoading<List<MaintenanceModel>>()
        : state;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Maintenance',
          style: AppTypography.titleSerif.copyWith(
            color: AppColors.onBackground,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: AppTypography.labelLarge
              .copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTypography.labelLarge,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.accent,
          indicatorWeight: 2,
          dividerColor: AppColors.onSurfaceVariant.withValues(alpha: 0.12),
          tabs: [
            _buildTabLabel('Overdue', overdueRecords.length,
                const Color(0xFFCF6679)),
            _buildTabLabel('This Week', dueSoonRecords.length,
                const Color(0xFFD4AF37)),
            _buildTabLabel('Upcoming', upcomingRecords.length,
                const Color(0xFF8A8AA8)),
            _buildTabLabel('Completed', completedRecords.length,
                const Color(0xFF6DB86F)),
          ],
        ),
      ),
      body: renderState.when(
        data: (_) => TabBarView(
          controller: _tabController,
          children: [
            _buildTabContent(overdueRecords, tab: _tabs[0]),
            _buildTabContent(dueSoonRecords, tab: _tabs[1]),
            _buildTabContent(upcomingRecords, tab: _tabs[2]),
            _buildTabContent(completedRecords, tab: _tabs[3]),
          ],
        ),
        loading: () => const AppScreenSkeleton(showHeader: false),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  MaintenanceListNotifier.errorMessage(e),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      ref
                          .read(maintenanceListNotifierProvider.notifier)
                          .load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Tab _buildTabLabel(String label, int count, Color badgeColor) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: AppTypography.labelSmall.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabContent(List<MaintenanceModel> records,
      {required String tab}) {
    if (records.isEmpty) {
      return _EmptyTabState(tab: tab);
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () =>
          ref.read(maintenanceListNotifierProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
        itemCount: records.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final record = records[index];
          return _MaintenanceCard(
            record: record,
            onTap: () =>
                context.push('/maintenance/${record.id}', extra: record),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyTabState extends StatelessWidget {
  const _EmptyTabState({required this.tab});

  final String tab;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, icon, color) = switch (tab) {
      'Overdue' => (
          'All caught up',
          'No overdue maintenance at this time.',
          Icons.task_alt_rounded,
          const Color(0xFF6DB86F),
        ),
      'This Week' => (
          'Nothing due this week',
          'Upcoming tasks will appear here automatically.',
          Icons.event_available_rounded,
          AppColors.accent,
        ),
      'Upcoming' => (
          'Schedule looks clear',
          'Add tasks from item details to plan ahead.',
          Icons.calendar_month_rounded,
          AppColors.onSurfaceVariant,
        ),
      _ => (
          'No history yet',
          'Completed maintenance will appear here.',
          Icons.history_rounded,
          AppColors.onSurfaceVariant,
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.08),
                border: Border.all(
                  color: color.withValues(alpha: 0.28),
                  width: 1.5,
                ),
              ),
              child: Icon(icon,
                  size: 30, color: color.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleSerif.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Maintenance card
// ---------------------------------------------------------------------------

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({required this.record, required this.onTap});

  final MaintenanceModel record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(record);
    final isHighPriority = record.isOverdue || record.isUrgent;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: isHighPriority
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  statusColor.withValues(alpha: 0.07),
                  AppColors.surface,
                ],
              )
            : null,
        color: isHighPriority ? null : AppColors.surface,
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: statusColor.withValues(alpha: 0.06),
            highlightColor: statusColor.withValues(alpha: 0.03),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent bar
                  Container(width: 3, color: statusColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon container
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _icon(record),
                              color: statusColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        record.title,
                                        style:
                                            AppTypography.titleSerif.copyWith(
                                          color: AppColors.onBackground,
                                          fontSize: 15,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    _StatusBadge(
                                        status: record.status,
                                        color: statusColor),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                _DateRow(
                                    record: record, statusColor: statusColor),
                                if (record.isRecurring) ...[
                                  const SizedBox(height: 4),
                                  _RecurrenceRow(record: record),
                                ],
                                if (record.isAiSuggested &&
                                    record.aiRiskScore != null) ...[
                                  const SizedBox(height: 4),
                                  _AiRow(record: record),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Chevron
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppColors.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(MaintenanceModel r) {
    if (r.isOverdue) return const Color(0xFFCF6679);
    if (r.isUrgent) return const Color(0xFFE07B39);
    if (r.isDueSoon) return const Color(0xFFD4AF37);
    if (r.isCompleted) return const Color(0xFF6DB86F);
    return const Color(0xFF8A8AA8);
  }

  IconData _icon(MaintenanceModel r) {
    if (r.isCompleted) return Icons.check_circle_outline_rounded;
    if (r.isOverdue) return Icons.warning_amber_rounded;
    if (r.isUrgent) return Icons.error_outline_rounded;
    if (r.isAiSuggested) return Icons.auto_awesome_rounded;
    if (r.isRecurring) return Icons.repeat_rounded;
    return Icons.build_circle_outlined;
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _DateRow extends StatelessWidget {
  const _DateRow({required this.record, required this.statusColor});

  final MaintenanceModel record;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(record.scheduledDate);
    final dateStr =
        dt != null ? DateFormat.yMMMd().format(dt) : record.scheduledDate;
    final urgency = _urgencyLabel(dt);

    return Row(
      children: [
        Icon(Icons.calendar_today_outlined,
            size: 13, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          dateStr,
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
        if (urgency != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              urgency,
              style: AppTypography.labelSmall.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String? _urgencyLabel(DateTime? dt) {
    if (dt == null) return null;
    final now = DateTime.now();
    if (record.isOverdue) {
      final days = now.difference(dt).inDays;
      return days <= 0 ? 'Due today' : '${days}d overdue';
    }
    final diff = dt.difference(now).inDays;
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Tomorrow';
    if (diff <= 7) return 'In $diff days';
    return null;
  }
}

class _RecurrenceRow extends StatelessWidget {
  const _RecurrenceRow({required this.record});

  final MaintenanceModel record;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.repeat_rounded,
            size: 13, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          'Every ${record.recurrenceIntervalDays ?? '?'} days',
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _AiRow extends StatelessWidget {
  const _AiRow({required this.record});

  final MaintenanceModel record;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.auto_awesome_rounded,
            size: 13, color: AppColors.accentLight),
        const SizedBox(width: 4),
        Text(
          'AI · Risk ${record.aiRiskScore!.toInt()}%',
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.accentLight),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.32), width: 1),
      ),
      child: Text(
        _label(status),
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  String _label(String s) => switch (s) {
        'pending' => 'Pending',
        'overdue' => 'Overdue',
        'completed' => 'Completed',
        'cancelled' => 'Cancelled',
        _ => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}',
      };
}
