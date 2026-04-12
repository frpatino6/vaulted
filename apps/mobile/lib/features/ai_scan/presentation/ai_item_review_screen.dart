import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../inventory/data/item_repository_provider.dart';
import '../../inventory/domain/item_list_notifier.dart';
import '../../properties/data/models/floor_model.dart';
import '../../properties/data/models/room_model.dart';
import '../data/models/ai_scan_result_model.dart';

class AiItemReviewScreen extends ConsumerStatefulWidget {
  const AiItemReviewScreen({
    super.key,
    required this.propertyId,
    required this.result,
    required this.floors,
  });

  final String propertyId;
  final AiScanResult result;
  final List<FloorModel> floors;

  @override
  ConsumerState<AiItemReviewScreen> createState() => _AiItemReviewScreenState();
}

class _AiItemReviewScreenState extends ConsumerState<AiItemReviewScreen> {
  static const List<String> _categories = [
    'furniture', 'art', 'technology', 'wardrobe',
    'vehicles', 'wine', 'sports', 'other',
  ];

  late final TextEditingController _nameCtrl;
  late final TextEditingController _subcategoryCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _serialCtrl;
  late final TextEditingController _purchasePriceCtrl;
  late final TextEditingController _currentValueCtrl;
  late final TextEditingController _tagsCtrl;

  late String _category;
  RoomModel? _selectedRoom;
  bool _saving = false;

  List<RoomModel> get _allRooms =>
      widget.floors.expand((f) => f.rooms).toList();

  @override
  void initState() {
    super.initState();
    final r = widget.result;
    final inv = r.invoiceData;

    _nameCtrl = TextEditingController(text: r.name);
    _subcategoryCtrl = TextEditingController(text: r.subcategory);
    _brandCtrl = TextEditingController(text: r.brand ?? '');
    _serialCtrl = TextEditingController(text: inv?.serialNumber ?? '');
    _purchasePriceCtrl = TextEditingController(
      text: inv?.purchasePrice != null ? inv!.purchasePrice.toString() : '',
    );
    _currentValueCtrl = TextEditingController(
      text: r.estimatedValue != null ? r.estimatedValue.toString() : '',
    );
    _tagsCtrl = TextEditingController(
      text: r.tags.join(', '),
    );
    _category = _categories.contains(r.category) ? r.category : 'other';

    // Pre-select suggested room
    if (r.suggestedRoom != null) {
      _selectedRoom = _allRooms.firstWhere(
        (room) => room.roomId == r.suggestedRoom!.roomId,
        orElse: () => _allRooms.isNotEmpty ? _allRooms.first : _emptyRoom,
      );
    } else if (_allRooms.isNotEmpty) {
      _selectedRoom = null;
    }
  }

  RoomModel get _emptyRoom => const RoomModel(roomId: '', name: '', type: '');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subcategoryCtrl.dispose();
    _brandCtrl.dispose();
    _serialCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _currentValueCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        title: const Text('Review item'),
        actions: [
          // Confidence badge
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: _ConfidenceBadge(confidence: widget.result.confidence),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI notice banner
            _AiBanner(hasInvoice: widget.result.invoiceData != null),
            const SizedBox(height: AppSpacing.md),

            // Captured photos strip
            if (widget.result.capturedPhotoUrls.isNotEmpty) ...[
              _PhotoStrip(urls: widget.result.capturedPhotoUrls),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ── Name ──────────────────────────────────────────
            _AiField(
              label: 'NAME',
              aiSuggested: true,
              child: _textField(_nameCtrl, hint: 'Item name'),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Category ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _AiField(
                    label: 'CATEGORY',
                    aiSuggested: true,
                    child: _categoryDropdown(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _AiField(
                    label: 'SUBCATEGORY',
                    aiSuggested: widget.result.subcategory.isNotEmpty,
                    child: _textField(_subcategoryCtrl, hint: 'Opcional'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Brand ─────────────────────────────────────────
            _AiField(
              label: 'BRAND',
              aiSuggested: widget.result.brand != null,
              child: _textField(_brandCtrl, hint: 'Opcional'),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Room selector ─────────────────────────────────
            _AiField(
              label: 'ROOM',
              aiSuggested: widget.result.suggestedRoom != null,
              child: _roomDropdown(),
            ),
            if (widget.result.suggestedRoom?.reasoning.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  '✦ ${widget.result.suggestedRoom!.reasoning}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.accent,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            // ── Price + Value ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _AiField(
                    label: 'PURCHASE PRICE',
                    aiSuggested: widget.result.invoiceData?.purchasePrice != null,
                    child: _textField(
                      _purchasePriceCtrl,
                      hint: '\$0',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _AiField(
                    label: 'ESTIMATED VALUE',
                    aiSuggested: widget.result.estimatedValue != null,
                    child: _textField(
                      _currentValueCtrl,
                      hint: '\$0',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Serial number ─────────────────────────────────
            _AiField(
              label: 'SERIAL NUMBER',
              aiSuggested: widget.result.invoiceData?.serialNumber != null,
              child: _textField(_serialCtrl, hint: 'Opcional'),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Tags ──────────────────────────────────────────
            _AiField(
              label: 'TAGS',
              aiSuggested: widget.result.tags.isNotEmpty,
              child: _textField(_tagsCtrl, hint: 'tag1, tag2, ...'),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Save button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Save item',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                'Fields marked ✦ were suggested by AI — review before saving',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _textField(
    TextEditingController ctrl, {
    String hint = '',
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.onBackground, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: InputBorder.none,
      ),
    );
  }

  Widget _categoryDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _category,
          isExpanded: true,
          isDense: true,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: AppColors.onBackground, fontSize: 14),
          onChanged: (v) => setState(() => _category = v ?? _category),
          items: _categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
        ),
      ),
    );
  }

  Widget _roomDropdown() {
    final rooms = _allRooms;
    if (rooms.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          'No rooms available',
          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RoomModel>(
          value: _selectedRoom,
          isExpanded: true,
          isDense: true,
          hint: const Text(
            'Select a room',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
          ),
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: AppColors.onBackground, fontSize: 14),
          onChanged: (v) => setState(() => _selectedRoom = v),
          items: rooms
              .map(
                (r) => DropdownMenuItem(
                  value: r,
                  child: Text(r.name),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a room')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(itemRepositoryProvider);
      await repo.createItem(
        propertyId: widget.propertyId,
        roomId: _selectedRoom!.roomId,
        name: _nameCtrl.text.trim(),
        category: _category,
        subcategory: _subcategoryCtrl.text.trim(),
        serialNumber: _serialCtrl.text.trim().isEmpty
            ? null
            : _serialCtrl.text.trim(),
        purchasePrice: int.tryParse(
              _purchasePriceCtrl.text.replaceAll(RegExp(r'[^\d]'), ''),
            ) ??
            0,
        currentValue: int.tryParse(
              _currentValueCtrl.text.replaceAll(RegExp(r'[^\d]'), ''),
            ) ??
            0,
        tags: _tagsCtrl.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        photos: widget.result.capturedPhotoUrls.take(1).toList(),
        attributes: {
          if (_brandCtrl.text.trim().isNotEmpty) 'brand': _brandCtrl.text.trim(),
          ...widget.result.attributes,
        },
      );

      if (!mounted) return;

      // Refresh the room's item list if provider is available
      ref.invalidate(itemListNotifierProvider);

      // Navigate to the room where the item was saved
      context.go(
        '/properties/${widget.propertyId}/rooms/${_selectedRoom!.roomId}'
        '?name=${Uri.encodeComponent(_selectedRoom!.name)}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving item: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});
  final double confidence;

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        '✦ IA · $pct%',
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _AiBanner extends StatelessWidget {
  const _AiBanner({required this.hasInvoice});
  final bool hasInvoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Text('✦', style: TextStyle(color: AppColors.accent, fontSize: 18)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              hasInvoice
                  ? 'AI analyzed the product and receipt. Review the fields before saving.'
                  : 'AI analyzed the product. You can fill in additional fields manually.',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.urls});
  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            urls[i],
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 72,
              height: 72,
              color: AppColors.surface,
              child: const Icon(
                Icons.image_outlined,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps a field with a label and optional ✦ AI-suggested styling.
class _AiField extends StatelessWidget {
  const _AiField({
    required this.label,
    required this.aiSuggested,
    required this.child,
  });

  final String label;
  final bool aiSuggested;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (aiSuggested) ...[
              const SizedBox(width: 4),
              const Text(
                '✦',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.accent,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: aiSuggested
                ? AppColors.accent.withValues(alpha: 0.07)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: aiSuggested
                  ? AppColors.accent.withValues(alpha: 0.3)
                  : AppColors.surfaceVariant,
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}
