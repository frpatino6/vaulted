import 'dart:math';

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
        final rawBbox = m['boundingBox'] as Map<String, dynamic>?;
        return _EditableSection(
          code: m['code'] as String? ?? '',
          name: m['name'] as String? ?? '',
          type: m['type'] as String? ?? 'other',
          notes: m['notes'] as String?,
          selected: true,
          boundingBox: rawBbox != null
              ? _BoundingBox(
                  x: (rawBbox['x'] as num).toDouble(),
                  y: (rawBbox['y'] as num).toDouble(),
                  width: (rawBbox['width'] as num).toDouble(),
                  height: (rawBbox['height'] as num).toDouble(),
                )
              : null,
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
        title: const Text(
          'AI Section Scan',
          style: TextStyle(color: AppColors.onBackground),
        ),
        iconTheme: const IconThemeData(color: AppColors.onBackground),
      ),
      body: switch (_step) {
        _ScanStep.capture => _CaptureView(onPick: _pickImage),
        _ScanStep.uploading => const _ProgressView(message: 'Uploading photo…'),
        _ScanStep.analyzing => const _ProgressView(message: 'AI is mapping sections…'),
        _ScanStep.review => _AnnotatedReviewView(
            imageUrl: _imageUrl!,
            roomName: widget.roomName,
            furnitureDescription: _furnitureDescription,
            confidence: _confidence,
            sections: _detected,
            saving: _saving,
            onToggle: (i) => setState(() =>
                _detected[i] = _detected[i].copyWith(selected: !_detected[i].selected)),
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

// ── Bounding box ─────────────────────────────────────────────────────────────

class _BoundingBox {
  const _BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;
}

// ── Editable section model ───────────────────────────────────────────────────

class _EditableSection {
  _EditableSection({
    required this.code,
    required this.name,
    required this.type,
    this.notes,
    this.selected = true,
    this.boundingBox,
  });

  final String code;
  final String name;
  final String type;
  final String? notes;
  final bool selected;
  final _BoundingBox? boundingBox;

  _EditableSection copyWith({
    String? code,
    String? name,
    String? type,
    String? notes,
    bool? selected,
    _BoundingBox? boundingBox,
  }) =>
      _EditableSection(
        code: code ?? this.code,
        name: name ?? this.name,
        type: type ?? this.type,
        notes: notes ?? this.notes,
        selected: selected ?? this.selected,
        boundingBox: boundingBox ?? this.boundingBox,
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
              'AI will automatically detect every drawer, cabinet, and shelf — then pin the section codes directly on the photo.',
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

// ── Annotated review view ─────────────────────────────────────────────────────

class _AnnotatedReviewView extends StatefulWidget {
  const _AnnotatedReviewView({
    required this.imageUrl,
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

  final String imageUrl;
  final String roomName;
  final String furnitureDescription;
  final double confidence;
  final List<_EditableSection> sections;
  final bool saving;
  final void Function(int) onToggle;
  final void Function(int) onEdit;
  final VoidCallback onRescan;
  final VoidCallback onSave;

  @override
  State<_AnnotatedReviewView> createState() => _AnnotatedReviewViewState();
}

class _AnnotatedReviewViewState extends State<_AnnotatedReviewView> {
  Size? _naturalImageSize;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  @override
  void didUpdateWidget(_AnnotatedReviewView old) {
    super.didUpdateWidget(old);
    if (old.imageUrl != widget.imageUrl) _loadImageSize();
  }

  void _loadImageSize() {
    final stream = NetworkImage(widget.imageUrl).resolve(const ImageConfiguration());
    stream.addListener(ImageStreamListener((info, _) {
      if (mounted) {
        setState(() => _naturalImageSize = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            ));
      }
    }));
  }

  int get _selectedCount => widget.sections.where((s) => s.selected).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Info bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.furnitureDescription.isNotEmpty
                      ? widget.furnitureDescription
                      : '${widget.sections.length} sections detected',
                  style: const TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _ConfidenceBadge(confidence: widget.confidence),
            ],
          ),
        ),

        // Annotated image
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.imageUrl,
                        fit: BoxFit.contain,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                      ),
                      if (_naturalImageSize != null)
                        ..._buildOverlays(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),

        // Bottom actions
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.surfaceVariant)),
          ),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: widget.onRescan,
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
                  onPressed: (widget.saving || _selectedCount == 0) ? null : widget.onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: widget.saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Save $_selectedCount section${_selectedCount == 1 ? '' : 's'}',
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOverlays(double containerW, double containerH) {
    final imgW = _naturalImageSize!.width;
    final imgH = _naturalImageSize!.height;

    // Compute rendered image rect within the container (BoxFit.contain logic)
    final scale = min(containerW / imgW, containerH / imgH);
    final renderedW = imgW * scale;
    final renderedH = imgH * scale;
    final offsetX = (containerW - renderedW) / 2;
    final offsetY = (containerH - renderedH) / 2;

    return widget.sections.asMap().entries.map((entry) {
      final i = entry.key;
      final s = entry.value;
      final bbox = s.boundingBox;
      if (bbox == null) return const SizedBox.shrink();

      final centerX = offsetX + (bbox.x + bbox.width / 2) * renderedW;
      final centerY = offsetY + (bbox.y + bbox.height / 2) * renderedH;

      // Draw a subtle rectangle outline for the detected section
      final rectLeft = offsetX + bbox.x * renderedW;
      final rectTop = offsetY + bbox.y * renderedH;
      final rectW = bbox.width * renderedW;
      final rectH = bbox.height * renderedH;

      return Stack(
        children: [
          // Section outline
          Positioned(
            left: rectLeft,
            top: rectTop,
            child: Container(
              width: rectW,
              height: rectH,
              decoration: BoxDecoration(
                border: Border.all(
                  color: s.selected
                      ? AppColors.accent.withAlpha(180)
                      : AppColors.onSurfaceVariant.withAlpha(100),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
                color: s.selected
                    ? AppColors.accent.withAlpha(20)
                    : Colors.black.withAlpha(20),
              ),
            ),
          ),
          // Code chip at center
          Positioned(
            left: centerX - 32,
            top: centerY - 16,
            child: _SectionChip(
              section: s,
              onTap: () => widget.onToggle(i),
              onEdit: () => widget.onEdit(i),
            ),
          ),
        ],
      );
    }).toList();
  }
}

// ── Section chip (overlay on image) ──────────────────────────────────────────

class _SectionChip extends StatelessWidget {
  const _SectionChip({
    required this.section,
    required this.onTap,
    required this.onEdit,
  });

  final _EditableSection section;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isSelected = section.selected;
    final bg = isSelected ? AppColors.accent : Colors.black54;
    final fg = isSelected ? AppColors.background : Colors.white70;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 8, right: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              section.code,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 2),
            GestureDetector(
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: fg.withAlpha(200),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Confidence badge ──────────────────────────────────────────────────────────

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});

  final double confidence;

  Color get _color {
    if (confidence >= 0.8) return const Color(0xFF4CAF50);
    if (confidence >= 0.6) return const Color(0xFFFFA726);
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${(confidence * 100).round()}%',
        style: TextStyle(
          fontSize: 11,
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
                width: 40,
                height: 4,
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
                    notes:
                        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
