import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../media/data/media_repository_provider.dart';
import '../data/models/room_section_model.dart';
import '../domain/property_detail_notifier.dart';

class AiSectionScanScreen extends ConsumerStatefulWidget {
  const AiSectionScanScreen({
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
  ConsumerState<AiSectionScanScreen> createState() => _AiSectionScanScreenState();
}

class _AiSectionScanScreenState extends ConsumerState<AiSectionScanScreen> {
  final _picker = ImagePicker();

  _ScanStep _step = _ScanStep.capture;
  String? _imageUrl;
  List<_EditableSection> _detected = [];
  String _furnitureDescription = '';
  double _confidence = 0;
  bool _saving = false;

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null || !mounted) return;

    setState(() => _step = _ScanStep.uploading);
    try {
      final url = await ref.read(mediaRepositoryProvider).uploadPhoto(file);
      if (!mounted) return;
      setState(() {
        _imageUrl = url;
        _step = _ScanStep.analyzing;
      });
      await _analyze(url);
    } catch (e) {
      if (mounted) {
        setState(() => _step = _ScanStep.capture);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _analyze(String imageUrl) async {
    try {
      final result = await ref
          .read(propertyDetailNotifierProvider.notifier)
          .analyzeSections(imageUrl);

      final rawSections = (result['sections'] as List?) ?? [];
      final sections = rawSections.map((s) {
        final m = s as Map<String, dynamic>;
        return _EditableSection(
          code: m['code'] as String? ?? '',
          name: m['name'] as String? ?? '',
          type: m['type'] as String? ?? 'other',
          notes: m['notes'] as String?,
          selected: true,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _detected = sections;
          _furnitureDescription = result['furnitureDescription'] as String? ?? '';
          _confidence = (result['confidence'] as num?)?.toDouble() ?? 0;
          _step = _ScanStep.review;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _step = _ScanStep.capture);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI analysis failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    final toSave = _detected.where((s) => s.selected).toList();
    if (toSave.isEmpty || _saving) return;
    setState(() => _saving = true);

    try {
      final sections = toSave
          .map((s) => {
                'code': s.code,
                'name': s.name,
                'type': s.type,
                if (s.notes != null && s.notes!.isNotEmpty) 'notes': s.notes,
              })
          .toList();

      await ref
          .read(propertyDetailNotifierProvider.notifier)
          .addSectionsBulk(widget.floorId, widget.roomId, sections);

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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'AI Section Scan',
          style: const TextStyle(color: AppColors.onBackground),
        ),
        iconTheme: const IconThemeData(color: AppColors.onBackground),
      ),
      body: switch (_step) {
        _ScanStep.capture => _CaptureView(onPick: _pickImage),
        _ScanStep.uploading => const _ProgressView(message: 'Uploading photo…'),
        _ScanStep.analyzing => const _ProgressView(message: 'AI is mapping sections…'),
        _ScanStep.review => _ReviewView(
            roomName: widget.roomName,
            furnitureDescription: _furnitureDescription,
            confidence: _confidence,
            sections: _detected,
            saving: _saving,
            onToggle: (i, v) => setState(() => _detected[i] = _detected[i].copyWith(selected: v)),
            onEdit: (i) => _showEditSheet(i),
            onRescan: () => setState(() => _step = _ScanStep.capture),
            onSave: _save,
          ),
      },
    );
  }

  Future<void> _showEditSheet(int index) async {
    final s = _detected[index];
    final result = await showModalBottomSheet<_EditableSection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSectionSheet(section: s),
    );
    if (result != null && mounted) {
      setState(() => _detected[index] = result);
    }
  }
}

// ── Step enum ────────────────────────────────────────────────────────────────

enum _ScanStep { capture, uploading, analyzing, review }

// ── Editable section model ───────────────────────────────────────────────────

class _EditableSection {
  _EditableSection({
    required this.code,
    required this.name,
    required this.type,
    this.notes,
    this.selected = true,
  });

  final String code;
  final String name;
  final String type;
  final String? notes;
  final bool selected;

  _EditableSection copyWith({
    String? code,
    String? name,
    String? type,
    String? notes,
    bool? selected,
  }) => _EditableSection(
    code: code ?? this.code,
    name: name ?? this.name,
    type: type ?? this.type,
    notes: notes ?? this.notes,
    selected: selected ?? this.selected,
  );
}

// ── Capture view ─────────────────────────────────────────────────────────────

class _CaptureView extends StatelessWidget {
  const _CaptureView({required this.onPick});

  final Future<void> Function(ImageSource) onPick;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(25),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.auto_awesome, size: 48, color: AppColors.accent),
            ),
            const SizedBox(height: 24),
            const Text(
              'Take a photo of the storage furniture',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI will automatically detect every drawer, cabinet, and shelf — then generate section codes for you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => onPick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take photo'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => onPick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose from gallery'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Progress view ────────────────────────────────────────────────────────────

class _ProgressView extends StatelessWidget {
  const _ProgressView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.accent),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Review view ───────────────────────────────────────────────────────────────

class _ReviewView extends StatelessWidget {
  const _ReviewView({
    required this.roomName,
    required this.furnitureDescription,
    required this.confidence,
    required this.sections,
    required this.saving,
    required this.onToggle,
    required this.onEdit,
    required this.onRescan,
    required this.onSave,
  });

  final String roomName;
  final String furnitureDescription;
  final double confidence;
  final List<_EditableSection> sections;
  final bool saving;
  final void Function(int, bool) onToggle;
  final void Function(int) onEdit;
  final VoidCallback onRescan;
  final VoidCallback onSave;

  int get _selectedCount => sections.where((s) => s.selected).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.accent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${sections.length} sections detected',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _confidenceColor(confidence).withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(_confidence * 100).round()}% confidence',
                      style: TextStyle(
                        fontSize: 11,
                        color: _confidenceColor(confidence),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (furnitureDescription.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  furnitureDescription,
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Review and deselect any sections you don\'t want to add.',
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Section list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final s = sections[i];
              return Container(
                decoration: BoxDecoration(
                  color: s.selected
                      ? AppColors.surfaceVariant
                      : AppColors.surfaceVariant.withAlpha(100),
                  borderRadius: BorderRadius.circular(14),
                  border: s.selected
                      ? Border.all(color: AppColors.accent.withAlpha(80), width: 1)
                      : null,
                ),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: s.selected
                          ? AppColors.accent.withAlpha(25)
                          : AppColors.onSurfaceVariant.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        s.code,
                        style: TextStyle(
                          color: s.selected ? AppColors.accent : AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    s.name,
                    style: TextStyle(
                      color: s.selected ? AppColors.onBackground : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    s.notes != null && s.notes!.isNotEmpty
                        ? '${s.type} · ${s.notes}'
                        : s.type,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: AppColors.onSurfaceVariant,
                        onPressed: () => onEdit(i),
                      ),
                      Checkbox(
                        value: s.selected,
                        onChanged: (v) => onToggle(i, v ?? false),
                        activeColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom actions
        Container(
          padding: EdgeInsets.fromLTRB(
            16, 12, 16,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(color: AppColors.surfaceVariant),
            ),
          ),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: onRescan,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurfaceVariant,
                  side: BorderSide(color: AppColors.onSurfaceVariant.withAlpha(100)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Rescan'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: (saving || _selectedCount == 0) ? null : onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Save $_selectedCount section${_selectedCount == 1 ? '' : 's'}'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double get _confidence => confidence;

  Color _confidenceColor(double c) {
    if (c >= 0.8) return const Color(0xFF4CAF50);
    if (c >= 0.6) return const Color(0xFFFFA726);
    return AppColors.error;
  }
}

// ── Edit section inline sheet ────────────────────────────────────────────────

class _EditSectionSheet extends StatefulWidget {
  const _EditSectionSheet({required this.section});

  final _EditableSection section;

  @override
  State<_EditSectionSheet> createState() => _EditSectionSheetState();
}

class _EditSectionSheetState extends State<_EditSectionSheet> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;
  late String _type;

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
    _codeCtrl = TextEditingController(text: widget.section.code);
    _nameCtrl = TextEditingController(text: widget.section.name);
    _notesCtrl = TextEditingController(text: widget.section.notes ?? '');
    _type = widget.section.type;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
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
            const Text(
              'Edit section',
              style: TextStyle(
                fontSize: 18,
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
                    decoration: const InputDecoration(labelText: 'Code', hintText: '1A'),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 10,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
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
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  widget.section.copyWith(
                    code: _codeCtrl.text.trim(),
                    name: _nameCtrl.text.trim(),
                    type: _type,
                    notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
