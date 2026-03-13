import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/item_photo_picker.dart';
import '../../media/data/media_repository_provider.dart';
import '../data/item_repository_provider.dart';
import '../data/models/item_model.dart';
import '../domain/item_list_notifier.dart';
import '../domain/item_detail_notifier.dart';
import '../../dashboard/domain/dashboard_notifier.dart';

class EditItemSheet extends ConsumerStatefulWidget {
  const EditItemSheet({
    super.key,
    required this.item,
    required this.onUpdated,
  });

  final ItemModel item;
  final VoidCallback onUpdated;

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
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _currentValueController;
  late final TextEditingController _tagsController;

  late List<String> _existingPhotos;
  final List<XFile> _pendingPhotos = [];
  bool _uploadingPhotos = false;

  late String _category;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _existingPhotos = List.from(item.photos);
    _nameController = TextEditingController(text: item.name);
    _subcategoryController = TextEditingController(text: item.subcategory);
    _serialNumberController = TextEditingController(text: item.serialNumber ?? '');
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subcategoryController.dispose();
    _serialNumberController.dispose();
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
          : tagsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final serialNum = _serialNumberController.text.trim();

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
        serialNumber: serialNum.isEmpty ? null : serialNum,
        valuation: {
          'purchasePrice': purchasePrice,
          'currentValue': currentValue,
          'currency': 'USD',
        },
        tags: tags,
        photos: allPhotos,
      );
      await ref.read(itemDetailNotifierProvider.notifier).load(widget.item.id);
      await ref.read(itemListNotifierProvider.notifier).refresh();
      await ref.read(dashboardNotifierProvider.notifier).load();
      if (mounted) {
        widget.onUpdated();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated')),
        );
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
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: ListView(
          controller: scrollController,
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
                  final images = list.where((x) => x.path.isNotEmpty).toList();
                  if (images.isEmpty || !mounted) return;
                  setState(() {
                    final total = _existingPhotos.length + _pendingPhotos.length;
                    final remaining = 10 - total;
                    if (remaining > 0) {
                      _pendingPhotos.addAll(images.take(remaining));
                    }
                  });
                },
                onPickFromCamera: () async {
                  final picker = ImagePicker();
                  final file = await picker.pickImage(source: ImageSource.camera);
                  if (file == null || !mounted) return;
                  setState(() {
                    final total = _existingPhotos.length + _pendingPhotos.length;
                    if (total < 10) _pendingPhotos.add(file);
                  });
                },
                onRemoveExisting: (index) => setState(() => _existingPhotos.removeAt(index)),
                onRemovePending: (index) => setState(() => _pendingPhotos.removeAt(index)),
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
              decoration: const InputDecoration(
                labelText: 'Category',
              ),
              dropdownColor: AppColors.surfaceVariant,
              items: EditItemSheet._categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c[0].toUpperCase() + c.substring(1),
                        style: const TextStyle(color: AppColors.onBackground),
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
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _serialNumberController,
              decoration: const InputDecoration(
                labelText: 'Serial number (optional)',
                hintText: 'e.g. SN123',
              ),
            ),
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
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 52,
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
          ],
        ),
      ),
    );
  }
}
