import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../dashboard/data/models/dashboard_model.dart';
import '../../dashboard/domain/dashboard_notifier.dart';
import '../../users/domain/current_user_jwt.dart';

const List<Color> _categoryColors = [
  Color(0xFFC5A059), // gold
  Color(0xFF8B7355), // dark gold
  Color(0xFF6B6B6B), // medium grey
  Color(0xFF4A4A4A), // dark grey
  Color(0xFFD4B896), // light gold
  Color(0xFF9E9E9E), // light grey
  Color(0xFF3D3D3D), // darker grey
  Color(0xFFB8965A), // amber gold
];

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = currentUserRole() ?? 'guest';
    final canSeeValues = role == 'owner' || role == 'auditor';
    final dashboardState = ref.watch(dashboardNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          'Inventory Reports',
          style: AppTypography.displaySerif.copyWith(
            color: AppColors.onBackground,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md, left: 8),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                foregroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PDF export coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Export PDF'),
            ),
          ),
        ],
      ),
      body: dashboardState.when(
        data: (data) {
          if (data == null) {
            return const Center(child: Text('No dashboard data available'));
          }
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HeroStatCard(data: data),
                    const SizedBox(height: AppSpacing.lg),
                    _CategoryChartCard(data: data),
                    const SizedBox(height: AppSpacing.lg),
                    _StatusCard(data: data),
                    if (canSeeValues) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _AssetValueCard(data: data),
                    ],
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const AppScreenSkeleton(showHeader: false),
        error:
            (error, _) => Center(
              child: Text(
                'Unable to load reports',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.onBackground),
              ),
            ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 2.0,
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    );
  }
}

Widget _sectionCard({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white10, width: 0.5),
    ),
    child: child,
  );
}

class _HeroStatCard extends StatelessWidget {
  const _HeroStatCard({required this.data});

  final DashboardModel data;

  static final _currency = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('TOTAL ASSET VALUE'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _currency.format(data.totalValuation),
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC5A059),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${data.totalItems} items across ${data.totalProperties} properties',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _CategoryChartCard extends StatefulWidget {
  const _CategoryChartCard({required this.data});

  final DashboardModel data;

  @override
  State<_CategoryChartCard> createState() => _CategoryChartCardState();
}

class _CategoryChartCardState extends State<_CategoryChartCard> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final entries =
        data.itemsByCategory.entries.where((e) => e.value > 0).toList();
    final total = data.totalItems;
    final hasData = entries.isNotEmpty && total > 0;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('BY CATEGORY'),
          const SizedBox(height: AppSpacing.lg),
          if (hasData) ...[
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 75,
                  sectionsSpace: 1,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                        } else {
                          _touchedIndex =
                              pieTouchResponse
                                  .touchedSection!
                                  .touchedSectionIndex;
                        }
                      });
                    },
                  ),
                  sections:
                      entries.asMap().entries.map((entry) {
                        final i = entry.key;
                        final e = entry.value;
                        final color =
                            _categoryColors[i % _categoryColors.length];
                        final isTouched = i == _touchedIndex;
                        return PieChartSectionData(
                          value: e.value.toDouble(),
                          color: color,
                          radius: isTouched ? 52 : 45,
                          showTitle: false,
                        );
                      }).toList(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _categoryColors[i % _categoryColors.length],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _capitalize(entries[i].key),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.onBackground),
                        ),
                        const Spacer(),
                        Text(
                          '${entries[i].value}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${total > 0 ? (entries[i].value / total * 100).round() : 0}%',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'No category data',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.data});

  final DashboardModel data;

  @override
  Widget build(BuildContext context) {
    final entries =
        data.itemsByStatus.entries.where((e) => e.value > 0).toList();
    final total = data.totalItems;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('BY STATUS'),
          const SizedBox(height: AppSpacing.lg),
          if (entries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'No status data',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...entries.map((e) {
              final pct = total > 0 ? e.value / total : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    StatusBadge(status: e.key, compact: true),
                    const Spacer(),
                    Text(
                      '${e.value}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onBackground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accent,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AssetValueCard extends StatelessWidget {
  const _AssetValueCard({required this.data});

  final DashboardModel data;

  static final _currency = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('ASSET VALUE'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _currency.format(data.totalValuation),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC5A059),
            ),
          ),
        ],
      ),
    );
  }
}
