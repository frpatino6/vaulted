import 'dart:math' show min;

import 'package:cached_network_image/cached_network_image.dart';
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
import '../../household_members/data/models/household_member_model.dart';
import '../../household_members/domain/household_members_notifier.dart';
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
  late int _quantity;
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
    _quantity = item.quantity > 0 ? item.quantity : 1;

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

  Future<void> _openSectionPicker() async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SectionPickerSheet(
        sections: _availableSections,
        selectedSectionId: _selectedSectionId,
      ),
    );
    // picked == '' means "No section" was chosen; null means dismissed
    if (!mounted) return;
    if (picked != null) setState(() => _selectedSectionId = picked.isEmpty ? null : picked);
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
        quantity: _quantity,
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
    final members = ref.watch(householdMembersNotifierProvider).valueOrNull ??
        const <HouseholdMemberModel>[];
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
                        final list = await picker.pickMultipleMedia(
                          imageQuality: 80,
                          maxWidth: 1920,
                          maxHeight: 1920,
                        );
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
                          imageQuality: 80,
                          maxWidth: 1920,
                          maxHeight: 1920,
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
                  _QuantityStepper(
                    value: _quantity,
                    onChanged: (v) => setState(() => _quantity = v),
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
                      members: members,
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
                    _SectionPickerField(
                      sections: _availableSections,
                      selectedSectionId: _selectedSectionId,
                      onTap: _openSectionPicker,
                      onClear: () => setState(() => _selectedSectionId = null),
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

// ── Quantity stepper ──────────────────────────────────────────────────────

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.value, required this.onChanged});

  final int value;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Quantity',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton.outlined(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.remove, size: 16),
            style: IconButton.styleFrom(
              foregroundColor: value > 1 ? AppColors.accent : AppColors.onSurfaceVariant,
              side: BorderSide(
                color: value > 1
                    ? AppColors.accent.withValues(alpha: 0.5)
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ),
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton.outlined(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add, size: 16),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
            ),
            onPressed: () => onChanged(value + 1),
          ),
        ),
      ],
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

// ── Section picker field ───────────────────────────────────────────────────

class _SectionPickerField extends StatelessWidget {
  const _SectionPickerField({
    required this.sections,
    required this.selectedSectionId,
    required this.onTap,
    required this.onClear,
  });

  final List<RoomSectionModel> sections;
  final String? selectedSectionId;
  final VoidCallback onTap;
  final VoidCallback onClear;

  RoomSectionModel? get _selected =>
      selectedSectionId != null
          ? sections.where((s) => s.sectionId == selectedSectionId).firstOrNull
          : null;

  String _label(RoomSectionModel s) {
    final parts = <String>[
      if (s.furnitureName?.isNotEmpty == true) s.furnitureName!,
      s.code,
      if (s.name.isNotEmpty) s.name,
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final sel = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SECTION',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            letterSpacing: 1.5,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: sel != null
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : AppColors.onSurfaceVariant.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: sel != null
                    ? AppColors.accent.withValues(alpha: 0.4)
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.grid_view_outlined,
                  size: 18,
                  color: sel != null
                      ? AppColors.accent
                      : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    sel != null ? _label(sel) : 'Select section (optional)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: sel != null
                          ? AppColors.accent
                          : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (sel != null)
                  GestureDetector(
                    onTap: onClear,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.accent.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section picker sheet ───────────────────────────────────────────────────

class _SectionPickerSheet extends StatefulWidget {
  const _SectionPickerSheet({
    required this.sections,
    required this.selectedSectionId,
  });

  final List<RoomSectionModel> sections;
  final String? selectedSectionId;

  @override
  State<_SectionPickerSheet> createState() => _SectionPickerSheetState();
}

class _SectionPickerSheetState extends State<_SectionPickerSheet> {
  // photoUrl → natural image size
  final Map<String, Size> _imageSizes = {};

  Map<String, List<RoomSectionModel>> get _grouped {
    final map = <String, List<RoomSectionModel>>{};
    for (final s in widget.sections) {
      final key = s.furnitureName?.isNotEmpty == true ? s.furnitureName! : '';
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    for (final s in widget.sections) {
      if (s.photo != null) _loadImageSize(s.photo!);
    }
  }

  void _loadImageSize(String url) {
    if (_imageSizes.containsKey(url)) return;
    NetworkImage(url)
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((info, _) {
      if (mounted) {
        setState(() => _imageSizes[url] = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            ));
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped;
    final groupKeys = groups.keys.toList()
      ..sort((a, b) {
        if (a.isEmpty) return 1;
        if (b.isEmpty) return -1;
        return a.compareTo(b);
      });

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                const Icon(Icons.grid_view_outlined,
                    color: AppColors.accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Select section',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // "No section" option
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: Icon(
                    Icons.block_outlined,
                    size: 18,
                    color: widget.selectedSectionId == null
                        ? AppColors.accent
                        : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  title: Text(
                    'No section',
                    style: TextStyle(
                      color: widget.selectedSectionId == null
                          ? AppColors.accent
                          : AppColors.onBackground,
                      fontWeight: widget.selectedSectionId == null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: widget.selectedSectionId == null
                      ? const Icon(Icons.check, color: AppColors.accent, size: 18)
                      : null,
                  onTap: () => Navigator.of(context).pop(''),
                ),
                const Divider(height: 8),
                for (final key in groupKeys) ...[
                  _GroupHeader(label: key.isEmpty ? 'Unlabeled' : key),
                  const SizedBox(height: 8),
                  _CabinetVisualPicker(
                    sections: groups[key]!,
                    selectedSectionId: widget.selectedSectionId,
                    imageSizes: _imageSizes,
                    onSelect: (id) => Navigator.of(context).pop(id),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cabinet visual picker ──────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Row(
        children: [
          const Icon(Icons.kitchen_outlined, size: 14, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.accent,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CabinetVisualPicker extends StatelessWidget {
  const _CabinetVisualPicker({
    required this.sections,
    required this.selectedSectionId,
    required this.imageSizes,
    required this.onSelect,
  });

  final List<RoomSectionModel> sections;
  final String? selectedSectionId;
  final Map<String, Size> imageSizes;
  final void Function(String sectionId) onSelect;

  // First photo URL shared by sections in this group
  String? get _photoUrl {
    for (final s in sections) {
      if (s.photo != null) return s.photo;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _photoUrl;
    final sectionsWithBox = sections.where((s) => s.boundingBox != null).toList();
    final sectionsWithoutBox = sections.where((s) => s.boundingBox == null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visual photo picker (only when photo + at least one bbox exists)
        if (photoUrl != null && sectionsWithBox.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LayoutBuilder(
              builder: (_, constraints) {
                final w = constraints.maxWidth;
                final nat = imageSizes[photoUrl];
                final h = nat != null
                    ? (w * nat.height / nat.width).clamp(140.0, 300.0)
                    : 200.0;
                final scale =
                    nat != null ? min(w / nat.width, h / nat.height) : null;
                final renderedW = scale != null ? nat!.width * scale : 0.0;
                final renderedH = scale != null ? nat!.height * scale : 0.0;
                final offsetX = (w - renderedW) / 2;
                final offsetY = (h - renderedH) / 2;

                return SizedBox(
                  width: w,
                  height: h,
                  child: Stack(
                    children: [
                      Container(color: Colors.black),
                      CachedNetworkImage(
                        imageUrl: photoUrl,
                        width: w,
                        height: h,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => Container(
                          color: AppColors.accent.withValues(alpha: 0.08),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: Colors.white24),
                          ),
                        ),
                      ),
                      if (scale != null)
                        for (final s in sectionsWithBox)
                          _TappableBBox(
                            bbox: s.boundingBox!,
                            offsetX: offsetX,
                            offsetY: offsetY,
                            renderedW: renderedW,
                            renderedH: renderedH,
                            label: s.code,
                            isSelected: s.sectionId == selectedSectionId,
                            onTap: () => onSelect(s.sectionId),
                          ),
                    ],
                  ),
                );
              },
            ),
          ),
        // Fallback list for sections without bounding box
        if (sectionsWithoutBox.isNotEmpty || (photoUrl == null))
          ..._buildListTiles(
              context, photoUrl == null ? sections : sectionsWithoutBox),
      ],
    );
  }

  List<Widget> _buildListTiles(
      BuildContext context, List<RoomSectionModel> items) {
    return [
      for (final section in items)
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: selectedSectionId == section.sectionId
                  ? AppColors.accent.withValues(alpha: 0.18)
                  : AppColors.onSurfaceVariant.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                section.code,
                style: TextStyle(
                  color: selectedSectionId == section.sectionId
                      ? AppColors.accent
                      : AppColors.onBackground,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          title: Text(
            section.name.isNotEmpty ? section.name : section.code,
            style: TextStyle(
              color: selectedSectionId == section.sectionId
                  ? AppColors.accent
                  : AppColors.onBackground,
              fontWeight: selectedSectionId == section.sectionId
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
          subtitle: section.notes?.isNotEmpty == true
              ? Text(section.notes!,
                  style: const TextStyle(
                      color: AppColors.onSurfaceVariant, fontSize: 12))
              : null,
          trailing: selectedSectionId == section.sectionId
              ? const Icon(Icons.check, color: AppColors.accent, size: 18)
              : null,
          onTap: () => onSelect(section.sectionId),
        ),
    ];
  }
}

// ── Tappable bounding box overlay ─────────────────────────────────────────

class _TappableBBox extends StatelessWidget {
  const _TappableBBox({
    required this.bbox,
    required this.offsetX,
    required this.offsetY,
    required this.renderedW,
    required this.renderedH,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final SectionBoundingBox bbox;
  final double offsetX, offsetY, renderedW, renderedH;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final left = offsetX + bbox.x * renderedW;
    final top = offsetY + bbox.y * renderedH;
    final width = bbox.width * renderedW;
    final height = bbox.height * renderedH;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? AppColors.accent : Colors.white70,
              width: isSelected ? 2.5 : 1.5,
            ),
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.10),
          ),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Wardrobe fields ────────────────────────────────────────────────────────

class _WardrobeFieldsSection extends StatefulWidget {
  const _WardrobeFieldsSection({
    super.key,
    required this.initialValue,
    required this.members,
  });

  final WardrobeAttributes initialValue;
  final List<HouseholdMemberModel> members;

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
  String? _ownerMemberId;

  WardrobeAttributes get value => WardrobeAttributes(
    type: _type,
    brand: _trimOrNull(_brandController.text),
    size: _trimOrNull(_sizeController.text),
    color: _trimOrNull(_colorController.text),
    material: _trimOrNull(_materialController.text),
    season: _season,
    cleaningStatus: _cleaningStatus,
    ownerMemberId: _ownerMemberId,
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
    _ownerMemberId = widget.initialValue.ownerMemberId;
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
          initialValue: _ownerMemberId,
          decoration: const InputDecoration(labelText: 'Belongs to (optional)'),
          dropdownColor: AppColors.surfaceVariant,
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Unassigned'),
            ),
            ...widget.members.map(
              (member) => DropdownMenuItem<String>(
                value: member.id,
                child: Text(member.name),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _ownerMemberId = value),
        ),
        const SizedBox(height: AppSpacing.md),
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
