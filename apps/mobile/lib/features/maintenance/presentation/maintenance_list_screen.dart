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
    final upcomingRecords =
        allRecords
            .where((r) => r.isPending && !r.isDueSoon && !r.isOverdue)
            .toList();
    final completedRecords = allRecords.where((r) => r.isCompleted).toList();

    final showInitialSkeleton =
        !_initialLoadCompleted &&
        !state.hasError &&
        (state.isLoading || (state.valueOrNull?.isEmpty ?? true));
    final renderState =
        showInitialSkeleton
            ? const AsyncLoading<List<MaintenanceModel>>()
            : state;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        title: Text(
          'Maintenance',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.accent,
          tabs: [
            _buildTabTitle('Overdue', overdueRecords.length),
            _buildTabTitle('This Week', dueSoonRecords.length),
            _buildTabTitle('Upcoming', upcomingRecords.length),
            _buildTabTitle('Completed', completedRecords.length),
          ],
        ),
      ),
      body: renderState.when(
        data:
            (_) => TabBarView(
              controller: _tabController,
              children: [
                _buildTab(overdueRecords, tab: _tabs[0]),
                _buildTab(dueSoonRecords, tab: _tabs[1]),
                _buildTab(upcomingRecords, tab: _tabs[2]),
                _buildTab(completedRecords, tab: _tabs[3]),
              ],
            ),
        loading: () => const AppScreenSkeleton(showHeader: false),
        error:
            (e, _) => Center(
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
                      onPressed:
                          () =>
                              ref
                                  .read(
                                    maintenanceListNotifierProvider.notifier,
                                  )
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

  Tab _buildTabTitle(String label, int count) {
    return Tab(
      child: Text(
        '$label ($count)',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTab(List<MaintenanceModel> records, {required String tab}) {
    if (records.isEmpty) {
      return _EmptyTabState(
        tab: tab,
        onRefresh:
            () => ref.read(maintenanceListNotifierProvider.notifier).load(),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh:
          () => ref.read(maintenanceListNotifierProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: records.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final record = records[index];
          return _MaintenanceCard(
            record: record,
            onTap:
                () => context.push('/maintenance/${record.id}', extra: record),
          );
        },
      ),
    );
  }
}

class _EmptyTabState extends StatelessWidget {
  const _EmptyTabState({required this.tab, required this.onRefresh});

  final String tab;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final String title;
    final String subtitle;
    final IconData icon;

    switch (tab) {
      case 'Overdue':
        title = 'No overdue maintenance';
        subtitle = 'Everything pending is currently on schedule.';
        icon = Icons.task_alt;
        break;
      case 'This Week':
        title = 'No maintenance due this week';
        subtitle = 'Upcoming tasks will appear here automatically.';
        icon = Icons.event_available;
        break;
      case 'Upcoming':
        title = 'No upcoming maintenance';
        subtitle = 'Create tasks from item details to plan ahead.';
        icon = Icons.event_note;
        break;
      default:
        title = 'No completed maintenance yet';
        subtitle = 'Completed tasks will build your maintenance history.';
        icon = Icons.history;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
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
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceCard extends ConsumerWidget {
  const _MaintenanceCard({required this.record, required this.onTap});

  final MaintenanceModel record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(record);
    final dateStr = _formatDate(record.scheduledDate);

    return Card(
      color: AppColors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.title,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.onBackground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _StatusChip(status: record.status, color: statusColor),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (record.isRecurring) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.repeat,
                      size: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Every ${record.recurrenceIntervalDays ?? '?'} days',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              if (record.isAiSuggested && record.aiRiskScore != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppColors.accentLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI suggested · Risk ${record.aiRiskScore!.toInt()}%',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accentLight,
                      ),
                    ),
                  ],
                ),
              ],
              if (record.isPending || record.isOverdue) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tap for details',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () => _markComplete(context, ref),
                      child: const Text('Complete'),
                    ),
                  ],
                ),
              ],
            ],
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
    return const Color(0xFF6A6A7E);
  }

  String _formatDate(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;
    return DateFormat.yMMMd().format(dt);
  }

  Future<void> _markComplete(BuildContext context, WidgetRef ref) async {
    await ref
        .read(maintenanceListNotifierProvider.notifier)
        .complete(record.id);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Marked as completed')));
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
