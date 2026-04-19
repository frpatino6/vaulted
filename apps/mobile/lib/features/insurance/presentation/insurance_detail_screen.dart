import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../data/models/insurance_policy_model.dart';
import '../domain/insurance_detail_notifier.dart';
import '../domain/insurance_list_notifier.dart';
import 'attach_item_sheet.dart';
import 'coverage_ai_analysis_sheet.dart';

class InsuranceDetailScreen extends ConsumerStatefulWidget {
  const InsuranceDetailScreen({super.key, required this.policyId});

  final String policyId;

  @override
  ConsumerState<InsuranceDetailScreen> createState() =>
      _InsuranceDetailScreenState();
}

class _InsuranceDetailScreenState extends ConsumerState<InsuranceDetailScreen> {
  bool _initialLoadCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(insuranceDetailNotifierProvider.notifier)
          .load(widget.policyId)
          .whenComplete(() {
            if (!mounted) return;
            setState(() => _initialLoadCompleted = true);
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(insuranceDetailNotifierProvider);
    final showInitialSkeleton =
        !_initialLoadCompleted &&
        !state.hasError &&
        (state.isLoading || state.valueOrNull == null);
    final renderState =
        showInitialSkeleton
            ? const AsyncLoading<InsurancePolicyModel?>()
            : state;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: renderState.when(
        data:
            (policy) =>
                policy == null
                    ? const Center(child: Text('Policy not found'))
                    : _buildContent(context, policy),
        loading: () => const AppScreenSkeleton(showHeader: false),
        error:
            (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  InsuranceDetailNotifier.message(e),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, InsurancePolicyModel policy) {
    final currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.onBackground,
          pinned: true,
          title: Text(
            policy.provider,
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_awesome_outlined),
              color: AppColors.accentLight,
              tooltip: 'AI Analysis',
              onPressed: () => _showAiAnalysisSheet(context, policy.id),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.accent,
              onPressed: () async {
                await context.push(
                  '/insurance/${policy.id}/edit',
                  extra: policy,
                );
                if (context.mounted) {
                  ref
                      .read(insuranceDetailNotifierProvider.notifier)
                      .load(widget.policyId);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              onPressed: () => _confirmDelete(context, policy),
            ),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Status + coverage type
              Row(
                children: [
                  _StatusBadge(status: policy.status),
                  const SizedBox(width: AppSpacing.sm),
                  _InfoChip(
                    label: policy.coverageTypeLabel,
                    icon: Icons.category_outlined,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Coverage amount card
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Coverage',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFmt.format(policy.totalCoverageAmount),
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (policy.premium != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Premium: ${currencyFmt.format(policy.premium!)} / year',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Policy details
              _SectionCard(
                child: Column(
                  children: [
                    _DetailRow('Policy Number', policy.policyNumber),
                    _DetailRow('Coverage Type', policy.coverageTypeLabel),
                    _DetailRow('Currency', policy.currency),
                    _DetailRow('Start Date', _fmtDate(policy.startDate)),
                    _DetailRow(
                      'Expires',
                      _fmtDate(policy.expiresAt),
                      valueColor:
                          policy.isExpiringSoon ? AppColors.error : null,
                    ),
                    if (policy.notes != null && policy.notes!.isNotEmpty)
                      _DetailRow('Notes', policy.notes!),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Insured items section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Insured Items',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.onBackground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed:
                            () => context.push('/insurance/${policy.id}/gaps'),
                        icon: Icon(
                          Icons.analytics_outlined,
                          size: 16,
                          color: AppColors.accentLight,
                        ),
                        label: Text(
                          'Gap Analysis',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.accentLight,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.accent,
                        onPressed: () => _showAttachSheet(context, policy.id),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              if (policy.insuredItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: Text(
                      'No items attached to this policy.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...policy.insuredItems.map(
                  (item) => _InsuredItemRow(
                    item: item,
                    onDetach: () => _detachItem(item.itemId),
                  ),
                ).toList(),

              const SizedBox(height: AppSpacing.xl),
            ]),
          ),
        ),
      ],
    );
  }

  void _showAttachSheet(BuildContext context, String policyId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => AttachItemSheet(
            policyId: policyId,
            onAttached: (itemId, coveredValue, currency) async {
              await ref
                  .read(insuranceDetailNotifierProvider.notifier)
                  .attachItem(
                    policyId,
                    itemId: itemId,
                    coveredValue: coveredValue,
                    currency: currency,
                  );
            },
          ),
    );
  }

  void _showAiAnalysisSheet(BuildContext context, String policyId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CoverageAiAnalysisSheet(policyId: policyId),
    );
  }

  Future<void> _detachItem(String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              'Remove Item',
              style: TextStyle(color: AppColors.onBackground),
            ),
            content: Text(
              'Remove this item from the policy?',
              style: TextStyle(color: AppColors.onSurface),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.onSurface),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Remove', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ref
          .read(insuranceDetailNotifierProvider.notifier)
          .detachItem(widget.policyId, itemId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(InsuranceDetailNotifier.message(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    InsurancePolicyModel policy,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              'Delete Policy',
              style: TextStyle(color: AppColors.onBackground),
            ),
            content: Text(
              'Delete "${policy.provider} – ${policy.policyNumber}"? This cannot be undone.',
              style: TextStyle(color: AppColors.onSurface),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.onSurface),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ref
          .read(insuranceListNotifierProvider.notifier)
          .deletePolicy(policy.id);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(InsuranceListNotifier.message(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _fmtDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('MMM d, yyyy').format(dt);
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
              style: AppTypography.bodySmall.copyWith(
                color: valueColor ?? AppColors.onBackground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsuredItemRow extends StatefulWidget {
  const _InsuredItemRow({required this.item, required this.onDetach});

  final InsuredItemModel item;
  final Future<void> Function() onDetach;

  @override
  State<_InsuredItemRow> createState() => _InsuredItemRowState();
}

class _InsuredItemRowState extends State<_InsuredItemRow> {
  bool _loading = false;

  Future<void> _handleDetach() async {
    setState(() => _loading = true);
    try {
      await widget.onDetach();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 18,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              widget.item.itemName.isNotEmpty
                  ? widget.item.itemName
                  : widget.item.itemId,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            currencyFmt.format(widget.item.coveredValue),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 24,
            height: 24,
            child: _loading
                ? Padding(
                    padding: const EdgeInsets.all(4),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.error),
                    ),
                  )
                : GestureDetector(
                    onTap: _handleDetach,
                    child:
                        Icon(Icons.close, size: 16, color: AppColors.error),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'active':
        color = const Color(0xFF4CAF50);
        break;
      case 'expired':
        color = AppColors.error;
        break;
      default:
        color = AppColors.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: AppTypography.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
