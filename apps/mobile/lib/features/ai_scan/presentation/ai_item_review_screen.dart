import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/help_screen_button.dart';
import '../../inventory/data/item_repository_provider.dart';
import '../../inventory/domain/item_list_notifier.dart';
import '../../properties/data/models/floor_model.dart';
import '../../properties/data/models/room_model.dart';
import '../../wardrobe/data/models/wardrobe_attributes.dart';
import '../data/models/ai_scan_result_model.dart';
import '../domain/ai_scan_notifier.dart';

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
  final _wardrobeSectionKey = GlobalKey<_AiWardrobeSectionState>();

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
          const HelpScreenButton(screenKey: 'ai_scan'),
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
            const SizedBox(height: AppSpacing.md),

            // ── Wardrobe details (only when category = wardrobe) ──
            if (_category == 'wardrobe') ...[
              _AiWardrobeSection(
                key: _wardrobeSectionKey,
                initial: WardrobeAttributes.fromMap(widget.result.attributes),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            const SizedBox(height: AppSpacing.lg),

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
            'No room — assign later',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
          ),
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: AppColors.onBackground, fontSize: 14),
          onChanged: (v) => setState(() => _selectedRoom = v),
          items: [
            const DropdownMenuItem<RoomModel>(
              value: null,
              child: Text(
                'No room — assign later',
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
            ...rooms.map(
              (r) => DropdownMenuItem(
                value: r,
                child: Text(r.name),
              ),
            ),
          ],
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
    setState(() => _saving = true);

    try {
      final repo = ref.read(itemRepositoryProvider);
      await repo.createItem(
        propertyId: widget.propertyId,
        roomId: _selectedRoom?.roomId,
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
        attributes: _category == 'wardrobe'
            ? {
                if (_brandCtrl.text.trim().isNotEmpty)
                  'brand': _brandCtrl.text.trim(),
                ..._wardrobeSectionKey.currentState?.value.toMap() ?? {},
              }
            : {
                if (_brandCtrl.text.trim().isNotEmpty)
                  'brand': _brandCtrl.text.trim(),
                ...widget.result.attributes,
              },
      );

      if (!mounted) return;

      // Refresh the room's item list if provider is available
      ref.invalidate(itemListNotifierProvider);
      if (_selectedRoom == null) {
        ref.invalidate(unlocatedItemsProvider(widget.propertyId));
      }

      // Reset notifier before popping so scan screen listener won't re-push review
      ref.read(aiScanNotifierProvider.notifier).reset();

      final router = GoRouter.of(context);
      final propertyId = widget.propertyId;
      final roomId = _selectedRoom?.roomId;
      final roomName = _selectedRoom?.name;

      // Pop review → scan screen (notifier already reset, no re-push)
      router.pop();

      // Next frame: pop scan → property detail, then push room if one was selected
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.pop();
        if (roomId != null && roomName != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            router.push(
              '/properties/$propertyId/rooms/$roomId'
              '?name=${Uri.encodeComponent(roomName)}',
            );
          });
        }
      });
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
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            urls[i],
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
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

// ─────────────────────────────────────────────────────────────────────────────
// Wardrobe section (shown when category == 'wardrobe')
// ─────────────────────────────────────────────────────────────────────────────

class _AiWardrobeSection extends StatefulWidget {
  const _AiWardrobeSection({super.key, required this.initial});
  final WardrobeAttributes initial;

  @override
  State<_AiWardrobeSection> createState() => _AiWardrobeSectionState();
}

class _AiWardrobeSectionState extends State<_AiWardrobeSection> {
  static const Map<String, String> _typeLabels = {
    'clothing': 'Clothing',
    'footwear': 'Footwear',
    'accessories': 'Accessories',
    'jewelry_watches': 'Jewelry & Watches',
  };

  static const Map<String, String> _seasonLabels = {
    'spring_summer': 'Spring/Summer',
    'fall_winter': 'Fall/Winter',
    'all_season': 'All Season',
  };

  static const Map<String, String> _cleaningLabels = {
    'clean': 'Clean ✓',
    'needs_cleaning': 'Needs Cleaning',
    'at_dry_cleaner': 'At Dry Cleaner',
  };

  late String? _type;
  late String? _season;
  late String? _cleaningStatus;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _sizeCtrl;
  late final TextEditingController _materialCtrl;

  WardrobeAttributes get value => WardrobeAttributes(
    type: _type,
    color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
    size: _sizeCtrl.text.trim().isEmpty ? null : _sizeCtrl.text.trim(),
    material: _materialCtrl.text.trim().isEmpty ? null : _materialCtrl.text.trim(),
    season: _season,
    cleaningStatus: _cleaningStatus,
  );

  @override
  void initState() {
    super.initState();
    _type = WardrobeAttributes.types.contains(widget.initial.type)
        ? widget.initial.type
        : null;
    _season = WardrobeAttributes.seasons.contains(widget.initial.season)
        ? widget.initial.season
        : null;
    _cleaningStatus =
        WardrobeAttributes.cleaningStatuses.contains(widget.initial.cleaningStatus)
            ? widget.initial.cleaningStatus
            : null;
    _colorCtrl = TextEditingController(text: widget.initial.color ?? '');
    _sizeCtrl = TextEditingController(text: widget.initial.size ?? '');
    _materialCtrl = TextEditingController(text: widget.initial.material ?? '');
  }

  @override
  void dispose() {
    _colorCtrl.dispose();
    _sizeCtrl.dispose();
    _materialCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'WARDROBE DETAILS',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            const Text('✦', style: TextStyle(fontSize: 10, color: AppColors.accent)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Type
        _AiField(
          label: 'TYPE',
          aiSuggested: widget.initial.type != null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _type,
                isExpanded: true,
                isDense: true,
                hint: const Text(
                  'Select type',
                  style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
                ),
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.onBackground, fontSize: 14),
                onChanged: (v) => setState(() => _type = v),
                items: WardrobeAttributes.types
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_typeLabels[t] ?? t),
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Color
        _AiField(
          label: 'COLOR',
          aiSuggested: widget.initial.color != null,
          child: _textInput(_colorCtrl, hint: 'e.g. navy blue'),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Size
        _AiField(
          label: 'SIZE',
          aiSuggested: widget.initial.size != null,
          child: _textInput(_sizeCtrl, hint: 'S / M / L / 42 / 38…'),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Material
        _AiField(
          label: 'MATERIAL',
          aiSuggested: widget.initial.material != null,
          child: _textInput(_materialCtrl, hint: 'e.g. cotton, leather'),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Season
        _AiField(
          label: 'SEASON',
          aiSuggested: widget.initial.season != null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _season,
                isExpanded: true,
                isDense: true,
                hint: const Text(
                  'Select season',
                  style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
                ),
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.onBackground, fontSize: 14),
                onChanged: (v) => setState(() => _season = v),
                items: WardrobeAttributes.seasons
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(_seasonLabels[s] ?? s),
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Cleaning status
        _AiField(
          label: 'CLEANING STATUS',
          aiSuggested: widget.initial.cleaningStatus != null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _cleaningStatus,
                isExpanded: true,
                isDense: true,
                hint: const Text(
                  'Select status',
                  style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
                ),
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.onBackground, fontSize: 14),
                onChanged: (v) => setState(() => _cleaningStatus = v),
                items: WardrobeAttributes.cleaningStatuses
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(_cleaningLabels[s] ?? s),
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _textInput(TextEditingController ctrl, {String hint = ''}) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: AppColors.onBackground, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: InputBorder.none,
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
