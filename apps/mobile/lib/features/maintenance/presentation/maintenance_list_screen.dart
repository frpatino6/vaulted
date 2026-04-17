import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.accent,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: renderState.when(
        data:
            (records) => TabBarView(
              controller: _tabController,
              children: [
                _buildTab(records.where((r) => r.isOverdue).toList()),
                _buildTab(records.where((r) => r.isDueSoon).toList()),
                _buildTab(
                  records
                      .where((r) => r.isPending && !r.isDueSoon && !r.isOverdue)
                      .toList(),
                ),
                _buildTab(records.where((r) => r.isCompleted).toList()),
              ],
            ),
        loading: () => const AppScreenSkeleton(showHeader: false),
        error:
            (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  MaintenanceListNotifier.errorMessage(e),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildTab(List<MaintenanceModel> records) {
    if (records.isEmpty) {
      return Center(
        child: Text(
          'No records',
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh:
          () => ref.read(maintenanceListNotifierProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: records.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder:
            (context, index) => _MaintenanceCard(record: records[index]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MaintenanceCard
// ---------------------------------------------------------------------------

class _MaintenanceCard extends ConsumerWidget {
  const _MaintenanceCard({required this.record});

  final MaintenanceModel record;

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
                  Icon(
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _markComplete(context, ref),
                    child: const Text('Mark complete'),
                  ),
                ],
              ),
            ],
          ],
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
