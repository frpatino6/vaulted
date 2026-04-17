import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../data/models/maintenance_model.dart';
import '../domain/maintenance_notifier.dart';

class MaintenanceDetailScreen extends ConsumerWidget {
  const MaintenanceDetailScreen({
    super.key,
    required this.maintenanceId,
    this.initialRecord,
  });

  final String maintenanceId;
  final MaintenanceModel? initialRecord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(maintenanceListNotifierProvider);
    final fromState = state.valueOrNull;
    MaintenanceModel? found;
    if (fromState != null) {
      for (final model in fromState) {
        if (model.id == maintenanceId) {
          found = model;
          break;
        }
      }
    }
    final MaintenanceModel? record = initialRecord ?? found;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        title: Text(
          'Maintenance Detail',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body:
          record == null
              ? _MissingDetailState(
                isLoading: state.isLoading,
                onRetry:
                    () =>
                        ref
                            .read(maintenanceListNotifierProvider.notifier)
                            .load(),
              )
              : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _TitleCard(record: record),
                  const SizedBox(height: AppSpacing.md),
                  _MetaCard(record: record),
                  if ((record.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _SectionCard(
                      title: 'Description',
                      child: Text(
                        record.description!.trim(),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.onBackground,
                        ),
                      ),
                    ),
                  ],
                  if ((record.notes ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _SectionCard(
                      title: 'Notes',
                      child: Text(
                        record.notes!.trim(),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.onBackground,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
    );
  }
}

class _TitleCard extends StatelessWidget {
  const _TitleCard({required this.record});

  final MaintenanceModel record;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(record);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (record.isAiSuggested && record.aiRiskScore != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'AI suggested · Risk ${record.aiRiskScore!.toInt()}%',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.accentLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatusBadge(status: record.status, color: statusColor),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.record});

  final MaintenanceModel record;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Schedule',
      child: Column(
        children: [
          _MetaRow(label: 'Scheduled', value: _fmt(record.scheduledDate)),
          _MetaRow(
            label: 'Recurring',
            value: record.isRecurring ? 'Yes' : 'No',
          ),
          if (record.isRecurring && record.recurrenceIntervalDays != null)
            _MetaRow(
              label: 'Interval',
              value: 'Every ${record.recurrenceIntervalDays} days',
            ),
          if (record.completedDate != null)
            _MetaRow(label: 'Completed', value: _fmt(record.completedDate!)),
          if ((record.providerName ?? '').trim().isNotEmpty)
            _MetaRow(label: 'Provider', value: record.providerName!.trim()),
          if ((record.providerContact ?? '').trim().isNotEmpty)
            _MetaRow(label: 'Contact', value: record.providerContact!.trim()),
          if (record.cost != null)
            _MetaRow(
              label: 'Cost',
              value: NumberFormat.currency(
                symbol: record.currency == 'USD' ? r'$' : '${record.currency} ',
                decimalDigits: 2,
              ).format(record.cost),
            ),
        ],
      ),
    );
  }

  String _fmt(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;
    return DateFormat.yMMMd().add_jm().format(dt);
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onBackground,
              ),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MissingDetailState extends StatelessWidget {
  const _MissingDetailState({required this.isLoading, required this.onRetry});

  final bool isLoading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, color: AppColors.onSurfaceVariant),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Could not load maintenance detail.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload List'),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(MaintenanceModel r) {
  if (r.isOverdue) return const Color(0xFFCF6679);
  if (r.isUrgent) return const Color(0xFFE07B39);
  if (r.isDueSoon) return const Color(0xFFD4AF37);
  if (r.isCompleted) return const Color(0xFF6DB86F);
  return const Color(0xFF6A6A7E);
}
