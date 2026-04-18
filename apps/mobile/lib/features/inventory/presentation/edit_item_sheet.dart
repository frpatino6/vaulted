import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/item_photo_picker.dart';
import '../../media/data/media_repository_provider.dart';
import '../../properties/data/models/floor_model.dart';
import '../../properties/data/models/room_model.dart';
import '../../properties/data/models/room_section_model.dart';
import '../../wardrobe/data/models/wardrobe_attributes.dart';
import '../data/item_repository_provider.dart';
import '../data/models/item_model.dart';
import '../domain/item_list_notifier.dart';
import '../domain/item_detail_notifier.dart';
import '../../dashboard/domain/dashboard_notifier.dart';
import 'assign_location_sheet.dart';

class EditItemSheet extends ConsumerStatefulWidget {
  const EditItemSheet({
    super.key,
    required this.item,
    required this.onUpdated,
    this.floors,
  });

  final ItemModel item;
  final VoidCallback onUpdated;

  /// When provided, the user can change the item's room via a structured picker.
  final List<FloorModel>? floors;

  static const List<String> _categories = [
    'furniture',
    'art',
    'technology',
    'wardrobe',
    'vehicles',
    'wine',
    'sports',
    'other',
  ];

  @override
  ConsumerState<EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends ConsumerState<EditItemSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _subcategoryController;
  late final TextEditingController _serialNumberController;
  late final TextEditingController _locationDetailController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _currentValueController;
  late final TextEditingController _tagsController;

  late List<String> _existingPhotos;
  final List<XFile> _pendingPhotos = [];
  final GlobalKey<_WardrobeFieldsSectionState> _wardrobeSectionKey =
      GlobalKey<_WardrobeFieldsSectionState>();
  bool _uploadingPhotos = false;

  late String _category;
  bool _submitting = false;

  String? _selectedRoomId;
  String? _selectedRoomName;
  String? _selectedSectionId;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _existingPhotos = List.from(item.photos);
    _nameController = TextEditingController(text: item.name);
    _subcategoryController = TextEditingController(text: item.subcategory);
    _serialNumberController = TextEditingController(
      text: item.serialNumber ?? '',
    );
    _locationDetailController = TextEditingController(
      text: item.locationDetail ?? '',
    );
    _purchasePriceController = TextEditingController(
      text: item.valuation != null && item.valuation!.purchasePrice > 0
          ? item.valuation!.purchasePrice.toString()
          : '',
    );
    _currentValueController = TextEditingController(
      text: item.valuation != null && item.valuation!.currentValue > 0
          ? item.valuation!.currentValue.toString()
          : '',
    );
    _tagsController = TextEditingController(text: item.tags.join(', '));
    _category = EditItemSheet._categories.contains(item.category)
        ? item.category
        : 'other';

    _selectedRoomId = item.roomId;
    _selectedRoomName = _resolveRoomName(item.roomId);
    _selectedSectionId = item.sectionId;
  }

  String? _resolveRoomName(String? roomId) {
    if (roomId == null) return null;
    // Try to find the room name from floors if available
    final floors = widget.floors;
    if (floors == null) return widget.item.roomName ?? roomId;
    for (final floor in floors) {
      for (final room in floor.rooms) {
        if (room.roomId == roomId) return room.name;
      }
    }
    return widget.item.roomName ?? roomId;
  }

  Future<void> _openRoomPicker() async {
    final floors = widget.floors;
    if (floors == null || floors.isEmpty) return;
    final picked = await showModalBottomSheet<RoomModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssignLocationSheet(
        floors: floors,
        initialRoomId: _selectedRoomId,
        title: 'Change room',
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedRoomId = picked.roomId;
        _selectedRoomName = picked.name;
        _selectedSectionId = null;
      });
    }
  }

  List<RoomSectionModel> get _availableSections {
    if (_selectedRoomId == null || widget.floors == null) return [];
    for (final floor in widget.floors!) {
      for (final room in floor.rooms) {
        if (room.roomId == _selectedRoomId) return room.sections;
      }
    }
    return [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subcategoryController.dispose();
    _serialNumberController.dispose();
    _locationDetailController.dispose();
    _purchasePriceController.dispose();
    _currentValueController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  int _parseInt(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^\d-]'), '');
    if (cleaned.isEmpty) return 0;
    return int.tryParse(cleaned) ?? 0;
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final repo = ref.read(itemRepositoryProvider);
      final mediaRepo = ref.read(mediaRepositoryProvider);
      final purchasePrice = _parseInt(_purchasePriceController.text);
      final currentValue = _parseInt(_currentValueController.text);
      final tagsStr = _tagsController.text.trim();
      final tags = tagsStr.isEmpty
          ? <String>[]
          : tagsStr
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
      final serialNum = _serialNumberController.text.trim();
      final locationDet = _locationDetailController.text.trim();

      List<String> uploadedUrls = [];
      if (_pendingPhotos.isNotEmpty) {
        setState(() => _uploadingPhotos = true);
        int failedCount = 0;
        for (final file in _pendingPhotos) {
          try {
            final url = await mediaRepo.uploadPhoto(file);
            uploadedUrls.add(url);
          } catch (_) {
            failedCount++;
          }
        }
        if (mounted) setState(() => _uploadingPhotos = false);
        if (mounted && failedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$failedCount photo(s) could not be uploaded'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }

      final allPhotos = [..._existingPhotos, ...uploadedUrls];
      await repo.updateItem(
        widget.item.id,
        name: name,
        category: _category,
        subcategory: _subcategoryController.text.trim(),
        roomId: _selectedRoomId != widget.item.roomId ? _selectedRoomId : null,
        serialNumber: serialNum.isEmpty ? null : serialNum,
        locationDetail: _selectedSectionId == null && locationDet.isNotEmpty
            ? locationDet
            : null,
        sectionId: _selectedSectionId,
        valuation: {
          'purchasePrice': purchasePrice,
          'currentValue': currentValue,
          'currency': 'USD',
        },
        tags: tags,
        photos: allPhotos,
        attributes: _category == 'wardrobe'
            ? _wardrobeSectionKey.currentState?.value.toMap()
            : null,
      );
      await ref.read(itemDetailNotifierProvider.notifier).load(widget.item.id);
      await ref.read(itemListNotifierProvider.notifier).refresh();
      await ref.read(dashboardNotifierProvider.notifier).load();
      if (mounted) {
        widget.onUpdated();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ItemDetailNotifier.message(e)),
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
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // ── Scrollable form ──────────────────────────────────────────
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                  bottom: AppSpacing.sm,
                ),
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
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Edit item',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 100,
                    child: ItemPhotoPicker(
                      photos: _existingPhotos,
                      pendingFiles: _pendingPhotos,
                      onPickFromGallery: () async {
                        final picker = ImagePicker();
                        final list = await picker.pickMultipleMedia();
                        if (list.isEmpty || !mounted) return;
                        final images =
                            list.where((x) => x.path.isNotEmpty).toList();
                        if (images.isEmpty || !mounted) return;
                        setState(() {
                          final total =
                              _existingPhotos.length + _pendingPhotos.length;
                          final remaining = 10 - total;
                          if (remaining > 0) {
                            _pendingPhotos.addAll(images.take(remaining));
                          }
                        });
                      },
                      onPickFromCamera: () async {
                        final picker = ImagePicker();
                        final file = await picker.pickImage(
                          source: ImageSource.camera,
                        );
                        if (file == null || !mounted) return;
                        setState(() {
                          final total =
                              _existingPhotos.length + _pendingPhotos.length;
                          if (total < 10) _pendingPhotos.add(file);
                        });
                      },
                      onRemoveExisting: (index) =>
                          setState(() => _existingPhotos.removeAt(index)),
                      onRemovePending: (index) =>
                          setState(() => _pendingPhotos.removeAt(index)),
                      uploading: _uploadingPhotos,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Chesterfield Sofa',
                    ),
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    dropdownColor: AppColors.surfaceVariant,
                    items: EditItemSheet._categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c[0].toUpperCase() + c.substring(1),
                              style: const TextStyle(
                                color: AppColors.onBackground,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _category = v ?? 'other'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _subcategoryController,
                    decoration: const InputDecoration(
                      labelText: 'Subcategory (optional)',
                      hintText: 'e.g. living room',
                    ),
                  ),
                  if (_category == 'wardrobe') ...[
                    const SizedBox(height: AppSpacing.lg),
                    _WardrobeFieldsSection(
                      key: _wardrobeSectionKey,
                      initialValue: widget.item.wardrobeAttributes,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _serialNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Serial number (optional)',
                      hintText: 'e.g. SN123',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RoomPickerField(
                    roomName: _selectedRoomName,
                    canChange: (widget.floors?.isNotEmpty) ?? false,
                    onTap: _openRoomPicker,
                  ),
                  if (_availableSections.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: _selectedSectionId,
                      decoration: InputDecoration(
                        labelText: 'Section (optional)',
                        hintText: 'Select section',
                        prefixIcon: const Icon(
                          Icons.grid_view_outlined,
                          size: 18,
                        ),
                        suffixIcon: _selectedSectionId != null
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () => setState(
                                  () => _selectedSectionId = null,
                                ),
                              )
                            : null,
                      ),
                      dropdownColor: AppColors.surfaceVariant,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No section'),
                        ),
                        ..._availableSections.map(
                          (s) => DropdownMenuItem<String>(
                            value: s.sectionId,
                            child: Text('${s.code} – ${s.name}'),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedSectionId = v),
                    ),
                  ] else ...[
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _locationDetailController,
                      decoration: const InputDecoration(
                        labelText: 'Within room (optional)',
                        hintText: 'e.g. Left shelf, Cabinet 3',
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _purchasePriceController,
                    decoration: const InputDecoration(
                      labelText: 'Purchase price (optional)',
                      hintText: r'$',
                      prefixText: r'$ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _currentValueController,
                    decoration: const InputDecoration(
                      labelText: 'Current value (optional)',
                      hintText: r'$',
                      prefixText: r'$ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (optional)',
                      hintText: 'comma separated',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
            // ── Sticky save button — always visible ───────────────────────
            Container(
              color: AppColors.surfaceVariant,
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.sm,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
              ),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save changes'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Room picker field ──────────────────────────────────────────────────────

class _RoomPickerField extends StatelessWidget {
  const _RoomPickerField({
    required this.roomName,
    required this.canChange,
    required this.onTap,
  });

  final String? roomName;
  final bool canChange;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LOCATION',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            letterSpacing: 1.5,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: canChange ? onTap : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: roomName != null
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : AppColors.onSurfaceVariant.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: roomName != null
                    ? AppColors.accent.withValues(alpha: 0.4)
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  roomName != null
                      ? Icons.meeting_room_outlined
                      : Icons.location_off_outlined,
                  size: 18,
                  color: roomName != null
                      ? AppColors.accent
                      : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    roomName ?? 'No location assigned',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: roomName != null
                          ? AppColors.accent
                          : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                if (canChange)
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: roomName != null
                        ? AppColors.accent
                        : AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Wardrobe fields ────────────────────────────────────────────────────────

class _WardrobeFieldsSection extends StatefulWidget {
  const _WardrobeFieldsSection({super.key, required this.initialValue});

  final WardrobeAttributes initialValue;

  @override
  State<_WardrobeFieldsSection> createState() => _WardrobeFieldsSectionState();
}

class _WardrobeFieldsSectionState extends State<_WardrobeFieldsSection> {
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
  late final TextEditingController _brandController;
  late final TextEditingController _sizeController;
  late final TextEditingController _colorController;
  late final TextEditingController _materialController;

  WardrobeAttributes get value => WardrobeAttributes(
    type: _type,
    brand: _trimOrNull(_brandController.text),
    size: _trimOrNull(_sizeController.text),
    color: _trimOrNull(_colorController.text),
    material: _trimOrNull(_materialController.text),
    season: _season,
    cleaningStatus: _cleaningStatus,
  );

  String? _trimOrNull(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  @override
  void initState() {
    super.initState();
    _type = widget.initialValue.type;
    _season = widget.initialValue.season;
    _cleaningStatus = widget.initialValue.cleaningStatus;
    _brandController = TextEditingController(text: widget.initialValue.brand);
    _sizeController = TextEditingController(text: widget.initialValue.size);
    _colorController = TextEditingController(text: widget.initialValue.color);
    _materialController = TextEditingController(
      text: widget.initialValue.material,
    );
  }

  @override
  void dispose() {
    _brandController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _materialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WARDROBE DETAILS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            letterSpacing: 1.5,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Type'),
          dropdownColor: AppColors.surfaceVariant,
          items: WardrobeAttributes.types
              .map(
                (type) => DropdownMenuItem<String>(
                  value: type,
                  child: Text(
                    _typeLabels[type] ?? type,
                    style: const TextStyle(color: AppColors.onBackground),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _type = value),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _brandController,
          decoration: const InputDecoration(labelText: 'Brand (optional)'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _sizeController,
          decoration: const InputDecoration(
            labelText: 'Size (optional)',
            hintText: 'S / M / L / 42 / 38...',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _colorController,
          decoration: const InputDecoration(labelText: 'Color (optional)'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _materialController,
          decoration: const InputDecoration(labelText: 'Material (optional)'),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: _season,
          decoration: const InputDecoration(labelText: 'Season (optional)'),
          dropdownColor: AppColors.surfaceVariant,
          items: WardrobeAttributes.seasons
              .map(
                (season) => DropdownMenuItem<String>(
                  value: season,
                  child: Text(
                    _seasonLabels[season] ?? season,
                    style: const TextStyle(color: AppColors.onBackground),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _season = value),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: _cleaningStatus,
          decoration: const InputDecoration(
            labelText: 'Cleaning Status (optional)',
          ),
          dropdownColor: AppColors.surfaceVariant,
          items: WardrobeAttributes.cleaningStatuses
              .map(
                (status) => DropdownMenuItem<String>(
                  value: status,
                  child: Text(
                    _cleaningLabels[status] ?? status,
                    style: const TextStyle(color: AppColors.onBackground),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _cleaningStatus = value),
        ),
      ],
    );
  }
}
