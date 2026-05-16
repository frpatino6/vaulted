import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../inventory/data/models/item_model.dart';
import '../../inventory/data/search_remote_data_source_provider.dart';
import '../../users/domain/current_user_jwt.dart';
import '../data/models/orchestrator_plan_model.dart';
import '../domain/orchestrator_detail_notifier.dart';
import 'orchestrator_assign_sheet.dart';

class OrchestratorPlanDetailScreen extends ConsumerStatefulWidget {
  const OrchestratorPlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<OrchestratorPlanDetailScreen> createState() =>
      _OrchestratorPlanDetailScreenState();
}

class _OrchestratorPlanDetailScreenState
    extends ConsumerState<OrchestratorPlanDetailScreen> {
  bool _initialLoadCompleted = false;
  bool _publishing = false;
  bool _cancelling = false;

  String get _role => currentUserRole() ?? 'guest';
  bool get _isOwnerOrManager => _role == 'owner' || _role == 'manager';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(orchestratorDetailNotifierProvider.notifier)
          .load(widget.planId)
          .whenComplete(() {
        if (!mounted) return;
        setState(() => _initialLoadCompleted = true);
      });
    });
  }

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() => _publishing = true);
    try {
      await ref
          .read(orchestratorDetailNotifierProvider.notifier)
          .publish();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan published — staff notified!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(OrchestratorDetailNotifier.errorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _cancel() async {
    final currentPlan = ref.read(orchestratorDetailNotifierProvider).valueOrNull;
    final isDraft = currentPlan?.status == 'draft';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: Text(isDraft ? 'Delete Draft' : 'Cancel Plan'),
        content: Text(
          isDraft
              ? 'This draft plan will be permanently deleted.'
              : 'This plan will be marked cancelled and cannot be reactivated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(isDraft ? 'Delete' : 'Cancel Plan'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await ref
          .read(orchestratorDetailNotifierProvider.notifier)
          .cancel();
      if (!mounted) return;
      final planAfter = ref.read(orchestratorDetailNotifierProvider).valueOrNull;
      if (planAfter == null) {
        // Draft was deleted — plan no longer exists
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft deleted')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan cancelled')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(OrchestratorDetailNotifier.errorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orchestratorDetailNotifierProvider);
    final showInitialSkeleton = !_initialLoadCompleted &&
        !state.hasError &&
        (state.isLoading || state.valueOrNull == null);
    final renderState =
        showInitialSkeleton ? const AsyncLoading<OrchestratorPlanModel?>() : state;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: renderState.when(
        loading: () => const AppScreenSkeleton(showHeader: true, cardCount: 4),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 40),
              const SizedBox(height: AppSpacing.sm),
              Text(
                OrchestratorDetailNotifier.errorMessage(e),
                style: const TextStyle(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => ref
                    .read(orchestratorDetailNotifierProvider.notifier)
                    .load(widget.planId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (plan) {
          if (plan == null) {
            return const Center(
              child: Text(
                'Plan not found',
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            );
          }
          return _buildContent(context, plan);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, OrchestratorPlanModel plan) {
    final statusInfo = _planStatusInfo(plan.status);
    final progress = plan.percentComplete;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.onBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            plan.title,
            style: const TextStyle(
              color: AppColors.onBackground,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (_isOwnerOrManager && !plan.isCancelled)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.onBackground),
                color: AppColors.surfaceVariant,
                onSelected: (v) {
                  if (v == 'cancel') _cancel();
                  if (v == 'progress') {
                    context.push('/orchestrator/plans/${plan.id}/progress');
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'progress',
                    child: Row(
                      children: [
                        Icon(Icons.bar_chart_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Live Progress'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text(
                          'Cancel Plan',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + date row
                Row(
                  children: [
                    _StatusBadge(status: plan.status),
                    const SizedBox(width: AppSpacing.sm),
                    if (plan.targetDate != null) ...[
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(plan.targetDate),
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // AI summary
                if (plan.aiSummary.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border(
                        left: BorderSide(
                          color: AppColors.accent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      plan.aiSummary,
                      style: const TextStyle(
                        color: AppColors.onBackground,
                        fontSize: 14,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                // Overall progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'OVERALL PROGRESS',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: statusInfo.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor:
                        AppColors.onSurfaceVariant.withValues(alpha: 0.15),
                    color: statusInfo.color,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${plan.completedSteps} of ${plan.totalSteps} steps completed',
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Task groups header
                const Text(
                  'TASK GROUPS',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
        // Task group list
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final group = plan.taskGroups[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _TaskGroupCard(
                    group: group,
                    showAddItem: plan.isDraft && _isOwnerOrManager,
                    onTap: () => context.push(
                      '/orchestrator/plans/${plan.id}/groups/${group.groupId}',
                    ),
                    onAddItem: () => _showAddItemSheet(plan.id, group.groupId),
                    onAssign: _isOwnerOrManager && !plan.isCompleted && !plan.isCancelled
                        ? () => _showAssignSheet(plan.id, group)
                        : null,
                  ),
                );
              },
              childCount: plan.taskGroups.length,
            ),
          ),
        ),
        // Add Group button — only in draft
        if (plan.isDraft && _isOwnerOrManager)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: _AddGroupButton(
                onTap: () => _showAddGroupDialog(plan.id),
              ),
            ),
          ),
        // Publish button if draft
        if (plan.isDraft && _isOwnerOrManager)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _publishing ? null : _publish,
                  icon: _publishing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background,
                          ),
                        )
                      : const Icon(Icons.publish_rounded),
                  label: const Text('Publish Plan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (!plan.isDraft)
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      ],
    );
  }

  Future<void> _showAssignSheet(String planId, OrchestratorTaskGroupModel group) async {
    final user = await showOrchestratorAssignSheet(context);
    if (user == null || !mounted) return;
    await ref.read(orchestratorDetailNotifierProvider.notifier).updateAssignments([
      {
        'groupId': group.groupId,
        'assignedUserId': user.id,
        'assignedUserName': user.name,
      }
    ]);
  }

  void _showAddItemSheet(String planId, String groupId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemSheet(
        planId: planId,
        groupId: groupId,
        notifier: ref.read(orchestratorDetailNotifierProvider.notifier),
      ),
    );
  }

  Future<void> _showAddGroupDialog(String planId) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: const Text('Add Group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.onBackground),
          decoration: InputDecoration(
            hintText: 'Group title',
            hintStyle: TextStyle(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    final title = controller.text.trim();
    controller.dispose();
    if (confirmed != true || !mounted) return;
    if (title.isEmpty) return;
    try {
      await ref
          .read(orchestratorDetailNotifierProvider.notifier)
          .addGroup(title);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(OrchestratorDetailNotifier.errorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  static String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return DateFormat('MMM d, yyyy').format(dt);
  }
}

// ---------------------------------------------------------------------------
// Task group card
// ---------------------------------------------------------------------------

class _TaskGroupCard extends StatelessWidget {
  const _TaskGroupCard({
    required this.group,
    required this.onTap,
    this.showAddItem = false,
    this.onAddItem,
    this.onAssign,
  });

  final OrchestratorTaskGroupModel group;
  final VoidCallback onTap;
  final bool showAddItem;
  final VoidCallback? onAddItem;
  final VoidCallback? onAssign;

  String get _initials {
    final name = group.assignedUserName ?? '';
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final done = group.completedSteps;
    final total = group.totalSteps;
    final progress = total == 0 ? 0.0 : done / total;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: group.assignedUserName != null
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.1),
                child: Text(
                  _initials,
                  style: TextStyle(
                    color: group.assignedUserName != null
                        ? AppColors.accent
                        : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.title,
                            style: const TextStyle(
                              color: AppColors.onBackground,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _GroupStatusChip(status: group.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onAssign,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            group.assignedUserName ?? 'Unassigned',
                            style: TextStyle(
                              color: onAssign != null
                                  ? AppColors.accent
                                  : AppColors.onSurfaceVariant,
                              fontSize: 12,
                              decoration: onAssign != null
                                  ? TextDecoration.underline
                                  : null,
                            ),
                          ),
                          if (onAssign != null) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.edit, size: 11, color: AppColors.accent),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.onSurfaceVariant
                                  .withValues(alpha: 0.15),
                              color: AppColors.accent,
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '$done/$total',
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (showAddItem)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.accent, size: 20),
                  tooltip: 'Add item to group',
                  onPressed: onAddItem,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Group dashed button
// ---------------------------------------------------------------------------

class _AddGroupButton extends StatelessWidget {
  const _AddGroupButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.onSurfaceVariant, size: 18),
            SizedBox(width: 6),
            Text(
              'Add Group',
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Item bottom sheet
// ---------------------------------------------------------------------------

class _AddItemSheet extends ConsumerStatefulWidget {
  const _AddItemSheet({
    required this.planId,
    required this.groupId,
    required this.notifier,
  });

  final String planId;
  final String groupId;
  final OrchestratorDetailNotifier notifier;

  @override
  ConsumerState<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<_AddItemSheet> {
  final _searchController = TextEditingController();
  final _instructionController = TextEditingController();

  List<ItemModel> _results = [];
  ItemModel? _selected;
  bool _searching = false;
  bool _adding = false;
  String? _searchError;

  @override
  void dispose() {
    _searchController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _searchError = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final ds = ref.read(searchRemoteDataSourceProvider);
      final items = await ds.search(query: query);
      if (!mounted) return;
      setState(() => _results = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _searchError = 'Search failed. Please try again.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectItem(ItemModel item) {
    final roomPart = item.roomName != null ? ' from ${item.roomName}' : '';
    setState(() {
      _selected = item;
      _instructionController.text =
          'Retrieve the ${item.name}$roomPart';
    });
  }

  Future<void> _addToGroup() async {
    final item = _selected;
    if (item == null) return;
    final instruction = _instructionController.text.trim();
    if (instruction.isEmpty) return;
    setState(() => _adding = true);
    try {
      await widget.notifier.addManualStep(
        widget.groupId,
        item.id,
        instruction,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(OrchestratorDetailNotifier.errorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        bottomInset + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Add Item to Group',
            style: TextStyle(
              color: AppColors.onBackground,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_selected == null) ...[
            // Search field
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: AppColors.onBackground, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search items…',
                hintStyle: TextStyle(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: (v) {
                if (v.trim().length >= 2) _search(v.trim());
                if (v.trim().isEmpty) setState(() => _results = []);
              },
            ),
            if (_searchError != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                _searchError!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
            if (_results.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => Divider(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
                    height: 1,
                  ),
                  itemBuilder: (_, i) {
                    final item = _results[i];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(
                          color: AppColors.onBackground,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          item.category,
                          if (item.roomName != null) item.roomName!,
                        ].join(' · '),
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _selectItem(item),
                    );
                  },
                ),
              ),
            ],
          ] else ...[
            // Selected item + instruction editor
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.accent, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selected!.name,
                          style: const TextStyle(
                            color: AppColors.onBackground,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          [
                            _selected!.category,
                            if (_selected!.roomName != null)
                              _selected!.roomName!,
                          ].join(' · '),
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _selected = null;
                      _instructionController.clear();
                    }),
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Instruction',
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _instructionController,
              style: const TextStyle(color: AppColors.onBackground, fontSize: 14),
              maxLines: 2,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _adding ? null : _addToGroup,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _adding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.background,
                        ),
                      )
                    : const Text('Add to Plan'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reused status helpers
// ---------------------------------------------------------------------------

class _StatusInfo {
  const _StatusInfo(this.color, this.label);
  final Color color;
  final String label;
}

_StatusInfo _planStatusInfo(String status) {
  switch (status) {
    case 'published':
      return const _StatusInfo(Color(0xFF2196F3), 'Published');
    case 'in_progress':
      return const _StatusInfo(Color(0xFFE07B39), 'In Progress');
    case 'completed':
      return const _StatusInfo(Color(0xFF6DB86F), 'Completed');
    case 'cancelled':
      return const _StatusInfo(Color(0xFF9E9E9E), 'Cancelled');
    default:
      return const _StatusInfo(Color(0xFF8A8AA8), 'Draft');
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final info = _planStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          color: info.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GroupStatusChip extends StatelessWidget {
  const _GroupStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'in_progress':
        color = const Color(0xFFE07B39);
        label = 'In Progress';
        break;
      case 'completed':
        color = const Color(0xFF6DB86F);
        label = 'Done';
        break;
      default:
        color = const Color(0xFF8A8AA8);
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
