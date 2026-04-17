import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../data/models/insurance_policy_model.dart';
import '../domain/coverage_gaps_notifier.dart';

class CoverageGapsScreen extends ConsumerStatefulWidget {
  const CoverageGapsScreen({super.key, required this.policyId});

  final String policyId;

  @override
  ConsumerState<CoverageGapsScreen> createState() => _CoverageGapsScreenState();
}

class _CoverageGapsScreenState extends ConsumerState<CoverageGapsScreen> {
  bool _initialLoadCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(coverageGapsNotifierProvider.notifier)
          .load(widget.policyId)
          .whenComplete(() {
            if (!mounted) return;
            setState(() => _initialLoadCompleted = true);
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coverageGapsNotifierProvider);
    final showInitialSkeleton =
        !_initialLoadCompleted &&
        !state.hasError &&
        (state.isLoading || state.valueOrNull == null);
    final renderState =
        showInitialSkeleton
            ? const AsyncLoading<CoverageGapReportModel?>()
            : state;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        title: Text(
          'Coverage Gap Analysis',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: renderState.when(
        data:
            (report) =>
                report == null
                    ? const Center(child: Text('No data'))
                    : _buildReport(report),
        loading: () => const AppScreenSkeleton(showHeader: false),
        error:
            (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  CoverageGapsNotifier.message(e),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildReport(CoverageGapReportModel report) {
    final currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final gapItems =
        report.items.where((i) => i.gap > 0 || i.fullyUninsured).toList();
    final coveredItems =
        report.items.where((i) => !i.fullyUninsured && i.gap <= 0).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Inventory Value',
                value: currencyFmt.format(report.totalInventoryValue),
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SummaryCard(
                label: 'Covered',
                value: currencyFmt.format(report.totalCoveredValue),
                color: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _SummaryCard(
          label: 'Total Coverage Gap',
          value: currencyFmt.format(report.totalGap),
          color:
              report.totalGap > 0 ? AppColors.error : const Color(0xFF4CAF50),
          fullWidth: true,
        ),

        // Gap percentage indicator
        if (report.totalInventoryValue > 0) ...[
          const SizedBox(height: AppSpacing.md),
          _buildCoverageBar(report),
        ],

        // Items with gaps
        if (gapItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Items with Coverage Gaps',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...gapItems.map(
            (item) => _GapItemCard(item: item, currencyFmt: currencyFmt),
          ),
        ],

        // Fully covered items
        if (coveredItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Fully Covered Items',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...coveredItems.map(
            (item) => _GapItemCard(
              item: item,
              currencyFmt: currencyFmt,
              isCovered: true,
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildCoverageBar(CoverageGapReportModel report) {
    final pct = (report.totalCoveredValue / report.totalInventoryValue).clamp(
      0.0,
      1.0,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Coverage',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            Text(
              '${(pct * 100).toStringAsFixed(1)}%',
              style: AppTypography.bodySmall.copyWith(
                color:
                    pct >= 0.9
                        ? const Color(0xFF4CAF50)
                        : pct >= 0.5
                        ? AppColors.accent
                        : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              pct >= 0.9
                  ? const Color(0xFF4CAF50)
                  : pct >= 0.5
                  ? AppColors.accent
                  : AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GapItemCard extends StatelessWidget {
  const _GapItemCard({
    required this.item,
    required this.currencyFmt,
    this.isCovered = false,
  });

  final CoverageGapItemModel item;
  final NumberFormat currencyFmt;
  final bool isCovered;

  @override
  Widget build(BuildContext context) {
    final gapColor =
        item.fullyUninsured
            ? AppColors.error
            : item.gap > 0
            ? AppColors.accent
            : const Color(0xFF4CAF50);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isCovered
                  ? const Color(0xFF4CAF50).withOpacity(0.3)
                  : gapColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.itemName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.fullyUninsured)
                _Chip(label: 'Uninsured', color: AppColors.error),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ValueLabel(
                label: 'Item Value',
                value: currencyFmt.format(item.currentValue),
              ),
              if (item.coveredValue != null)
                _ValueLabel(
                  label: 'Covered',
                  value: currencyFmt.format(item.coveredValue!),
                  color: const Color(0xFF4CAF50),
                ),
              _ValueLabel(
                label: 'Gap',
                value: currencyFmt.format(item.gap),
                color: gapColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueLabel extends StatelessWidget {
  const _ValueLabel({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: color ?? AppColors.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
