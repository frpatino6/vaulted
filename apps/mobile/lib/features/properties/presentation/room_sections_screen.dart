import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/models/room_section_model.dart';
import '../domain/property_detail_notifier.dart';
import 'ai_section_scan_screen.dart';

class RoomSectionsScreen extends ConsumerStatefulWidget {
  const RoomSectionsScreen({
    super.key,
    required this.propertyId,
    required this.floorId,
    required this.roomId,
    required this.roomName,
  });

  final String propertyId;
  final String floorId;
  final String roomId;
  final String roomName;

  @override
  ConsumerState<RoomSectionsScreen> createState() => _RoomSectionsScreenState();
}

class _RoomSectionsScreenState extends ConsumerState<RoomSectionsScreen> {
  List<RoomSectionModel> _sections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sections = await ref
          .read(propertyDetailNotifierProvider.notifier)
          .getSections(widget.floorId, widget.roomId);
      if (mounted) setState(() => _sections = sections);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddSheet({RoomSectionModel? editing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SectionFormSheet(
        floorId: widget.floorId,
        roomId: widget.roomId,
        editing: editing,
      ),
    );
    if (result == true) _load();
  }

  Future<void> _delete(RoomSectionModel section) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: const Text('Delete section'),
        content: Text('Delete "${section.code} – ${section.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ref.read(propertyDetailNotifierProvider.notifier).deleteSection(
        widget.floorId, widget.roomId, section.sectionId,
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(PropertyDetailNotifier.message(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openAiScan() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AiSectionScanScreen(
          propertyId: widget.propertyId,
          floorId: widget.floorId,
          roomId: widget.roomId,
          roomName: widget.roomName,
        ),
      ),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          '${widget.roomName} – Sections',
          style: const TextStyle(color: AppColors.onBackground),
        ),
        iconTheme: const IconThemeData(color: AppColors.onBackground),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppColors.accent),
            tooltip: 'AI Section Scan',
            onPressed: _openAiScan,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            tooltip: 'Add section',
            onPressed: () => _showAddSheet(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sections.isEmpty
              ? _EmptyState(onAiScan: _openAiScan, onAdd: () => _showAddSheet())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Text(
                            '${_sections.length} section${_sections.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sections.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _SectionTile(
                          section: _sections[i],
                          onEdit: () => _showAddSheet(editing: _sections[i]),
                          onDelete: () => _delete(_sections[i]),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ── Section tile ────────────────────────────────────────────────────────────

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.section,
    required this.onEdit,
    required this.onDelete,
  });

  final RoomSectionModel section;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  IconData get _icon {
    switch (section.type) {
      case 'drawer':
        return Icons.table_rows_outlined;
      case 'cabinet':
        return Icons.door_sliding_outlined;
      case 'shelf':
        return Icons.shelves;
      case 'rack':
        return Icons.view_week_outlined;
      case 'safe':
        return Icons.lock_outline;
      case 'compartment':
        return Icons.grid_view_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.accent.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              section.code,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        title: Text(
          section.name,
          style: const TextStyle(
            color: AppColors.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(_icon, size: 13, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              section.type,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            if (section.notes != null && section.notes!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.notes!,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppColors.onSurfaceVariant,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: AppColors.error,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAiScan, required this.onAdd});

  final VoidCallback onAiScan;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.grid_view_outlined, size: 64, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text(
              'No sections yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Define the storage sections of this room\nbefore adding inventory items.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAiScan,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Scan with AI'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add manually'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section form sheet ───────────────────────────────────────────────────────

class _SectionFormSheet extends ConsumerStatefulWidget {
  const _SectionFormSheet({
    required this.floorId,
    required this.roomId,
    this.editing,
  });

  final String floorId;
  final String roomId;
  final RoomSectionModel? editing;

  @override
  ConsumerState<_SectionFormSheet> createState() => _SectionFormSheetState();
}

class _SectionFormSheetState extends ConsumerState<_SectionFormSheet> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;
  String _type = 'other';
  bool _submitting = false;

  static const _types = [
    ('drawer', 'Drawer'),
    ('cabinet', 'Cabinet'),
    ('shelf', 'Shelf'),
    ('rack', 'Rack'),
    ('safe', 'Safe'),
    ('compartment', 'Compartment'),
    ('other', 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.editing?.code ?? '');
    _nameCtrl = TextEditingController(text: widget.editing?.name ?? '');
    _notesCtrl = TextEditingController(text: widget.editing?.notes ?? '');
    _type = widget.editing?.type ?? 'other';
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (code.isEmpty || name.isEmpty || _submitting) return;
    setState(() => _submitting = true);

    try {
      final notifier = ref.read(propertyDetailNotifierProvider.notifier);
      if (widget.editing != null) {
        await notifier.updateSection(
          widget.floorId, widget.roomId, widget.editing!.sectionId,
          code: code, name: name, type: _type,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
      } else {
        await notifier.addSection(
          widget.floorId, widget.roomId,
          code: code, name: name, type: _type,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(PropertyDetailNotifier.message(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editing != null;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEditing ? 'Edit section' : 'Add section',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Code',
                      hintText: '1A',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 10,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Top Left Drawer',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              dropdownColor: AppColors.surfaceVariant,
              items: _types
                  .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? 'other'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. has glass door',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Save changes' : 'Add section'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
