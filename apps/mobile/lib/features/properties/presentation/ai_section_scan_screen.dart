import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_compress_utils.dart';
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
    this.existingSectionCodes = const [],
  });

  final String propertyId;
  final String floorId;
  final String roomId;
  final String roomName;
  final List<String> existingSectionCodes;

  @override
  ConsumerState<AiSectionScanScreen> createState() => _AiSectionScanScreenState();
}

class _AiSectionScanScreenState extends ConsumerState<AiSectionScanScreen> {
  final _picker = ImagePicker();

  _ScanStep _step = _ScanStep.capture;
  final List<_ScanGroup> _groups = [];
  int _currentGroupIndex = 0;
  bool _saving = false;
  final _annotatedKey = GlobalKey();

  _ScanGroup? get _currentGroup =>
      _groups.isNotEmpty ? _groups[_currentGroupIndex] : null;

  int get _totalSelectedCount =>
      _groups.fold(0, (sum, g) => sum + g.sections.where((s) => s.selected).length);

  // ── Image pick ────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (file == null || !mounted) return;

    setState(() => _step = _ScanStep.analyzing);
    try {
      final bytes = await file.readAsBytes();
      final mime = file.mimeType ?? 'image/jpeg';
      await _analyze(bytes, mime);
    } catch (e) {
      if (mounted) {
        setState(() => _step = _ScanStep.capture);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read image: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ── AI analysis ───────────────────────────────────────────────────────────

  Future<void> _analyze(Uint8List bytes, String mimeType) async {
    try {
      final result = await ref
          .read(propertyDetailNotifierProvider.notifier)
          .analyzeSectionsFromBytes(bytes, mimeType);

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
          row: m['row'] as int? ?? 1,
          column: m['column'] as String? ?? 'A',
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

      final furnitureDescription = result['furnitureDescription'] as String? ?? '';
      final confidence = (result['confidence'] as num?)?.toDouble() ?? 0;

      final newGroup = _ScanGroup(
        imageBytes: bytes,
        mimeType: mimeType,
        sections: sections,
        furnitureName: furnitureDescription,
        confidence: confidence,
      );

      if (mounted) {
        setState(() {
          if (_currentGroup == null) {
            _groups.add(newGroup);
            _currentGroupIndex = 0;
          } else {
            _groups.add(newGroup);
            _currentGroupIndex = _groups.length - 1;
          }
          _step = _ScanStep.review;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _step = _ScanStep.capture);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI analysis failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ── Next available code within current group ──────────────────────────────

  String _nextAvailableCode() {
    final group = _currentGroup;
    final usedCodes = <String>{
      ...group?.sections.map((s) => s.code) ?? [],
    };
    final sections = group?.sections ?? [];
    final maxRow = sections.isEmpty ? 0 : sections.map((s) => s.row).reduce(max);
    var row = maxRow + 1;
    var col = 'A';
    while (usedCodes.contains('$row$col')) {
      final nextCharCode = col.codeUnitAt(0) + 1;
      if (nextCharCode > 'Z'.codeUnitAt(0)) {
        row++;
        col = 'A';
      } else {
        col = String.fromCharCode(nextCharCode);
      }
    }
    return '$row$col';
  }

  // ── Section management ────────────────────────────────────────────────────

  void _removeSection(int i) {
    final group = _currentGroup;
    if (group == null) return;
    final removed = group.sections[i];
    final idx = i;
    setState(() => group.sections.removeAt(i));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Section ${removed.code} removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            if (mounted) setState(() => group.sections.insert(idx.clamp(0, group.sections.length), removed));
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _updateSection(int index, _EditableSection updated) {
    final group = _currentGroup;
    if (group == null) return;
    setState(() => group.sections[index] = updated);
  }

  Future<void> _addAtPosition(double fracX, double fracY) async {
    final nextCode = _nextAvailableCode();
    const bw = 0.15, bh = 0.12;
    final placeholder = _EditableSection(
      code: nextCode,
      name: '',
      type: 'other',
      selected: true,
      row: int.tryParse(nextCode.replaceAll(RegExp(r'[A-Z]'), '')) ?? 1,
      column: nextCode.replaceAll(RegExp(r'[0-9]'), ''),
      boundingBox: _BoundingBox(
        x: (fracX - bw / 2).clamp(0.0, 1.0 - bw),
        y: (fracY - bh / 2).clamp(0.0, 1.0 - bh),
        width: bw,
        height: bh,
      ),
    );
    final result = await showModalBottomSheet<_EditableSection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSectionSheet(section: placeholder),
    );
    if (result != null && mounted) {
      setState(() => _currentGroup?.sections.add(result));
    }
  }

  // ── Capture annotated screenshot ──────────────────────────────────────────

  Future<Uint8List?> _captureAnnotated() async {
    try {
      final boundary = _annotatedKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  // ── Scan another piece ────────────────────────────────────────────────────

  Future<void> _onAddMore() async {
    // Capture annotated screenshot for current group before switching
    final annotated = await _captureAnnotated();
    if (annotated != null) {
      _currentGroup?.annotatedBytes = annotated;
    }
    if (mounted) setState(() => _step = _ScanStep.capture);
  }

  // ── Rescan current cabinet ────────────────────────────────────────────────

  void _onRescan() {
    setState(() {
      if (_groups.isNotEmpty) _groups.removeLast();
      _currentGroupIndex = _groups.isEmpty ? 0 : _groups.length - 1;
      _step = _ScanStep.capture;
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _requestSave() async {
    final allSelected = _groups
        .expand((g) => g.sections.where((s) => s.selected).map((s) => (group: g, section: s)))
        .toList();
    if (allSelected.isEmpty) return;

    final furnitureNames = {
      for (final g in _groups.where((g) => g.sections.any((s) => s.selected)))
        g: '',
    };

    final confirmed = await showModalBottomSheet<Map<_ScanGroup, String>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SaveSummarySheet(
        groups: _groups.where((g) => g.sections.any((s) => s.selected)).toList(),
        roomName: widget.roomName,
        initialFurnitureNames: furnitureNames,
      ),
    );
    if (confirmed != null) {
      for (final entry in confirmed.entries) {
        entry.key.furnitureName = entry.value;
      }
      await _save();
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      // Capture annotated screenshot for last group if not done yet
      final lastGroup = _currentGroup;
      if (lastGroup != null && lastGroup.annotatedBytes == null) {
        lastGroup.annotatedBytes = await _captureAnnotated();
      }

      final allSections = <Map<String, dynamic>>[];

      for (final group in _groups) {
        final selected = group.sections.where((s) => s.selected).toList();
        if (selected.isEmpty) continue;

        // Upload annotated photo for this group
        String? annotatedPhotoUrl;
        final annotated = group.annotatedBytes;
        if (annotated != null) {
          try {
            final compressed = await compressImageBytes(annotated);
            annotatedPhotoUrl = await ref
                .read(mediaRepositoryProvider)
                .uploadPhotoBytes(compressed, 'section_map.jpg');
          } catch (_) {
            // Proceed without photo if upload fails
          }
        }

        for (final s in selected) {
          allSections.add({
            'code': s.code,
            'name': s.name,
            'type': s.type,
            if (s.notes != null && s.notes!.isNotEmpty) 'notes': s.notes,
            if (annotatedPhotoUrl != null) 'photo': annotatedPhotoUrl,
            if (group.furnitureName.isNotEmpty) 'furnitureName': group.furnitureName,
            if (s.boundingBox != null) 'boundingBox': {
              'x': s.boundingBox!.x,
              'y': s.boundingBox!.y,
              'width': s.boundingBox!.width,
              'height': s.boundingBox!.height,
            },
          });
        }
      }

      if (allSections.isEmpty) return;

      await ref
          .read(propertyDetailNotifierProvider.notifier)
          .addSectionsBulk(widget.floorId, widget.roomId, allSections);
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final previousGroupCount = _currentGroupIndex;
    final previousSectionCount = _groups
        .take(_currentGroupIndex)
        .fold(0, (sum, g) => sum + g.sections.where((s) => s.selected).length);

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
        _ScanStep.capture => _CaptureView(
            onPick: _pickImage,
            previousGroupCount: previousGroupCount,
            previousSectionCount: previousSectionCount,
          ),
        _ScanStep.uploading => const _ProgressView(message: 'Uploading photo…'),
        _ScanStep.analyzing => const _ProgressView(message: 'AI is mapping sections…'),
        _ScanStep.review => _AnnotatedReviewView(
            imageBytes: _currentGroup!.imageBytes,
            roomName: widget.roomName,
            furnitureDescription: _currentGroup!.furnitureName,
            confidence: _currentGroup!.confidence,
            sections: _currentGroup!.sections,
            saving: _saving,
            annotatedKey: _annotatedKey,
            previousGroupCount: previousGroupCount,
            previousSectionCount: previousSectionCount,
            totalSelectedCount: _totalSelectedCount,
            onToggle: (i) => setState(() {
              final s = _currentGroup!.sections[i];
              _currentGroup!.sections[i] = s.copyWith(selected: !s.selected);
            }),
            onEdit: (i) => _showEditSheet(i),
            onRemove: _removeSection,
            onUpdateSection: _updateSection,
            onAddAtPosition: _addAtPosition,
            onRescan: _onRescan,
            onAddMore: _onAddMore,
            onSave: _requestSave,
          ),
      },
    );
  }

  Future<void> _showEditSheet(int index) async {
    final group = _currentGroup;
    if (group == null) return;
    final result = await showModalBottomSheet<_EditableSection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSectionSheet(section: group.sections[index]),
    );
    if (result != null && mounted) setState(() => group.sections[index] = result);
  }
}

// ── Enums & models ────────────────────────────────────────────────────────────

enum _ScanStep { capture, uploading, analyzing, review }

enum _ResizeHandle { topLeft, topRight, bottomLeft, bottomRight }

class _ScanGroup {
  _ScanGroup({
    required this.imageBytes,
    required this.mimeType,
    required this.sections,
    this.furnitureName = '',
    this.confidence = 0,
    this.annotatedBytes,
  });

  final Uint8List imageBytes;
  final String mimeType;
  List<_EditableSection> sections;
  String furnitureName;
  final double confidence;
  Uint8List? annotatedBytes;
}

class _BoundingBox {
  const _BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
  final double x, y, width, height;
}

class _EditableSection {
  _EditableSection({
    required this.code,
    required this.name,
    required this.type,
    this.notes,
    this.selected = true,
    this.boundingBox,
    this.row = 1,
    this.column = 'A',
  });

  final String code, name, type;
  final String? notes;
  final bool selected;
  final _BoundingBox? boundingBox;
  final int row;
  final String column;

  _EditableSection copyWith({
    String? code,
    String? name,
    String? type,
    String? notes,
    bool? selected,
    _BoundingBox? boundingBox,
    int? row,
    String? column,
  }) =>
      _EditableSection(
        code: code ?? this.code,
        name: name ?? this.name,
        type: type ?? this.type,
        notes: notes ?? this.notes,
        selected: selected ?? this.selected,
        boundingBox: boundingBox ?? this.boundingBox,
        row: row ?? this.row,
        column: column ?? this.column,
      );
}

// ── Type icon helper ──────────────────────────────────────────────────────────

IconData _iconForSectionType(String type) => switch (type) {
      'drawer' => Icons.density_medium,
      'cabinet' => Icons.door_front_door_outlined,
      'shelf' => Icons.shelves,
      'rack' => Icons.grid_view_outlined,
      'safe' => Icons.lock_outline,
      'compartment' => Icons.grid_on,
      _ => Icons.category_outlined,
    };

// ── Capture view ──────────────────────────────────────────────────────────────

class _CaptureView extends StatelessWidget {
  const _CaptureView({
    required this.onPick,
    required this.previousGroupCount,
    required this.previousSectionCount,
  });

  final Future<void> Function(ImageSource) onPick;
  final int previousGroupCount;
  final int previousSectionCount;

  @override
  Widget build(BuildContext context) {
    final isAddingMore = previousGroupCount > 0;
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
            Text(
              isAddingMore
                  ? 'Scan another piece of furniture'
                  : 'Take a photo of the storage furniture',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAddingMore
                  ? '$previousSectionCount section${previousSectionCount == 1 ? '' : 's'} mapped across $previousGroupCount cabinet${previousGroupCount == 1 ? '' : 's'}.'
                  : 'AI will detect every drawer, cabinet, and shelf — then pin the codes directly on the photo.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.onSurfaceVariant),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Progress view ─────────────────────────────────────────────────────────────

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
          Text(message, style: const TextStyle(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Annotated review view ─────────────────────────────────────────────────────

class _AnnotatedReviewView extends StatefulWidget {
  const _AnnotatedReviewView({
    required this.imageBytes,
    required this.roomName,
    required this.furnitureDescription,
    required this.confidence,
    required this.sections,
    required this.saving,
    required this.annotatedKey,
    required this.previousGroupCount,
    required this.previousSectionCount,
    required this.totalSelectedCount,
    required this.onToggle,
    required this.onEdit,
    required this.onRemove,
    required this.onUpdateSection,
    required this.onAddAtPosition,
    required this.onRescan,
    required this.onAddMore,
    required this.onSave,
  });

  final Uint8List imageBytes;
  final String roomName, furnitureDescription;
  final double confidence;
  final List<_EditableSection> sections;
  final bool saving;
  final GlobalKey annotatedKey;
  final int previousGroupCount;
  final int previousSectionCount;
  final int totalSelectedCount;
  final void Function(int) onToggle;
  final void Function(int) onEdit;
  final void Function(int) onRemove;
  final void Function(int, _EditableSection) onUpdateSection;
  final void Function(double fracX, double fracY) onAddAtPosition;
  final VoidCallback onRescan, onSave;
  final Future<void> Function() onAddMore;

  @override
  State<_AnnotatedReviewView> createState() => _AnnotatedReviewViewState();
}

class _AnnotatedReviewViewState extends State<_AnnotatedReviewView> {
  Size? _naturalImageSize;
  bool _moveMode = false;

  int? _draggingIndex;
  Offset _dragTotal = Offset.zero;
  _ResizeHandle? _resizingHandle;

  double _renderedW = 0, _renderedH = 0, _offsetX = 0, _offsetY = 0;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  @override
  void didUpdateWidget(_AnnotatedReviewView old) {
    super.didUpdateWidget(old);
    if (old.imageBytes != widget.imageBytes) {
      setState(() => _naturalImageSize = null);
      _loadImageSize();
    }
  }

  void _loadImageSize() {
    MemoryImage(widget.imageBytes).resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((info, _) {
        if (mounted) {
          setState(() => _naturalImageSize = Size(
                info.image.width.toDouble(),
                info.image.height.toDouble(),
              ));
        }
      }),
    );
  }

  void _updateLayout(double containerW, double containerH) {
    if (_naturalImageSize == null) return;
    final scale = min(containerW / _naturalImageSize!.width,
        containerH / _naturalImageSize!.height);
    _renderedW = _naturalImageSize!.width * scale;
    _renderedH = _naturalImageSize!.height * scale;
    _offsetX = (containerW - _renderedW) / 2;
    _offsetY = (containerH - _renderedH) / 2;
  }

  bool get _layoutReady => _naturalImageSize != null && _renderedW > 0;

  int get _selectedCount => widget.sections.where((s) => s.selected).length;
  bool get _isLowConfidence => widget.confidence > 0 && widget.confidence < 0.6;

  void _onDragUpdate(int i, DragUpdateDetails details) {
    setState(() {
      _draggingIndex = i;
      _dragTotal += details.delta;
    });
  }

  void _onDragEnd(int i) {
    if (!_layoutReady) {
      setState(() { _draggingIndex = null; _dragTotal = Offset.zero; _resizingHandle = null; });
      return;
    }
    final s = widget.sections[i];
    final bbox = s.boundingBox;
    if (bbox != null) {
      final dx = _dragTotal.dx / _renderedW;
      final dy = _dragTotal.dy / _renderedH;
      final handle = _resizingHandle;
      _BoundingBox newBbox;
      if (handle == null) {
        newBbox = _BoundingBox(
          x: (bbox.x + dx).clamp(0.0, 1.0 - bbox.width),
          y: (bbox.y + dy).clamp(0.0, 1.0 - bbox.height),
          width: bbox.width,
          height: bbox.height,
        );
      } else {
        double nx = bbox.x, ny = bbox.y, nw = bbox.width, nh = bbox.height;
        const minSize = 0.04;
        switch (handle) {
          case _ResizeHandle.topLeft:
            nx = (bbox.x + dx).clamp(0.0, bbox.x + bbox.width - minSize);
            ny = (bbox.y + dy).clamp(0.0, bbox.y + bbox.height - minSize);
            nw = (bbox.x + bbox.width) - nx;
            nh = (bbox.y + bbox.height) - ny;
          case _ResizeHandle.topRight:
            ny = (bbox.y + dy).clamp(0.0, bbox.y + bbox.height - minSize);
            nw = (bbox.width + dx).clamp(minSize, 1.0 - bbox.x);
            nh = (bbox.y + bbox.height) - ny;
          case _ResizeHandle.bottomLeft:
            nx = (bbox.x + dx).clamp(0.0, bbox.x + bbox.width - minSize);
            nw = (bbox.x + bbox.width) - nx;
            nh = (bbox.height + dy).clamp(minSize, 1.0 - bbox.y);
          case _ResizeHandle.bottomRight:
            nw = (bbox.width + dx).clamp(minSize, 1.0 - bbox.x);
            nh = (bbox.height + dy).clamp(minSize, 1.0 - bbox.y);
        }
        newBbox = _BoundingBox(x: nx, y: ny, width: nw, height: nh);
      }
      widget.onUpdateSection(i, s.copyWith(boundingBox: newBbox));
    }
    setState(() { _draggingIndex = null; _dragTotal = Offset.zero; _resizingHandle = null; });
  }

  void _handleImageTap(Offset localPos) {
    if (_moveMode || !_layoutReady) return;
    final fracX = ((localPos.dx - _offsetX) / _renderedW).clamp(0.0, 1.0);
    final fracY = ((localPos.dy - _offsetY) / _renderedH).clamp(0.0, 1.0);
    widget.onAddAtPosition(fracX, fracY);
  }

  @override
  Widget build(BuildContext context) {
    final hasPrevious = widget.previousGroupCount > 0;

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

        // Previous cabinets badge
        if (hasPrevious)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accent.withAlpha(60)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.accent, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${widget.previousSectionCount} section${widget.previousSectionCount == 1 ? '' : 's'} mapped from ${widget.previousGroupCount} previous cabinet${widget.previousGroupCount == 1 ? '' : 's'}',
                  style: const TextStyle(color: AppColors.accent, fontSize: 12),
                ),
              ],
            ),
          ),

        // Low confidence warning
        if (_isLowConfidence)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFCA28)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Low confidence — retake in better lighting or closer to the furniture.',
                    style: TextStyle(color: Color(0xFF5D3A00), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        // Move-mode hint
        if (_moveMode)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accent.withAlpha(80)),
            ),
            child: const Row(
              children: [
                Icon(Icons.open_with, color: AppColors.accent, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Drag any section box to reposition it. Tap the move button again to exit.',
                    style: TextStyle(color: AppColors.accent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        // Annotated image
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                RepaintBoundary(
                  key: widget.annotatedKey,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _moveMode
                        ? _buildImageStack()
                        : InteractiveViewer(
                            minScale: 1.0,
                            maxScale: 4.0,
                            child: _buildImageStack(),
                          ),
                  ),
                ),
                if (_layoutReady)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _moveMode = !_moveMode;
                        _draggingIndex = null;
                        _dragTotal = Offset.zero;
                      }),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _moveMode
                              ? AppColors.accent
                              : Colors.black.withAlpha(140),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.open_with,
                          size: 18,
                          color: _moveMode ? AppColors.background : Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Bottom actions
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16,
              MediaQuery.of(context).padding.bottom + 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.surfaceVariant)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: widget.onAddMore,
                  icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                  label: const Text('Scan another piece'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: widget.onRescan,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onSurfaceVariant,
                      side: BorderSide(
                          color: AppColors.onSurfaceVariant.withAlpha(100)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Rescan'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: (widget.saving || widget.totalSelectedCount == 0)
                          ? null
                          : widget.onSave,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: widget.saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Save ${widget.totalSelectedCount} section${widget.totalSelectedCount == 1 ? '' : 's'}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageStack() {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        _updateLayout(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onTapUp: (d) => _handleImageTap(d.localPosition),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                widget.imageBytes,
                fit: BoxFit.contain,
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              ),
              if (_naturalImageSize == null)
                Container(
                  color: Colors.black54,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.accent),
                      SizedBox(height: 14),
                      Text(
                        'Placing section markers…',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              else
                ..._buildOverlays(),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildOverlays() {
    return widget.sections.asMap().entries.map((entry) {
      final i = entry.key;
      final s = entry.value;
      final bbox = s.boundingBox;
      if (bbox == null) return const SizedBox.shrink();

      final isDragging = _draggingIndex == i;
      final dragDx = isDragging ? _dragTotal.dx : 0.0;
      final dragDy = isDragging ? _dragTotal.dy : 0.0;

      final centerX = _offsetX + (bbox.x + bbox.width / 2) * _renderedW + dragDx;
      final centerY = _offsetY + (bbox.y + bbox.height / 2) * _renderedH + dragDy;
      final rectLeft = _offsetX + bbox.x * _renderedW + dragDx;
      final rectTop = _offsetY + bbox.y * _renderedH + dragDy;
      final rectW = bbox.width * _renderedW;
      final rectH = bbox.height * _renderedH;

      return Stack(
        children: [
          Positioned(
            left: rectLeft,
            top: rectTop,
            child: GestureDetector(
              onPanUpdate: _moveMode ? (d) => _onDragUpdate(i, d) : null,
              onPanEnd: _moveMode ? (_) => _onDragEnd(i) : null,
              child: Container(
                width: rectW,
                height: rectH,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDragging
                        ? AppColors.accent
                        : s.selected
                            ? AppColors.accent.withAlpha(180)
                            : AppColors.onSurfaceVariant.withAlpha(100),
                    width: isDragging ? 2.5 : 1.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: isDragging
                      ? AppColors.accent.withAlpha(40)
                      : s.selected
                          ? AppColors.accent.withAlpha(20)
                          : Colors.black.withAlpha(20),
                ),
              ),
            ),
          ),
          if (_moveMode) ...[
            for (final handle in _ResizeHandle.values)
              Positioned(
                left: switch (handle) {
                  _ResizeHandle.topLeft || _ResizeHandle.bottomLeft =>
                    rectLeft + dragDx - 7,
                  _ => rectLeft + rectW + dragDx - 7,
                },
                top: switch (handle) {
                  _ResizeHandle.topLeft || _ResizeHandle.topRight =>
                    rectTop + dragDy - 7,
                  _ => rectTop + rectH + dragDy - 7,
                },
                child: GestureDetector(
                  onPanUpdate: (d) {
                    setState(() {
                      _draggingIndex = i;
                      _resizingHandle = handle;
                      _dragTotal += d.delta;
                    });
                  },
                  onPanEnd: (_) => _onDragEnd(i),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(80),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
          Positioned(
            left: centerX - 36,
            top: centerY - 16,
            child: _SectionChip(
              section: s,
              moveMode: _moveMode,
              onTap: _moveMode ? null : () => widget.onToggle(i),
              onEdit: _moveMode ? null : () => widget.onEdit(i),
              onRemove: _moveMode ? null : () => widget.onRemove(i),
              onPanUpdate: _moveMode ? (d) => _onDragUpdate(i, d) : null,
              onPanEnd: _moveMode ? (_) => _onDragEnd(i) : null,
            ),
          ),
        ],
      );
    }).toList();
  }
}

// ── Section chip ──────────────────────────────────────────────────────────────

class _SectionChip extends StatelessWidget {
  const _SectionChip({
    required this.section,
    required this.moveMode,
    required this.onTap,
    required this.onEdit,
    required this.onRemove,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final _EditableSection section;
  final bool moveMode;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final void Function(DragUpdateDetails)? onPanUpdate;
  final void Function(DragEndDetails)? onPanEnd;

  @override
  Widget build(BuildContext context) {
    final isSelected = section.selected;
    final bg = moveMode
        ? Colors.black87
        : isSelected
            ? AppColors.accent
            : Colors.black54;
    final fg = isSelected && !moveMode ? AppColors.background : Colors.white;

    return GestureDetector(
      onTap: onTap,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 6, right: 4),
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
            Icon(
              _iconForSectionType(section.type),
              size: 12,
              color: fg.withAlpha(180),
            ),
            const SizedBox(width: 4),
            Text(
              section.code,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            if (moveMode) ...[
              const SizedBox(width: 4),
              Icon(Icons.open_with, size: 13, color: fg.withAlpha(180)),
            ] else ...[
              const SizedBox(width: 2),
              GestureDetector(
                onTap: onEdit,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                  child: Icon(Icons.edit_outlined, size: 13, color: fg.withAlpha(200)),
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 2, right: 4, top: 4, bottom: 4),
                  child: Icon(Icons.close, size: 13, color: fg.withAlpha(200)),
                ),
              ),
            ],
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
        style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Save summary sheet ────────────────────────────────────────────────────────

class _SaveSummarySheet extends StatefulWidget {
  const _SaveSummarySheet({
    required this.groups,
    required this.roomName,
    required this.initialFurnitureNames,
  });

  final List<_ScanGroup> groups;
  final String roomName;
  final Map<_ScanGroup, String> initialFurnitureNames;

  @override
  State<_SaveSummarySheet> createState() => _SaveSummarySheetState();
}

class _SaveSummarySheetState extends State<_SaveSummarySheet> {
  late final Map<_ScanGroup, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final g in widget.groups)
        g: TextEditingController(text: widget.initialFurnitureNames[g] ?? ''),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  int get _totalCount => widget.groups
      .fold(0, (sum, g) => sum + g.sections.where((s) => s.selected).length);

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.checklist_rtl_outlined,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saving $_totalCount section${_totalCount == 1 ? '' : 's'} to ${widget.roomName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.groups.length,
              itemBuilder: (_, gi) {
                final group = widget.groups[gi];
                final selected = group.sections.where((s) => s.selected).toList();
                final ctrl = _controllers[group]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (gi > 0) const Divider(height: 20),
                    // Furniture label field
                    TextField(
                      controller: ctrl,
                      decoration: InputDecoration(
                        labelText: 'Cabinet label (Cabinet ${gi + 1})',
                        hintText: 'e.g. Upper Cabinet, Island, Pantry…',
                        prefixIcon: const Icon(Icons.door_front_door_outlined,
                            size: 18, color: AppColors.accent),
                        filled: true,
                        fillColor: AppColors.background.withAlpha(80),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        labelStyle: const TextStyle(
                            color: AppColors.onSurfaceVariant, fontSize: 12),
                      ),
                      style: const TextStyle(
                          color: AppColors.onBackground, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    // Section list for this group
                    ...selected.map((s) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(_iconForSectionType(s.type),
                                        size: 14, color: AppColors.accent),
                                    Text(
                                      s.code,
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name.isNotEmpty ? s.name : s.code,
                                      style: const TextStyle(
                                        color: AppColors.onBackground,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      s.notes != null && s.notes!.isNotEmpty
                                          ? '${s.type} · ${s.notes}'
                                          : s.type,
                                      style: const TextStyle(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceVariant,
                    side: BorderSide(
                        color: AppColors.onSurfaceVariant.withAlpha(100)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Review'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final names = {
                        for (final entry in _controllers.entries)
                          entry.key: entry.value.text.trim(),
                      };
                      Navigator.of(context).pop(names);
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Confirm & Save'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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

// ── Edit section sheet ────────────────────────────────────────────────────────

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
                    decoration:
                        const InputDecoration(labelText: 'Code', hintText: '1A'),
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
                  .map((t) => DropdownMenuItem(
                      value: t.$1,
                      child: Row(
                        children: [
                          Icon(_iconForSectionType(t.$1),
                              size: 16, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(t.$2),
                        ],
                      )))
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
                    notes: _notesCtrl.text.trim().isEmpty
                        ? null
                        : _notesCtrl.text.trim(),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
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
