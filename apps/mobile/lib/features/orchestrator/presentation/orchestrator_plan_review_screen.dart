import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../inventory/data/models/item_model.dart';
import '../../inventory/data/search_remote_data_source_provider.dart';
import '../../users/data/models/user_model.dart';
import '../data/models/orchestrator_plan_model.dart';
import '../data/orchestrator_repository_provider.dart';
import 'orchestrator_assign_sheet.dart';

class OrchestratorPlanReviewScreen extends ConsumerStatefulWidget {
  const OrchestratorPlanReviewScreen({super.key, required this.parsed});

  final ParsedPlanModel parsed;

  @override
  ConsumerState<OrchestratorPlanReviewScreen> createState() =>
      _OrchestratorPlanReviewScreenState();
}

class _OrchestratorPlanReviewScreenState
    extends ConsumerState<OrchestratorPlanReviewScreen> {
  late final TextEditingController _titleController;

  // Mutable list of task groups for editing
  late List<_ReviewGroup> _groups;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.parsed.title);
    _groups = widget.parsed.taskGroups.map((g) {
      return _ReviewGroup(
        groupId: g.groupId,
        title: g.title,
        steps: g.steps,
        assignedUserId: g.assignedUserId,
        assignedUserName: g.assignedUserName,
      );
    }).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _assignGroup(int index) async {
    final user = await showOrchestratorAssignSheet(context);
    if (user == null || !mounted) return;
    setState(() {
      _groups[index] = _ReviewGroup(
        groupId: _groups[index].groupId,
        title: _groups[index].title,
        steps: _groups[index].steps,
        assignedUserId: user.id,
        assignedUserName: _displayName(user),
      );
    });
  }

  String _displayName(UserModel user) {
    final part = user.email.split('@').first;
    if (part.isEmpty) return user.email;
    return part[0].toUpperCase() + part.substring(1).toLowerCase();
  }

  Map<String, dynamic> _buildCreateBody({bool publish = false}) {
    final parsed = widget.parsed;
    return {
      'title': _titleController.text.trim().isEmpty
          ? parsed.title
          : _titleController.text.trim(),
      'originalCommand': parsed.title,
      'commandType': parsed.commandType,
      'aiSummary': parsed.aiSummary,
      if (parsed.targetDate != null) 'targetDate': parsed.targetDate,
      if (parsed.targetPropertyId != null)
        'targetPropertyId': parsed.targetPropertyId,
      if (parsed.destinationPropertyId != null)
        'destinationPropertyId': parsed.destinationPropertyId,
      'taskGroups': _groups.map((g) {
        return {
          'groupId': g.groupId,
          'title': g.title,
          if (g.assignedUserId != null) 'assignedUserId': g.assignedUserId,
          if (g.assignedUserName != null)
            'assignedUserName': g.assignedUserName,
          'steps': g.steps.map((s) {
            return {
              'stepId': s.stepId,
              'itemId': s.itemId,
              'itemName': s.itemName,
              'itemCategory': s.itemCategory,
              if (s.itemPhoto != null) 'itemPhoto': s.itemPhoto,
              if (s.roomId != null) 'roomId': s.roomId,
              if (s.roomName != null) 'roomName': s.roomName,
              if (s.roomPhoto != null) 'roomPhoto': s.roomPhoto,
              if (s.sectionId != null) 'sectionId': s.sectionId,
              if (s.sectionPhoto != null) 'sectionPhoto': s.sectionPhoto,
              if (s.sectionCode != null) 'sectionCode': s.sectionCode,
              if (s.sectionFurnitureName != null)
                'sectionFurnitureName': s.sectionFurnitureName,
              if (s.boundingBox != null)
                'boundingBox': s.boundingBox!.toJson(),
              'instruction': s.instruction,
            };
          }).toList(),
        };
      }).toList(),
    };
  }

  Future<void> _save({bool andPublish = false}) async {
    if (_saving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan title is required.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(orchestratorRepositoryProvider);
      final plan = await repo.createPlan(_buildCreateBody());
      if (andPublish) {
        await repo.publishPlan(plan.id);
      }
      if (!mounted) return;
      // Navigate to detail screen, replacing review screen
      context.pushReplacement('/orchestrator/plans/${plan.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _deleteGroup(int index) {
    setState(() => _groups.removeAt(index));
  }

  void _addManualStepToGroup(int groupIndex, ItemModel item, String instruction) {
    const uuid = Uuid();
    final step = OrchestratorStepModel(
      stepId: uuid.v4(),
      itemId: item.id,
      itemName: item.name,
      itemCategory: item.category,
      roomId: item.roomId,
      roomName: item.roomName,
      instruction: instruction,
    );
    setState(() {
      _groups[groupIndex].steps.add(step);
    });
  }

  void _showAddItemSheet(int groupIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewAddItemSheet(
        onItemSelected: (item, instruction) {
          _addManualStepToGroup(groupIndex, item, instruction);
        },
      ),
    );
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _groups.removeAt(oldIndex);
      _groups.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        elevation: 0,
        title: const Text(
          'Review Plan',
          style: TextStyle(
            color: AppColors.onBackground,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Editable title
                  const Text(
                    'PLAN TITLE',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      color: AppColors.onBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // AI summary
                  if (widget.parsed.aiSummary.isNotEmpty) ...[
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.auto_awesome_outlined,
                                size: 14,
                                color: AppColors.accent,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'AI Summary',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            widget.parsed.aiSummary,
                            style: const TextStyle(
                              color: AppColors.onBackground,
                              fontSize: 14,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  // Task groups header
                  Row(
                    children: [
                      const Text(
                        'TASK GROUPS',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_groups.length} groups · drag to reorder',
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_groups.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'All groups removed',
                          style: TextStyle(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: _reorder,
                      itemCount: _groups.length,
                      itemBuilder: (context, i) {
                        final group = _groups[i];
                        return _ReviewGroupCard(
                          key: ValueKey(group.groupId),
                          group: group,
                          index: i,
                          onAssign: () => _assignGroup(i),
                          onDelete: () => _deleteGroup(i),
                          onAddItem: () => _showAddItemSheet(i),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          // Bottom action buttons
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.sm,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _saving ? null : () => _save(andPublish: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.background,
                            ),
                          )
                        : const Text('Save & Publish'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => _save(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Save as Draft'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mutable group model for review screen
// ---------------------------------------------------------------------------

class _ReviewGroup {
  _ReviewGroup({
    required this.groupId,
    required this.title,
    required List<OrchestratorStepModel> steps,
    this.assignedUserId,
    this.assignedUserName,
  }) : steps = List<OrchestratorStepModel>.from(steps);

  final String groupId;
  final String title;
  final List<OrchestratorStepModel> steps;
  String? assignedUserId;
  String? assignedUserName;
}

// ---------------------------------------------------------------------------
// Review group card
// ---------------------------------------------------------------------------

class _ReviewGroupCard extends StatelessWidget {
  const _ReviewGroupCard({
    super.key,
    required this.group,
    required this.index,
    required this.onAssign,
    required this.onDelete,
    required this.onAddItem,
  });

  final _ReviewGroup group;
  final int index;
  final VoidCallback onAssign;
  final VoidCallback onDelete;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm + 4,
                AppSpacing.xs,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.drag_indicator,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.title,
                          style: const TextStyle(
                            color: AppColors.onBackground,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${group.steps.length} step${group.steps.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: AppColors.error,
                    tooltip: 'Remove group',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm + 4,
              ),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  GestureDetector(
                    onTap: onAssign,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: group.assignedUserName != null
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : AppColors.onSurfaceVariant.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: group.assignedUserName != null
                              ? AppColors.accent.withValues(alpha: 0.4)
                              : AppColors.onSurfaceVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            group.assignedUserName != null
                                ? Icons.person_rounded
                                : Icons.person_add_outlined,
                            size: 14,
                            color: group.assignedUserName != null
                                ? AppColors.accent
                                : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            group.assignedUserName ?? 'Assign to…',
                            style: TextStyle(
                              color: group.assignedUserName != null
                                  ? AppColors.accent
                                  : AppColors.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onAddItem,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Add Item',
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Item picker sheet for the review screen (ephemeral — no planId yet)
// ---------------------------------------------------------------------------

class _ReviewAddItemSheet extends ConsumerStatefulWidget {
  const _ReviewAddItemSheet({required this.onItemSelected});

  final void Function(ItemModel item, String instruction) onItemSelected;

  @override
  ConsumerState<_ReviewAddItemSheet> createState() =>
      _ReviewAddItemSheetState();
}

class _ReviewAddItemSheetState extends ConsumerState<_ReviewAddItemSheet> {
  final _searchController = TextEditingController();
  final _instructionController = TextEditingController();

  List<ItemModel> _results = [];
  ItemModel? _selected;
  bool _searching = false;
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
    } catch (_) {
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
      _instructionController.text = 'Retrieve the ${item.name}$roomPart';
    });
  }

  void _confirm() {
    final item = _selected;
    if (item == null) return;
    final instruction = _instructionController.text.trim();
    if (instruction.isEmpty) return;
    widget.onItemSelected(item, instruction);
    Navigator.of(context).pop();
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
                onPressed: _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add to Plan'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
