import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/item_repository_provider.dart';
import '../domain/item_list_notifier.dart';

class AddItemSheet extends ConsumerStatefulWidget {
  const AddItemSheet({
    super.key,
    required this.propertyId,
    required this.roomId,
    required this.onAdded,
  });

  final String propertyId;
  final String roomId;
  final VoidCallback onAdded;

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
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  final _nameController = TextEditingController();
  final _subcategoryController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _tagsController = TextEditingController();

  String _category = 'furniture';
  bool _submitting = false;

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

  int? _parseInt(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^\d-]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final repo = ref.read(itemRepositoryProvider);
      final purchasePrice = _parseInt(_purchasePriceController.text) ?? 0;
      final currentValue = _parseInt(_currentValueController.text) ?? 0;
      final tagsStr = _tagsController.text.trim();
      final tags = tagsStr.isEmpty ? <String>[] : tagsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      await repo.createItem(
        propertyId: widget.propertyId,
        roomId: widget.roomId,
        name: name,
        category: _category,
        subcategory: _subcategoryController.text.trim(),
        serialNumber: _serialNumberController.text.trim().isEmpty ? null : _serialNumberController.text.trim(),
        purchasePrice: purchasePrice,
        currentValue: currentValue,
        tags: tags,
      );
      if (mounted) {
        widget.onAdded();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ItemListNotifier.message(e)),
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
              'Add item',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onBackground,
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
              items: AddItemSheet._categories
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
              onChanged: (v) => setState(() => _category = v ?? 'furniture'),
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
                hintText: '\$',
                prefixText: r'$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _currentValueController,
              decoration: const InputDecoration(
                labelText: 'Current value (optional)',
                hintText: '\$',
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
                    : const Text('Add item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
