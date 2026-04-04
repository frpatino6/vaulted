import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../properties/data/models/floor_model.dart';
import '../../properties/data/models/property_model.dart';
import '../../properties/data/models/room_model.dart';
import '../../properties/domain/properties_notifier.dart';
import '../data/models/movement_model.dart';
import '../domain/active_movement_notifier.dart';

class NewMovementSheet extends ConsumerStatefulWidget {
  const NewMovementSheet({super.key, required this.onCreated});

  final void Function(MovementModel) onCreated;

  @override
  ConsumerState<NewMovementSheet> createState() => _NewMovementSheetState();
}

class _NewMovementSheetState extends ConsumerState<NewMovementSheet> {
  String? _selectedType;
  final _titleCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _dueDate;
  bool _loading = false;
  String? _error;

  // Transfer destination selection
  PropertyModel? _destProperty;
  FloorModel? _destFloor;
  RoomModel? _destRoom;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _destinationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _isTransfer => _selectedType == 'transfer';

  bool get _canSubmit {
    if (_selectedType == null || _loading) return false;
    if (_titleCtrl.text.trim().isEmpty) return false;
    if (_isTransfer && (_destProperty == null || _destRoom == null)) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final propertiesState = ref.watch(propertiesNotifierProvider);
    final properties = propertiesState.value ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, bottom + AppSpacing.md),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              'New Operation',
              style: TextStyle(
                color: AppColors.onBackground,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Items are saved to the server as you scan them.',
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Operation type grid
            Text(
              'TYPE',
              style: TextStyle(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 2.6,
              children: _types
                  .map((t) => _TypeCard(
                        type: t,
                        selected: _selectedType == t.id,
                        onTap: () => setState(() {
                          _selectedType = t.id;
                          _destProperty = null;
                          _destFloor = null;
                          _destRoom = null;
                        }),
                      ))
                  .toList(),
            ),

            if (_selectedType != null) ...[
              const SizedBox(height: AppSpacing.lg),

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
              _Field(
                controller: _titleCtrl,
                hint: _hintForType(_selectedType!),
                maxLength: 80,
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: AppSpacing.md),

              // Destination — structured selector for Transfer, text field for others
              if (_isTransfer) ...[
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
              ] else ...[
                Text(
                  _destinationLabel(_selectedType!),
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _Field(
                  controller: _destinationCtrl,
                  hint: _destinationHint(_selectedType!),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // Due date (not for disposal)
              if (_selectedType != 'disposal') ...[
                Text(
                  'EXPECTED RETURN',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.onSurfaceVariant
                              .withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 16,
                            color: _dueDate != null
                                ? AppColors.accent
                                : AppColors.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _dueDate != null
                              ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                              : 'Optional — tap to set',
                          style: TextStyle(
                            color: _dueDate != null
                                ? AppColors.onBackground
                                : AppColors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        if (_dueDate != null) ...[
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() => _dueDate = null),
                            child: Icon(Icons.close,
                                size: 16, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

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
              _Field(
                controller: _notesCtrl,
                hint: 'Optional internal notes…',
                maxLines: 2,
              ),
            ],

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
                        style:
                            TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor:
                      AppColors.accent.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_scanner_rounded, size: 20),
                label: Text(
                  _loading ? 'Creating…' : 'Start Scanning Items',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.surfaceVariant,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Please enter a title');
      return;
    }
    if (_isTransfer && (_destProperty == null || _destRoom == null)) {
      setState(() => _error = 'Please select a destination property and room');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final movement =
          await ref.read(activeMovementNotifierProvider.notifier).startMovement(
                operationType: _selectedType!,
                title: title,
                destination: _isTransfer
                    ? '${_destProperty!.name} / ${_destRoom!.name}'
                    : _destinationCtrl.text.trim(),
                destinationPropertyId:
                    _isTransfer ? _destProperty!.id : '',
                destinationRoomId: _isTransfer ? _destRoom!.roomId : '',
                destinationPropertyName:
                    _isTransfer ? _destProperty!.name : '',
                destinationRoomName:
                    _isTransfer ? _destRoom!.name : '',
                notes: _notesCtrl.text.trim(),
                dueDate: _dueDate?.toIso8601String(),
              );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated(movement);
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
// Destination selector for Transfer type
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
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.15)),
        ),
        child: Text(
          'No properties available',
          style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
        ),
      );
    }

    return Column(
      children: [
        // Property dropdown
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

          // Floor dropdown
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

            // Room dropdown
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
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Color(0xFF2196F3), size: 16),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${selectedProperty!.name} · ${selectedFloor?.name ?? ''} · ${selectedRoom!.name}',
                    style: const TextStyle(
                        color: Color(0xFF2196F3),
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
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
                : AppColors.onSurfaceVariant.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text(hint,
                  style: TextStyle(
                      color: AppColors.onSurfaceVariant, fontSize: 14)),
            ],
          ),
          isExpanded: true,
          dropdownColor: AppColors.surfaceVariant,
          style: TextStyle(color: AppColors.onBackground, fontSize: 14),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.onSurfaceVariant, size: 20),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(label(item),
                      style: TextStyle(
                          color: AppColors.onBackground, fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final _OperationType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected
              ? type.color.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? type.color.withValues(alpha: 0.7)
                : AppColors.onSurfaceVariant.withValues(alpha: 0.15),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(type.icon,
                color: selected ? type.color : AppColors.onSurfaceVariant,
                size: 20),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  type.label,
                  style: TextStyle(
                    color: selected ? type.color : AppColors.onBackground,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  type.subtitle,
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final int? maxLength;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      style: TextStyle(color: AppColors.onBackground, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
        counterStyle:
            TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class _OperationType {
  const _OperationType(
      {required this.id,
      required this.icon,
      required this.color,
      required this.label,
      required this.subtitle});

  final String id;
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
}

const _types = [
  _OperationType(
    id: 'transfer',
    icon: Icons.swap_horiz_rounded,
    color: Color(0xFF2196F3),
    label: 'Transfer',
    subtitle: 'Move to location',
  ),
  _OperationType(
    id: 'loan',
    icon: Icons.person_outline_rounded,
    color: Color(0xFF9C27B0),
    label: 'Loan',
    subtitle: 'Lend to someone',
  ),
  _OperationType(
    id: 'repair',
    icon: Icons.build_outlined,
    color: Color(0xFFFF9800),
    label: 'Repair',
    subtitle: 'Send for service',
  ),
  _OperationType(
    id: 'disposal',
    icon: Icons.delete_outline_rounded,
    color: Color(0xFFCF6679),
    label: 'Disposal',
    subtitle: 'Remove permanently',
  ),
];

String _hintForType(String type) => switch (type) {
      'loan' => 'e.g. Weekend loan to John',
      'repair' => 'e.g. Repair at ABC Service',
      'disposal' => 'e.g. Donate to charity',
      _ => 'e.g. Vacation to Aspen house',
    };

String _destinationLabel(String type) => switch (type) {
      'loan' => 'RECIPIENT',
      'repair' => 'SERVICE CENTER',
      'disposal' => 'DESTINATION / REASON',
      _ => 'DESTINATION',
    };

String _destinationHint(String type) => switch (type) {
      'loan' => 'e.g. John Doe',
      'repair' => 'e.g. ABC Repair Shop',
      'disposal' => 'e.g. Sold on eBay',
      _ => 'e.g. Storage Unit B',
    };
