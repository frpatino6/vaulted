import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../properties/data/models/floor_model.dart';
import '../../properties/data/models/property_model.dart';
import '../../properties/data/models/room_model.dart';
import '../../properties/domain/properties_notifier.dart';
import '../data/movement_repository_provider.dart';
import '../domain/active_movement_notifier.dart';

void showQuickTransferSheet(
  BuildContext context, {
  required String itemId,
  required String itemName,
  required String itemCategory,
  VoidCallback? onTransferred,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => QuickTransferSheet(
      itemId: itemId,
      itemName: itemName,
      itemCategory: itemCategory,
      onTransferred: onTransferred,
    ),
  );
}

class QuickTransferSheet extends ConsumerStatefulWidget {
  const QuickTransferSheet({
    super.key,
    required this.itemId,
    required this.itemName,
    required this.itemCategory,
    this.onTransferred,
  });

  final String itemId;
  final String itemName;
  final String itemCategory;
  final VoidCallback? onTransferred;

  @override
  ConsumerState<QuickTransferSheet> createState() => _QuickTransferSheetState();
}

class _QuickTransferSheetState extends ConsumerState<QuickTransferSheet> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  PropertyModel? _destProperty;
  FloorModel? _destFloor;
  RoomModel? _destRoom;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = 'Transfer: ${widget.itemName}';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_loading &&
      _titleCtrl.text.trim().isNotEmpty &&
      _destProperty != null &&
      _destRoom != null;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final properties =
        ref.watch(propertiesNotifierProvider).value ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        bottom + AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    color: Color(0xFF2196F3),
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transfer Item',
                      style: TextStyle(
                        color: AppColors.onBackground,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Move to another location immediately',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Item chip
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.itemName,
                          style: const TextStyle(
                            color: AppColors.onBackground,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.itemCategory,
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Destination label
            Text(
              'DESTINATION',
              style: TextStyle(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _DestinationSelector(
              properties: properties,
              selectedProperty: _destProperty,
              selectedFloor: _destFloor,
              selectedRoom: _destRoom,
              onPropertyChanged: (p) => setState(() {
                _destProperty = p;
                _destFloor = null;
                _destRoom = null;
              }),
              onFloorChanged: (f) => setState(() {
                _destFloor = f;
                _destRoom = null;
              }),
              onRoomChanged: (r) => setState(() => _destRoom = r),
            ),

            const SizedBox(height: AppSpacing.md),

            // Title
            Text(
              'TITLE',
              style: TextStyle(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _TextField(
              controller: _titleCtrl,
              hint: 'Transfer title…',
              maxLength: 120,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: AppSpacing.md),

            // Notes
            Text(
              'NOTES',
              style: TextStyle(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _TextField(
              controller: _notesCtrl,
              hint: 'Optional internal notes…',
              maxLines: 2,
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFF2196F3).withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.swap_horiz_rounded, size: 20),
                label: Text(
                  _loading ? 'Transferring…' : 'Transfer Now',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(movementRepositoryProvider).quickTransfer(
        itemId: widget.itemId,
        title: _titleCtrl.text.trim(),
        destinationPropertyId: _destProperty!.id,
        destinationRoomId: _destRoom!.roomId,
        destinationPropertyName: _destProperty!.name,
        destinationRoomName: _destRoom!.name,
        notes: _notesCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onTransferred?.call();
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = ActiveMovementNotifier.message(e);
      });
    }
  }
}

// ---------------------------------------------------------------------------

class _DestinationSelector extends StatelessWidget {
  const _DestinationSelector({
    required this.properties,
    required this.selectedProperty,
    required this.selectedFloor,
    required this.selectedRoom,
    required this.onPropertyChanged,
    required this.onFloorChanged,
    required this.onRoomChanged,
  });

  final List<PropertyModel> properties;
  final PropertyModel? selectedProperty;
  final FloorModel? selectedFloor;
  final RoomModel? selectedRoom;
  final void Function(PropertyModel?) onPropertyChanged;
  final void Function(FloorModel?) onFloorChanged;
  final void Function(RoomModel?) onRoomChanged;

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          'No properties available',
          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
        ),
      );
    }

    return Column(
      children: [
        _DropdownField<PropertyModel>(
          value: selectedProperty,
          hint: 'Select property',
          icon: Icons.home_outlined,
          items: properties,
          label: (p) => p.name,
          onChanged: onPropertyChanged,
        ),

        if (selectedProperty != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _DropdownField<FloorModel>(
            value: selectedFloor,
            hint: 'Select floor',
            icon: Icons.layers_outlined,
            items: selectedProperty!.floors,
            label: (f) => f.name,
            onChanged: onFloorChanged,
          ),

          if (selectedFloor != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _DropdownField<RoomModel>(
              value: selectedRoom,
              hint: 'Select room',
              icon: Icons.room_outlined,
              items: selectedFloor!.rooms,
              label: (r) => r.name,
              onChanged: onRoomChanged,
            ),
          ],
        ],

        if (selectedProperty != null && selectedRoom != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF2196F3).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF2196F3),
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${selectedProperty!.name} · ${selectedFloor?.name ?? ''} · ${selectedRoom!.name}',
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.label,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final IconData icon;
  final List<T> items;
  final String Function(T) label;
  final void Function(T?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null
              ? const Color(0xFF2196F3).withValues(alpha: 0.5)
              : AppColors.onSurfaceVariant.withValues(alpha: 0.15),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text(
                hint,
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          isExpanded: true,
          dropdownColor: AppColors.surfaceVariant,
          style: TextStyle(color: AppColors.onBackground, fontSize: 14),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.onSurfaceVariant,
            size: 20,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    label(item),
                    style: TextStyle(
                      color: AppColors.onBackground,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final int? maxLength;
  final int maxLines;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.onBackground, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
        counterStyle: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF2196F3),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
