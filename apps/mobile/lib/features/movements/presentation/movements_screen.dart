import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../users/domain/current_user_jwt.dart';
import '../data/models/movement_model.dart';
import '../domain/movement_list_notifier.dart';
import '../domain/active_movement_notifier.dart';
import 'new_movement_sheet.dart';

class MovementsScreen extends ConsumerStatefulWidget {
  const MovementsScreen({super.key});

  @override
  ConsumerState<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends ConsumerState<MovementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(movementListNotifierProvider.notifier).load();
      ref.read(activeMovementNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = currentUserRole() ?? 'guest';
    final canOperate = role == 'owner' || role == 'manager';
    final listState = ref.watch(movementListNotifierProvider);
    final draftState = ref.watch(activeMovementNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.onBackground, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Operations',
          style: TextStyle(
            color: AppColors.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Draft recovery banners — show one banner per active draft
          if (draftState.value != null && draftState.value!.isNotEmpty)
            _DraftBannerList(
              drafts: draftState.value!,
              onResume: (m) => context.push('/movements/${m.id}/scan'),
            ),
          Expanded(
            child: listState.when(
              data: (all) {
                final active = all
                    .where((m) => m.isDraft || m.isActive)
                    .toList();
                final history = all
                    .where((m) => m.isFinished)
                    .toList();

                return TabBarView(
                  controller: _tabs,
                  children: [
                    _MovementList(
                      movements: active,
                      emptyMessage: 'No active operations',
                      emptySubtitle: canOperate
                          ? 'Tap + to start a new operation'
                          : 'No operations in progress',
                      onRefresh: () => ref
                          .read(movementListNotifierProvider.notifier)
                          .load(),
                    ),
                    _MovementList(
                      movements: history,
                      emptyMessage: 'No history yet',
                      emptySubtitle:
                          'Completed operations will appear here',
                      onRefresh: () => ref
                          .read(movementListNotifierProvider.notifier)
                          .load(),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        color: AppColors.error, size: 40),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      MovementListNotifier.message(e),
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () => ref
                          .read(movementListNotifierProvider.notifier)
                          .load(),
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
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Operation',
                  style: TextStyle(fontWeight: FontWeight.w600)),
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

class _DraftBannerList extends StatelessWidget {
  const _DraftBannerList({required this.drafts, required this.onResume});

  final List<MovementModel> drafts;
  final void Function(MovementModel) onResume;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: drafts
          .map(
            (m) => GestureDetector(
              onTap: () => onResume(m),
              child: Container(
                margin: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pending_rounded,
                        color: AppColors.accent, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Draft in progress',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            m.title,
                            style: TextStyle(
                                color: AppColors.onBackground, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Resume →',
                      style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_horiz_rounded,
                  size: 56,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.3)),
              const SizedBox(height: AppSpacing.md),
              Text(
                emptyMessage,
                style: TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 17,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                emptySubtitle,
                style: TextStyle(
                    color: AppColors.onSurfaceVariant, fontSize: 14),
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

class MovementCard extends StatelessWidget {
  const MovementCard({super.key, required this.movement});

  final MovementModel movement;

  @override
  Widget build(BuildContext context) {
    final typeInfo = _typeInfo(movement.operationType);
    final statusInfo = _statusInfo(movement.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/movements/${movement.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusInfo.color.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeInfo.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeInfo.icon, color: typeInfo.color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.title,
                      style: TextStyle(
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
                          typeInfo.label,
                          style: TextStyle(
                              color: typeInfo.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                        if (movement.destination.isNotEmpty) ...[
                          Text(
                            ' · ${movement.destination}',
                            style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 11,
                            color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(
                          '${movement.items.length} item${movement.items.length == 1 ? '' : 's'}',
                          style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11),
                        ),
                        if (movement.isActive) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${movement.returnedCount}/${movement.items.length} returned',
                            style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(status: movement.status, info: statusInfo),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(movement.createdAt),
                    style: TextStyle(
                        color: AppColors.onSurfaceVariant, fontSize: 10),
                  ),
                ],
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
}

// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.info});

  final String status;
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
// Type & Status helpers
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
      'loan' => const _TypeInfo(
          Icons.person_outline_rounded, Color(0xFF9C27B0), 'Loan'),
      'repair' => const _TypeInfo(
          Icons.build_outlined, Color(0xFFFF9800), 'Repair'),
      'disposal' => const _TypeInfo(
          Icons.delete_outline_rounded, Color(0xFFCF6679), 'Disposal'),
      _ => const _TypeInfo(
          Icons.swap_horiz_rounded, Color(0xFF2196F3), 'Transfer'),
    };

_StatusInfo _statusInfo(String status) => switch (status) {
      'draft' =>
        const _StatusInfo(Color(0xFF9E9E9E), 'DRAFT'),
      'active' =>
        const _StatusInfo(Color(0xFF2196F3), 'ACTIVE'),
      'completed' =>
        const _StatusInfo(Color(0xFF4CAF50), 'DONE'),
      'partial' =>
        const _StatusInfo(Color(0xFFFF9800), 'PARTIAL'),
      'cancelled' =>
        const _StatusInfo(Color(0xFF9E9E9E), 'CANCELLED'),
      _ => const _StatusInfo(Color(0xFF9E9E9E), 'UNKNOWN'),
    };

// Expose helpers for other screens
_TypeInfo movementTypeInfo(String type) => _typeInfo(type);
_StatusInfo movementStatusInfo(String status) => _statusInfo(status);
