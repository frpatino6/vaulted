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
    final totalGap = report.totalUncoveredValue + report.totalUnderinsuredGap;
    final isEmpty = report.uncovered.isEmpty && report.underinsured.isEmpty;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Uninsured Gap',
                value: currencyFmt.format(report.totalUncoveredValue),
                color: report.totalUncoveredValue > 0
                    ? AppColors.error
                    : const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SummaryCard(
                label: 'Underinsured Gap',
                value: currencyFmt.format(report.totalUnderinsuredGap),
                color: report.totalUnderinsuredGap > 0
                    ? AppColors.accent
                    : const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _SummaryCard(
          label: 'Total Coverage Gap',
          value: currencyFmt.format(totalGap),
          color: totalGap > 0 ? AppColors.error : const Color(0xFF4CAF50),
          fullWidth: true,
        ),

        if (isEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              'All items are fully covered.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],

        // Uninsured items
        if (report.uncovered.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Uninsured Items',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...report.uncovered.map(
            (item) => _GapItemCard(
              item: item,
              currencyFmt: currencyFmt,
              fullyUninsured: true,
            ),
          ),
        ],

        // Underinsured items
        if (report.underinsured.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Underinsured Items',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...report.underinsured.map(
            (item) => _GapItemCard(
              item: item,
              currencyFmt: currencyFmt,
              fullyUninsured: false,
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
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
    required this.fullyUninsured,
  });

  final CoverageGapItemModel item;
  final NumberFormat currencyFmt;
  final bool fullyUninsured;

  @override
  Widget build(BuildContext context) {
    final gapColor = fullyUninsured
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
        border: Border.all(color: gapColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (fullyUninsured)
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
              if (!fullyUninsured)
                _ValueLabel(
                  label: 'Covered',
                  value: currencyFmt.format(item.coveredValue),
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
