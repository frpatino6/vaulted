import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../users/domain/current_user_jwt.dart';
import '../data/models/movement_model.dart';
import '../domain/movement_list_notifier.dart';
import '../domain/active_movement_notifier.dart';
import 'new_movement_sheet.dart';
import 'package:vaulted/shared/widgets/help_screen_button.dart';


// ---------------------------------------------------------------------------
// Color tokens — WCAG AA compliant on #1C1C26 (surfaceVariant)
// ---------------------------------------------------------------------------

const _kGreen  = Color(0xFF81C784); // Cataloged  — 6.9:1 on surfaceVariant
const _kPurple = Color(0xFFCE93D8); // Loan       — 7.3:1
const _kOrange = Color(0xFFFFB74D); // Repair     — 7.1:1
const _kRed    = Color(0xFFEF9A9A); // Disposal   — 6.8:1
const _kBlue   = Color(0xFF64B5F6); // Transfer   — 6.8:1

// ---------------------------------------------------------------------------

const _kMuted = Color(0xFF8E8E9E);
const _kFieldSurface = Color(0xFF13131C);
const _kOutline = Color(0xFF252530);

class MovementsScreen extends ConsumerStatefulWidget {
  const MovementsScreen({super.key});

  @override
  ConsumerState<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends ConsumerState<MovementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedType;
  bool _initialLoadCompleted = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(movementListNotifierProvider.notifier).load().whenComplete(() {
        if (!mounted) return;
        setState(() => _initialLoadCompleted = true);
      });
      ref.read(activeMovementNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<MovementModel> _applyFilters(List<MovementModel> movements) {
    final q = _searchController.text.trim().toLowerCase();
    return movements.where((m) {
      final matchesType =
          _selectedType == null || m.operationType == _selectedType;
      final matchesQuery = q.isEmpty ||
          m.title.toLowerCase().contains(q) ||
          m.destination.toLowerCase().contains(q);
      return matchesType && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final role = currentUserRole() ?? 'guest';
    final canOperate = role == 'owner' || role == 'manager';
    final listState = ref.watch(movementListNotifierProvider);
    final showInitialSkeleton =
        !_initialLoadCompleted &&
        !listState.hasError &&
        (listState.isLoading || (listState.valueOrNull?.isEmpty ?? true));
    final renderListState =
        showInitialSkeleton
            ? const AsyncLoading<List<MovementModel>>()
            : listState;
    final draftState = ref.watch(activeMovementNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.onBackground,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Operations',
          style: TextStyle(
            color: AppColors.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [const HelpScreenButton(screenKey: 'movements')],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Column(
            children: [
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.surfaceVariant,
              ),
              TabBar(
                controller: _tabs,
                indicatorColor: AppColors.accent,
                indicatorWeight: 2,
                labelColor: AppColors.accent,
                unselectedLabelColor: AppColors.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                tabs: const [Tab(text: 'Active'), Tab(text: 'History')],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          _SearchAndFilterBar(
            controller: _searchController,
            selectedType: _selectedType,
            onTypeSelected: (t) => setState(() => _selectedType = t),
          ),
          if (draftState.value != null && draftState.value!.isNotEmpty)
            _DraftBannerList(
              drafts: draftState.value!,
              onResume: (m) => context.push('/movements/${m.id}/scan'),
            ),
          Expanded(
            child: renderListState.when(
              data: (all) {
                final active = _applyFilters(
                    all.where((m) => m.isDraft || m.isActive).toList());
                final history =
                    _applyFilters(all.where((m) => m.isFinished).toList());

                return TabBarView(
                  controller: _tabs,
                  children: [
                    _MovementList(
                      movements: active,
                      emptyMessage: 'No active operations',
                      emptySubtitle: canOperate
                          ? 'Tap + to start a new operation'
                          : 'No operations in progress',
                      onRefresh: () =>
                          ref.read(movementListNotifierProvider.notifier).load(),
                    ),
                    _MovementList(
                      movements: history,
                      emptyMessage: 'No history yet',
                      emptySubtitle: 'Completed operations will appear here',
                      onRefresh: () =>
                          ref.read(movementListNotifierProvider.notifier).load(),
                    ),
                  ],
                );
              },
              loading: () =>
                  const AppScreenSkeleton(showHeader: false, cardCount: 5),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        color: AppColors.error, size: 40),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      MovementListNotifier.message(e),
                      style:
                          const TextStyle(color: AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () =>
                          ref.read(movementListNotifierProvider.notifier).load(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canOperate
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              elevation: 8,
              highlightElevation: 12,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'New Operation',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
              onPressed: () => _startNewMovement(context),
            )
          : null,
    );
  }

  void _startNewMovement(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NewMovementSheet(
        onCreated: (movement) {
          context.push('/movements/${movement.id}/scan');
        },
      ),
    ).then((_) {
      ref.read(movementListNotifierProvider.notifier).load();
    });
  }
}

// ---------------------------------------------------------------------------
// Draft recovery banner
// ---------------------------------------------------------------------------

class _DraftBannerList extends StatelessWidget {
  const _DraftBannerList({required this.drafts, required this.onResume});

  final List<MovementModel> drafts;
  final void Function(MovementModel) onResume;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: drafts.map((m) {
        return Semantics(
          button: true,
          label: 'Resume draft operation ${m.title}',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Material(
              color: AppColors.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => onResume(m),
                borderRadius: BorderRadius.circular(12),
                splashColor: AppColors.accent.withValues(alpha: 0.08),
                highlightColor: AppColors.accent.withValues(alpha: 0.05),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pending_rounded,
                        color: AppColors.accent,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Draft in progress',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.title,
                              style: const TextStyle(
                                color: AppColors.onBackground,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Resume',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
// ---------------------------------------------------------------------------
// Movement list
// ---------------------------------------------------------------------------

class _MovementList extends StatelessWidget {
  const _MovementList({
    required this.movements,
    required this.emptyMessage,
    required this.emptySubtitle,
    required this.onRefresh,
  });

  final List<MovementModel> movements;
  final String emptyMessage;
  final String emptySubtitle;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surfaceVariant,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.52,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 52,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      emptyMessage,
                      style: const TextStyle(
                        color: AppColors.onBackground,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      emptySubtitle,
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surfaceVariant,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, 110),
        itemCount: movements.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: MovementCard(movement: movements[i]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Movement card
// ---------------------------------------------------------------------------

class MovementCard extends StatelessWidget {
  const MovementCard({super.key, required this.movement});

  final MovementModel movement;

  @override
  Widget build(BuildContext context) {
    final typeInfo = _typeInfo(movement.operationType);
    final statusInfo = _statusInfo(movement.status);
    final hasLocation = movement.destination.isNotEmpty;
    final isActive = movement.isActive;
    final total = movement.items.length;
    final returned = movement.returnedCount;
    final progress = total > 0 ? returned / total : 0.0;

    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.24),
      child: InkWell(
        onTap: () => context.push('/movements/${movement.id}'),
        borderRadius: BorderRadius.circular(14),
        splashColor: typeInfo.color.withValues(alpha: 0.06),
        highlightColor: typeInfo.color.withValues(alpha: 0.04),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? typeInfo.color.withValues(alpha: 0.25)
                  : _kOutline,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Left: type icon ──────────────────────────────────────────
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: typeInfo.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(typeInfo.icon,
                    color: typeInfo.color, size: 20),
              ),
              const SizedBox(width: 12),

              // ── Center: text content ─────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title — first letter capitalized to handle user-entered lowercase titles
                    Text(
                      _capitalizeFirst(movement.title),
                      style: const TextStyle(
                        color: AppColors.onBackground,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Type label — neutral text + colored dot (WCAG AA)
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: typeInfo.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            typeInfo.label,
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Location row — only if destination is set
                    if (hasLocation) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              movement.destination,
                              style: const TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 5),

                    // Metadata: item count
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 10,
                          color: AppColors.onSurfaceVariant
                              .withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$total item${total == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant
                                .withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    // Progress bar — only for active movements
                    if (isActive && total > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 3,
                                backgroundColor: AppColors.onSurfaceVariant
                                    .withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress == 1.0
                                      ? const Color(0xFF81C784)
                                      : typeInfo.color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$returned/$total',
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ── Right: status + date ─────────────────────────────────────
              SizedBox(
                width: 84,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatusChip(status: movement.status, info: statusInfo),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _formatDate(movement.createdAt),
                      style: TextStyle(
                        color:
                            AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      return DateFormat('MMM d').format(DateTime.parse(iso));
    } catch (_) {
      return '';
    }
  }

  String _capitalizeFirst(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

// ---------------------------------------------------------------------------
// Status chip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.info});

  final String status;
  final _StatusInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: info.color.withValues(alpha: 0.28), width: 1),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          color: info.color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Type & Status metadata
// ---------------------------------------------------------------------------

class _TypeInfo {
  const _TypeInfo(this.icon, this.color, this.label);
  final IconData icon;
  final Color color;
  final String label;
}

class _StatusInfo {
  const _StatusInfo(this.color, this.label);
  final Color color;
  final String label;
}

_TypeInfo _typeInfo(String type) => switch (type) {
      'creation' => const _TypeInfo(
          Icons.add_circle_outline_rounded, _kGreen, 'Cataloged'),
      'loan' => const _TypeInfo(
          Icons.person_outline_rounded, _kPurple, 'Loan'),
      'repair' => const _TypeInfo(
          Icons.build_outlined, _kOrange, 'Repair'),
      'disposal' => const _TypeInfo(
          Icons.delete_outline_rounded, _kRed, 'Disposal'),
      _ => const _TypeInfo(
          Icons.swap_horiz_rounded, _kBlue, 'Transfer'),
    };

_StatusInfo _statusInfo(String status) => switch (status) {
      'draft' => const _StatusInfo(_kMuted, 'DRAFT'),
      'active' => const _StatusInfo(_kBlue, 'ACTIVE'),
      'completed' => const _StatusInfo(_kGreen, 'DONE'),
      'partial' => const _StatusInfo(_kOrange, 'PARTIAL'),
      'cancelled' => const _StatusInfo(_kMuted, 'CANCELLED'),
      _ => const _StatusInfo(_kMuted, 'UNKNOWN'),
    };

// Public helpers for other screens
_TypeInfo movementTypeInfo(String type) => _typeInfo(type);
_StatusInfo movementStatusInfo(String status) => _statusInfo(status);

// ---------------------------------------------------------------------------
// Search & filter bar
// ---------------------------------------------------------------------------

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({
    required this.controller,
    required this.selectedType,
    required this.onTypeSelected,
  });

  final TextEditingController controller;
  final String? selectedType;
  final ValueChanged<String?> onTypeSelected;

  static const _types = [
    ('repair',   Icons.build_outlined,          _kOrange, 'Repair'),
    ('loan',     Icons.person_outline_rounded,  _kPurple, 'Loan'),
    ('transfer', Icons.swap_horiz_rounded,      _kBlue,   'Transfer'),
    ('disposal', Icons.delete_outline_rounded,  _kRed,    'Disposal'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: TextField(
              controller: controller,
              style: const TextStyle(
                  color: AppColors.onBackground, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name or destination…',
                hintStyle: const TextStyle(
                    color: AppColors.onSurfaceVariant, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.onSurfaceVariant, size: 18),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.onSurfaceVariant, size: 16),
                        onPressed: () => controller.clear(),
                      )
                    : null,
                filled: true,
                fillColor: _kFieldSurface,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kOutline, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kOutline, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.6),
                      width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Chips with trailing fade
          Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 36),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      icon: Icons.apps_rounded,
                      color: AppColors.accent,
                      selected: selectedType == null,
                      onTap: () => onTypeSelected(null),
                    ),
                    const SizedBox(width: 6),
                    ..._types.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _FilterChip(
                          label: t.$4,
                          icon: t.$2,
                          color: t.$3,
                          selected: selectedType == t.$1,
                          onTap: () => onTypeSelected(
                              selectedType == t.$1 ? null : t.$1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Trailing fade mask
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.background.withValues(alpha: 0),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Filter by $label operations',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withValues(alpha: 0.08),
          highlightColor: color.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color:
                  selected ? color.withValues(alpha: 0.15) : _kFieldSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? color.withValues(alpha: 0.55) : _kOutline,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected ? color : AppColors.onSurface,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? color : AppColors.onSurface,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
