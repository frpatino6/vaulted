import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../inventory/data/models/item_model.dart';
import '../../inventory/domain/search_notifier.dart';
import '../data/models/maintenance_model.dart';
import '../domain/maintenance_notifier.dart';

class AddMaintenanceSheet extends ConsumerStatefulWidget {
  const AddMaintenanceSheet({
    super.key,
    this.itemId,
    this.initialTitle,
    this.initialNotes,
  });

  final String? itemId;
  final String? initialTitle;
  final String? initialNotes;

  @override
  ConsumerState<AddMaintenanceSheet> createState() =>
      _AddMaintenanceSheetState();
}

class _AddMaintenanceSheetState extends ConsumerState<AddMaintenanceSheet> {
  final _formKey = GlobalKey<FormState>();

  late final _titleController =
      TextEditingController(text: widget.initialTitle ?? '');
  late final _descriptionController =
      TextEditingController(text: widget.initialNotes ?? '');
  final _providerNameController = TextEditingController();
  final _providerContactController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final _intervalController = TextEditingController();
  final _itemSearchController = TextEditingController();

  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 7));
  bool _isRecurring = false;
  bool _isSaving = false;

  // Only used when no itemId is pre-set
  String? _selectedItemId;
  String? _selectedItemName;
  bool _showItemResults = false;

  bool get _needsItemSelection => widget.itemId == null;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _providerNameController.dispose();
    _providerContactController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _intervalController.dispose();
    _itemSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Schedule Maintenance',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.onBackground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: AppColors.onSurfaceVariant,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      children: [
                        if (_needsItemSelection) ...[
                          _SectionLabel('Item'),
                          const SizedBox(height: AppSpacing.sm),
                          _ItemPickerField(
                            searchController: _itemSearchController,
                            selectedItemName: _selectedItemName,
                            showResults: _showItemResults,
                            onSearchChanged: (query) {
                              setState(() => _showItemResults = query.isNotEmpty);
                              if (query.isNotEmpty) {
                                ref
                                    .read(searchNotifierProvider.notifier)
                                    .search(query);
                              } else {
                                ref
                                    .read(searchNotifierProvider.notifier)
                                    .clear();
                              }
                            },
                            onItemSelected: (item) {
                              setState(() {
                                _selectedItemId = item.id;
                                _selectedItemName = item.name;
                                _showItemResults = false;
                                _itemSearchController.text = item.name;
                              });
                              ref
                                  .read(searchNotifierProvider.notifier)
                                  .clear();
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        _buildField(
                          controller: _titleController,
                          label: 'Title',
                          hint: 'e.g., HVAC Service, Oil Change',
                          isRequired: true,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildField(
                          controller: _descriptionController,
                          label: 'Description',
                          hint: 'What needs to be done?',
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DatePickerField(
                          label: 'Scheduled Date',
                          selectedDate: _scheduledDate,
                          onDateSelected: (d) =>
                              setState(() => _scheduledDate = d),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SectionLabel('Recurrence'),
                        const SizedBox(height: AppSpacing.sm),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Repeat periodically',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.onBackground),
                          ),
                          subtitle: Text(
                            'Creates the next maintenance automatically when marked complete',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          value: _isRecurring,
                          activeThumbColor: AppColors.accent,
                          onChanged: (v) => setState(() => _isRecurring = v),
                        ),
                        if (_isRecurring) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _buildField(
                            controller: _intervalController,
                            label: 'Repeat every (days)',
                            hint: 'e.g., 90 for every 3 months',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (!_isRecurring) return null;
                              final n = int.tryParse(v ?? '');
                              if (n == null || n < 1) {
                                return 'Enter a valid number of days';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel('Provider (optional)'),
                        const SizedBox(height: AppSpacing.sm),
                        _buildField(
                          controller: _providerNameController,
                          label: 'Provider / Technician',
                          hint: 'Company or person name',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildField(
                          controller: _providerContactController,
                          label: 'Contact',
                          hint: 'Phone or email',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel('Cost (optional)'),
                        const SizedBox(height: AppSpacing.sm),
                        _buildField(
                          controller: _costController,
                          label: 'Estimated cost (USD)',
                          hint: 'e.g., 250',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel('Notes (optional)'),
                        const SizedBox(height: AppSpacing.sm),
                        _buildField(
                          controller: _notesController,
                          label: 'Notes',
                          hint: 'Additional details or instructions',
                          maxLines: 4,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Text(
                                    'Schedule Maintenance',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final effectiveItemId = widget.itemId ?? _selectedItemId;
    if (effectiveItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item first')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final record = await ref
        .read(itemMaintenanceNotifierProvider(effectiveItemId).notifier)
        .schedule(
          title: _titleController.text.trim(),
          scheduledDate: _scheduledDate,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isRecurring: _isRecurring,
          recurrenceIntervalDays: _isRecurring
              ? int.tryParse(_intervalController.text.trim())
              : null,
          providerName: _providerNameController.text.trim().isEmpty
              ? null
              : _providerNameController.text.trim(),
          providerContact: _providerContactController.text.trim().isEmpty
              ? null
              : _providerContactController.text.trim(),
          cost: double.tryParse(_costController.text.trim()),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (record != null) {
      Navigator.pop(context, record);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to schedule maintenance')),
      );
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    bool isRequired = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.onBackground),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
        hintStyle: TextStyle(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: AppColors.surfaceVariant.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: AppColors.surfaceVariant.withValues(alpha: 0.4),
      ),
      validator: validator ??
          (isRequired
              ? (v) {
                  if (v == null || v.trim().isEmpty) return '$label is required';
                  return null;
                }
              : null),
    );
  }
}

// ---------------------------------------------------------------------------
// Item picker with inline search results
// ---------------------------------------------------------------------------

class _ItemPickerField extends ConsumerWidget {
  const _ItemPickerField({
    required this.searchController,
    required this.selectedItemName,
    required this.showResults,
    required this.onSearchChanged,
    required this.onItemSelected,
  });

  final TextEditingController searchController;
  final String? selectedItemName;
  final bool showResults;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ItemModel> onItemSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: searchController,
          style: TextStyle(color: AppColors.onBackground),
          decoration: InputDecoration(
            labelText: selectedItemName != null ? 'Item selected' : 'Search item',
            hintText: 'Type to search your inventory…',
            labelStyle: TextStyle(
              color: selectedItemName != null
                  ? AppColors.accent
                  : AppColors.onSurfaceVariant,
            ),
            hintStyle: TextStyle(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6)),
            prefixIcon: Icon(
              selectedItemName != null
                  ? Icons.check_circle_outline_rounded
                  : Icons.search_rounded,
              color: selectedItemName != null
                  ? AppColors.accent
                  : AppColors.onSurfaceVariant,
            ),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    color: AppColors.onSurfaceVariant,
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: selectedItemName != null
                    ? AppColors.accent.withValues(alpha: 0.5)
                    : AppColors.surfaceVariant.withValues(alpha: 0.8),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.accent),
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant.withValues(alpha: 0.4),
          ),
          onChanged: onSearchChanged,
          validator: (_) =>
              selectedItemName == null ? 'Please select an item' : null,
        ),
        if (showResults) ...[
          const SizedBox(height: AppSpacing.xs),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.8)),
            ),
            child: searchState.when(
              data: (items) {
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'No items found',
                      style:
                          TextStyle(color: AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return ListTile(
                      dense: true,
                      title: Text(
                        item.name,
                        style: TextStyle(
                          color: AppColors.onBackground,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        item.category,
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () => onItemSelected(item),
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Search failed. Try again.',
                  style: TextStyle(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final String label;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.accent,
                onPrimary: Colors.black,
                surface: AppColors.surface,
                onSurface: AppColors.onBackground,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onDateSelected(picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
          suffixIcon:
              Icon(Icons.calendar_today_outlined, color: AppColors.accent),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: AppColors.surfaceVariant.withValues(alpha: 0.8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.accent),
          ),
          filled: true,
          fillColor: AppColors.surfaceVariant.withValues(alpha: 0.4),
        ),
        child: Text(
          DateFormat.yMMMd().format(selectedDate),
          style: TextStyle(color: AppColors.onBackground),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.onSurfaceVariant,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Helper to show AddMaintenanceSheet and return the created record.
Future<MaintenanceModel?> showAddMaintenanceSheet(
  BuildContext context, {
  String? itemId,
  String? initialTitle,
  String? initialNotes,
}) {
  return showModalBottomSheet<MaintenanceModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddMaintenanceSheet(
      itemId: itemId,
      initialTitle: initialTitle,
      initialNotes: initialNotes,
    ),
  );
}
