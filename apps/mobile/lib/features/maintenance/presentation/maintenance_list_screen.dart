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
      body: renderState.when(
        data: (_) => TabBarView(
          controller: _tabController,
          children: [
            _MaintenanceList(
              records: overdue,
              emptyMessage: 'All caught up',
              emptySubtitle: 'No overdue maintenance at this time.',
              onRefresh: () =>
                  ref.read(maintenanceListNotifierProvider.notifier).load(),
            ),
            _MaintenanceList(
              records: dueSoon,
              emptyMessage: 'Nothing due this week',
              emptySubtitle: 'Upcoming tasks will appear here automatically.',
              onRefresh: () =>
                  ref.read(maintenanceListNotifierProvider.notifier).load(),
            ),
            _MaintenanceList(
              records: upcoming,
              emptyMessage: 'Schedule looks clear',
              emptySubtitle: 'Add tasks from item details to plan ahead.',
              onRefresh: () =>
                  ref.read(maintenanceListNotifierProvider.notifier).load(),
            ),
            _MaintenanceList(
              records: completed,
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
// List + empty state
// ---------------------------------------------------------------------------

class _MaintenanceList extends StatelessWidget {
  const _MaintenanceList({
    required this.records,
    required this.emptyMessage,
    required this.emptySubtitle,
    required this.onRefresh,
  });

  final List<MaintenanceModel> records;
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
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, 120),
        itemCount: records.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: MaintenanceCard(
            record: records[i],
            onTap: () => context.push(
              '/maintenance/${records[i].id}',
              extra: records[i],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card — matches MovementCard conventions
// ---------------------------------------------------------------------------

class MaintenanceCard extends StatelessWidget {
  const MaintenanceCard({super.key, required this.record, required this.onTap});

  final MaintenanceModel record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = _statusInfo(record);
    final icon = _icon(record);

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
            border: Border.all(color: info.color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              // Icon container
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
                    Text(
                      record.title,
                      style: const TextStyle(
                        color: AppColors.onBackground,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _shortDate(record.scheduledDate),
                          style: TextStyle(
                            color: record.isOverdue || record.isUrgent
                                ? info.color
                                : AppColors.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_urgencyLabel(record) != null) ...[
                          Text(
                            ' · ${_urgencyLabel(record)}',
                            style: TextStyle(
                              color: info.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (record.isRecurring ||
                        (record.isAiSuggested &&
                            record.aiRiskScore != null)) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (record.isRecurring) ...[
                            Icon(Icons.repeat_rounded,
                                size: 11,
                                color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Text(
                              'Every ${record.recurrenceIntervalDays ?? '?'}d',
                              style: const TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          if (record.isAiSuggested &&
                              record.aiRiskScore != null) ...[
                            if (record.isRecurring)
                              const SizedBox(width: AppSpacing.sm),
                            const Icon(Icons.auto_awesome_rounded,
                                size: 11, color: AppColors.accentLight),
                            const SizedBox(width: 3),
                            Text(
                              'Risk ${record.aiRiskScore!.toInt()}%',
                              style: const TextStyle(
                                color: AppColors.accentLight,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Right: chip + short date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(info: info),
                  const SizedBox(height: 6),
                  Text(
                    _veryShortDate(record.scheduledDate),
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(MaintenanceModel r) {
    if (r.isCompleted) return Icons.check_circle_outline_rounded;
    if (r.isAiSuggested) return Icons.auto_awesome_rounded;
    if (r.isRecurring) return Icons.repeat_rounded;
    return Icons.build_outlined;
  }

  String _shortDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat.yMMMd().format(dt);
  }

  String _veryShortDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return DateFormat('MMM d').format(dt);
  }

  String? _urgencyLabel(MaintenanceModel r) {
    final dt = DateTime.tryParse(r.scheduledDate);
    if (dt == null) return null;
    final now = DateTime.now();
    if (r.isOverdue) {
      final days = now.difference(dt).inDays;
      return days <= 0 ? 'due today' : '${days}d overdue';
    }
    final diff = dt.difference(now).inDays;
    if (diff == 0) return 'due today';
    if (diff == 1) return 'tomorrow';
    if (diff <= 7) return 'in $diff days';
    return null;
  }
}

// ---------------------------------------------------------------------------
// Status chip — matches movements _StatusChip exactly
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.info});

  final _StatusInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: info.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          color: info.color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
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

_StatusInfo _statusInfo(MaintenanceModel r) {
  if (r.isOverdue) return const _StatusInfo(Color(0xFFCF6679), 'OVERDUE');
  if (r.isUrgent) return const _StatusInfo(Color(0xFFE07B39), 'URGENT');
  if (r.isDueSoon) return const _StatusInfo(Color(0xFFD4AF37), 'DUE SOON');
  if (r.isCompleted) return const _StatusInfo(Color(0xFF6DB86F), 'DONE');
  if (r.isCancelled) return const _StatusInfo(Color(0xFF9E9E9E), 'CANCELLED');
  return const _StatusInfo(Color(0xFF8A8AA8), 'PENDING');
}
