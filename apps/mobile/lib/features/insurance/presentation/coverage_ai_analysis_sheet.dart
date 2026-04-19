import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../data/models/insurance_ai_model.dart';
import '../domain/coverage_gaps_notifier.dart';
import '../domain/insurance_ai_notifier.dart';
import '../domain/insurance_detail_notifier.dart';

/// Bottom sheet that displays AI-powered coverage analysis for an insurance policy.
class CoverageAiAnalysisSheet extends ConsumerStatefulWidget {
  const CoverageAiAnalysisSheet({super.key, required this.policyId});

  final String policyId;

  @override
  ConsumerState<CoverageAiAnalysisSheet> createState() =>
      _CoverageAiAnalysisSheetState();
}

class _CoverageAiAnalysisSheetState
    extends ConsumerState<CoverageAiAnalysisSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(coverageAnalysisNotifierProvider.notifier)
          .load(widget.policyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(coverageAnalysisNotifierProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: analysisState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
            error: (e, _) => _ErrorView(
              message: CoverageAnalysisNotifier.message(e),
              onRetry: () => ref
                  .read(coverageAnalysisNotifierProvider.notifier)
                  .load(widget.policyId),
            ),
            data: (analysis) => analysis == null
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  )
                : _AnalysisContent(
                    analysis: analysis,
                    policyId: widget.policyId,
                    scrollController: scrollController,
                  ),
          ),
        );
      },
    );
  }
}

class _AnalysisContent extends ConsumerStatefulWidget {
  const _AnalysisContent({
    required this.analysis,
    required this.policyId,
    required this.scrollController,
  });

  final CoverageAnalysisModel analysis;
  final String policyId;
  final ScrollController scrollController;

  @override
  ConsumerState<_AnalysisContent> createState() => _AnalysisContentState();
}

class _AnalysisContentState extends ConsumerState<_AnalysisContent> {
  final Set<String> _attaching = {};

  Future<void> _showAttachDialog(
      BuildContext context, String itemId, String itemName) async {
    final report = ref.read(coverageGapsNotifierProvider).valueOrNull;
    var initialCoveredText = '';
    if (report != null) {
      for (final i in report.uncovered) {
        if (i.itemId == itemId) {
          initialCoveredText = i.currentValue.toString();
          break;
        }
      }
      if (initialCoveredText.isEmpty) {
        for (final i in report.underinsured) {
          if (i.itemId == itemId) {
            initialCoveredText = i.currentValue.toString();
            break;
          }
        }
      }
    }
    final valueCtrl = TextEditingController(text: initialCoveredText);
    String currency = 'USD';
    String? error;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Add to Policy',
            style: TextStyle(color: AppColors.onBackground),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                itemName,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: valueCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: TextStyle(color: AppColors.onBackground),
                      decoration: InputDecoration(
                        labelText: 'Covered Value',
                        labelStyle:
                            TextStyle(color: AppColors.onSurfaceVariant),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: currency,
                      dropdownColor: AppColors.surfaceVariant,
                      style: TextStyle(color: AppColors.onBackground),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: ['USD', 'EUR', 'GBP']
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) =>
                          setLocal(() => currency = v ?? 'USD'),
                    ),
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(error!,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.error)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: TextStyle(color: AppColors.onSurface)),
            ),
            TextButton(
              onPressed: () {
                final v = double.tryParse(valueCtrl.text.trim());
                if (v == null || v <= 0) {
                  setLocal(() => error = 'Enter a valid value.');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text('Attach',
                  style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final coveredValue =
        double.tryParse(valueCtrl.text.trim()) ?? 0;

    setState(() => _attaching.add(itemId));
    try {
      await ref
          .read(insuranceDetailNotifierProvider.notifier)
          .attachItem(
            widget.policyId,
            itemId: itemId,
            coveredValue: coveredValue,
            currency: currency,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$itemName added to policy.'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(InsuranceDetailNotifier.message(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _attaching.remove(itemId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Title row + risk badge
        Row(
          children: [
            Expanded(
              child: Text(
                'AI Coverage Analysis',
                style: AppTypography.titleLarge
                    .copyWith(color: AppColors.onBackground),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _RiskBadge(risk: widget.analysis.overallRisk),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Summary
        Text(
          widget.analysis.summary,
          style:
              AppTypography.bodyMedium.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),

        // Renewal urgency warning
        if (widget.analysis.renewalUrgency != 'none') ...[
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_outlined,
                    color: AppColors.error, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Policy renewal is ${widget.analysis.renewalUrgency}',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Recommendations
        if (widget.analysis.recommendations.isNotEmpty) ...[
          Text(
            'Recommendations',
            style: AppTypography.titleMedium
                .copyWith(color: AppColors.onBackground),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...widget.analysis.recommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      rec,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Priority items
        if (widget.analysis.priorityItems.isNotEmpty) ...[
          Text(
            'Priority Items',
            style: AppTypography.titleMedium
                .copyWith(color: AppColors.onBackground),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...widget.analysis.priorityItems.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemName,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.onBackground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.issue,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.onSurface),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: _attaching.contains(item.itemId)
                        ? Padding(
                            padding: const EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.accent),
                            ),
                          )
                        : IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.add_circle_outline,
                                size: 20, color: AppColors.accent),
                            tooltip: 'Add to policy',
                            onPressed: () => _showAttachDialog(
                                context, item.itemId, item.itemName),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Draft a claim button
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
            context.push('/insurance/${widget.policyId}/claim-draft');
          },
          icon: Icon(Icons.description_outlined,
              size: 16, color: AppColors.accentLight),
          label: Text(
            'Draft a Claim',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.accentLight),
          ),
        ),
      ],
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.risk});

  final String risk;

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (risk) {
      case 'low':
        color = const Color(0xFF4CAF50);
        break;
      case 'high':
        color = const Color(0xFFFF9800);
        break;
      case 'critical':
        color = AppColors.error;
        break;
      default:
        color = AppColors.accent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        risk[0].toUpperCase() + risk.substring(1),
        style: AppTypography.labelLarge
            .copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.accentLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
