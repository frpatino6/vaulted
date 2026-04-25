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
    final renderState = showSkeleton
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
          style: AppTypography.displaySerif.copyWith(
            color: AppColors.onBackground,
            fontSize: 22,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          labelStyle:
              AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTypography.labelLarge,
          indicatorColor: AppColors.accent,
          indicatorWeight: 1.5,
          dividerColor: AppColors.onSurfaceVariant.withValues(alpha: 0.10),
          tabs: [
            _tab('Overdue', overdue.length, _urgentDot),
            _tab('This Week', dueSoon.length, _soonDot),
            _tab('Upcoming', upcoming.length, null),
            _tab('Completed', completed.length, null),
          ],
        ),
      ),
      body: renderState.when(
        data: (_) => TabBarView(
          controller: _tabController,
          children: [
            _list(overdue, tab: _tabs[0]),
            _list(dueSoon, tab: _tabs[1]),
            _list(upcoming, tab: _tabs[2]),
            _list(completed, tab: _tabs[3]),
          ],
        ),
        loading: () => const AppScreenSkeleton(showHeader: false),
        error: (e, _) => _ErrorState(
          message: MaintenanceListNotifier.errorMessage(e),
          onRetry: () =>
              ref.read(maintenanceListNotifierProvider.notifier).load(),
        ),
      ),
    );
  }

  static const _urgentDot = Color(0xFFCF6679);
  static const _soonDot = Color(0xFFD4AF37);

  Tab _tab(String label, int count, Color? dotColor) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null && count > 0) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(count > 0 ? '$label  $count' : label),
        ],
      ),
    );
  }

  Widget _list(List<MaintenanceModel> records, {required String tab}) {
    if (records.isEmpty) return _EmptyState(tab: tab);

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () =>
          ref.read(maintenanceListNotifierProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xxl),
        itemCount: records.length,
        itemBuilder: (context, index) {
          return _MaintenanceRow(
            record: records[index],
            showDivider: index < records.length - 1,
            onTap: () => context.push(
                '/maintenance/${records[index].id}',
                extra: records[index]),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Row item — each maintenance record
// ---------------------------------------------------------------------------

class _MaintenanceRow extends StatelessWidget {
  const _MaintenanceRow({
    required this.record,
    required this.onTap,
    required this.showDivider,
  });

  final MaintenanceModel record;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final accentColor = _accentColor(record);
    final dt = DateTime.tryParse(record.scheduledDate);
    final dateLabel = dt != null ? DateFormat.yMMMd().format(dt) : record.scheduledDate;
    final urgencyTag = _urgencyTag(dt);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colored dot indicator
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.onBackground,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 10,
                        runSpacing: 3,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            dateLabel,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          if (urgencyTag != null)
                            Text(
                              urgencyTag,
                              style: AppTypography.labelSmall.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (record.isRecurring &&
                              record.recurrenceIntervalDays != null)
                            Text(
                              'Every ${record.recurrenceIntervalDays}d',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          if (record.isAiSuggested &&
                              record.aiRiskScore != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 11,
                                  color: AppColors.accentLight,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Risk ${record.aiRiskScore!.toInt()}%',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.accentLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 21,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.08),
          ),
      ],
    );
  }

  Color _accentColor(MaintenanceModel r) {
    if (r.isOverdue) return const Color(0xFFCF6679);
    if (r.isUrgent) return const Color(0xFFE07B39);
    if (r.isDueSoon) return const Color(0xFFD4AF37);
    if (r.isCompleted) return const Color(0xFF6DB86F);
    return AppColors.onSurfaceVariant;
  }

  String? _urgencyTag(DateTime? dt) {
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

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tab});

  final String tab;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = switch (tab) {
      'Overdue' => (
          'All caught up',
          'No overdue maintenance at this time.',
        ),
      'This Week' => (
          'Nothing due this week',
          'Upcoming tasks will appear here automatically.',
        ),
      'Upcoming' => (
          'Schedule looks clear',
          'Add tasks from item details to plan ahead.',
        ),
      _ => (
          'No history yet',
          'Completed maintenance will appear here.',
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.check_rounded,
                size: 22,
                color: AppColors.accent.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleSerif.copyWith(
                color: AppColors.onBackground,
                fontSize: 17,
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
// Error state
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
