import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../data/models/insurance_policy_model.dart';
import '../domain/insurance_list_notifier.dart';

class InsuranceListScreen extends ConsumerStatefulWidget {
  const InsuranceListScreen({super.key});

  @override
  ConsumerState<InsuranceListScreen> createState() =>
      _InsuranceListScreenState();
}

class _InsuranceListScreenState extends ConsumerState<InsuranceListScreen> {
  bool _initialLoadCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(insuranceListNotifierProvider.notifier).load().whenComplete(() {
        if (!mounted) return;
        setState(() => _initialLoadCompleted = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(insuranceListNotifierProvider);
    final showInitialSkeleton =
        !_initialLoadCompleted &&
        !state.hasError &&
        (state.isLoading || (state.valueOrNull?.isEmpty ?? true));
    final renderState =
        showInitialSkeleton
            ? const AsyncLoading<List<InsurancePolicyModel>>()
            : state;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: AppBottomNav(currentTab: AppTab.insurance),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        title: Text(
          'Insurance',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            color: AppColors.accent,
            onPressed: () async {
              await context.push('/insurance/new');
              if (context.mounted) {
                ref.read(insuranceListNotifierProvider.notifier).refresh();
              }
            },
          ),
        ],
      ),
      body: renderState.when(
        data:
            (policies) =>
                policies.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                      onRefresh:
                          () =>
                              ref
                                  .read(insuranceListNotifierProvider.notifier)
                                  .refresh(),
                      color: AppColors.accent,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: policies.length,
                        itemBuilder:
                            (context, index) =>
                                _PolicyCard(policy: policies[index]),
                      ),
                    ),
        loading: () => const AppScreenSkeleton(showHeader: false),
        error:
            (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  InsuranceListNotifier.message(e),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 64,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No insurance policies',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap + to add your first policy.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyCard extends ConsumerWidget {
  const _PolicyCard({required this.policy});

  final InsurancePolicyModel policy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/insurance/${policy.id}'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        policy.provider,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.onBackground,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusBadge(status: policy.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  policy.policyNumber,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoChip(
                      label: policy.coverageTypeLabel,
                      icon: Icons.category_outlined,
                    ),
                    Text(
                      currencyFmt.format(policy.totalCoverageAmount),
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expires ${_fmtDate(policy.expiresAt)}',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            policy.isExpiringSoon
                                ? AppColors.error
                                : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${policy.insuredItems.length} item${policy.insuredItems.length == 1 ? '' : 's'}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('MMM d, yyyy').format(dt);
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
