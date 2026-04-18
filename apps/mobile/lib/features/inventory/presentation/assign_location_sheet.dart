import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../properties/data/models/floor_model.dart';
import '../../properties/data/models/room_model.dart';
import '../data/item_repository_provider.dart';
import '../domain/item_list_notifier.dart';

/// Bottom sheet that lets the user pick Floor → Room and assigns that location
/// to [itemId]. If [itemId] is null the sheet just returns the selected
/// [RoomModel] without making any API call (used inside AddItemSheet).
class AssignLocationSheet extends ConsumerStatefulWidget {
  const AssignLocationSheet({
    super.key,
    required this.floors,
    this.itemId,
    this.initialRoomId,
    this.title = 'Assign location',
  });

  final List<FloorModel> floors;
  final String? itemId;
  final String? initialRoomId;
  final String title;

  @override
  ConsumerState<AssignLocationSheet> createState() =>
      _AssignLocationSheetState();
}

class _AssignLocationSheetState extends ConsumerState<AssignLocationSheet> {
  FloorModel? _selectedFloor;
  RoomModel? _selectedRoom;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoomId != null) {
      for (final floor in widget.floors) {
        for (final room in floor.rooms) {
          if (room.roomId == widget.initialRoomId) {
            _selectedFloor = floor;
            _selectedRoom = room;
            return;
          }
        }
      }
    }
  }

  Future<void> _confirm() async {
    final room = _selectedRoom;
    if (room == null) return;

    final itemId = widget.itemId;
    if (itemId == null) {
      // Caller just wants the selected room (e.g. AddItemSheet)
      if (mounted) Navigator.of(context).pop(room);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(itemRepositoryProvider).assignLocation(
        itemId,
        roomId: room.roomId,
      );
      await ref.read(itemListNotifierProvider.notifier).refresh();
      if (mounted) Navigator.of(context).pop(room);
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
      if (mounted) setState(() => _saving = false);
    }
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
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
            widget.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<FloorModel>(
            initialValue: _selectedFloor,
            decoration: const InputDecoration(labelText: 'Floor'),
            dropdownColor: AppColors.surfaceVariant,
            hint: const Text('Select floor'),
            items: widget.floors
                .map(
                  (f) => DropdownMenuItem(
                    value: f,
                    child: Text(
                      f.name,
                      style: const TextStyle(color: AppColors.onBackground),
                    ),
                  ),
                )
                .toList(),
            onChanged: (floor) => setState(() {
              _selectedFloor = floor;
              _selectedRoom = null;
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<RoomModel>(
            initialValue: _selectedRoom,
            decoration: const InputDecoration(labelText: 'Room'),
            dropdownColor: AppColors.surfaceVariant,
            hint: const Text('Select room'),
            items: (_selectedFloor?.rooms ?? [])
                .map(
                  (r) => DropdownMenuItem(
                    value: r,
                    child: Text(
                      r.name,
                      style: const TextStyle(color: AppColors.onBackground),
                    ),
                  ),
                )
                .toList(),
            onChanged: _selectedFloor == null
                ? null
                : (room) => setState(() => _selectedRoom = room),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: (_selectedRoom == null || _saving) ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirm location'),
            ),
          ),
        ],
      ),
    );
  }
}
