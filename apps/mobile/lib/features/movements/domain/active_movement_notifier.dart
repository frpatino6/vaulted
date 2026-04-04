import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/movement_model.dart';
import '../data/movement_repository_provider.dart';

/// Manages all in-progress draft movements for the current user.
/// Multiple drafts can exist simultaneously.
/// State is backed by the server — recoverable if the app restarts.
class ActiveMovementNotifier extends AsyncNotifier<List<MovementModel>> {
  @override
  Future<List<MovementModel>> build() async {
    try {
      return await ref.read(movementRepositoryProvider).getActiveDrafts();
    } catch (_) {
      return [];
    }
  }

  /// Creates a new draft movement and adds it to the list.
  Future<MovementModel> startMovement({
    required String operationType,
    required String title,
    String description = '',
    String destination = '',
    String destinationPropertyId = '',
    String destinationRoomId = '',
    String destinationPropertyName = '',
    String destinationRoomName = '',
    String? dueDate,
    String notes = '',
    String? propertyId,
  }) async {
    final movement = await ref.read(movementRepositoryProvider).createMovement(
          operationType: operationType,
          title: title,
          description: description,
          destination: destination,
          destinationPropertyId: destinationPropertyId,
          destinationRoomId: destinationRoomId,
          destinationPropertyName: destinationPropertyName,
          destinationRoomName: destinationRoomName,
          dueDate: dueDate,
          notes: notes,
          propertyId: propertyId,
        );
    final current = state.value ?? [];
    state = AsyncData([movement, ...current]);
    return movement;
  }

  /// Adds an item to the given movement and updates the list.
  Future<MovementModel> addItem(String movementId, String itemId) async {
    final movement =
        await ref.read(movementRepositoryProvider).addItem(movementId, itemId);
    _replace(movement);
    return movement;
  }

  /// Removes an item from the given movement and updates the list.
  Future<void> removeItem(String movementId, String itemId) async {
    final movement = await ref
        .read(movementRepositoryProvider)
        .removeItem(movementId, itemId);
    _replace(movement);
  }

  /// Activates a draft → removes it from drafts list (it transitions to active/completed).
  Future<MovementModel> activate(String movementId) async {
    final movement =
        await ref.read(movementRepositoryProvider).activate(movementId);
    _remove(movementId);
    return movement;
  }

  /// Cancels a movement and removes it from the drafts list.
  Future<void> cancel(String movementId) async {
    await ref.read(movementRepositoryProvider).cancel(movementId);
    _remove(movementId);
  }

  /// Refreshes the drafts list from the server.
  Future<void> refresh() async {
    try {
      final drafts =
          await ref.read(movementRepositoryProvider).getActiveDrafts();
      state = AsyncData(drafts);
    } catch (_) {
      // keep existing state on error
    }
  }

  void _replace(MovementModel updated) {
    final current = state.value ?? [];
    state = AsyncData(
      current
          .map((m) => m.id == updated.id ? updated : m)
          .toList(),
    );
  }

  void _remove(String movementId) {
    final current = state.value ?? [];
    state = AsyncData(current.where((m) => m.id != movementId).toList());
  }

  static String message(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['error']?['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
      if (e.error is String) return e.error as String;
    }
    return 'Something went wrong. Please try again.';
  }
}

final activeMovementNotifierProvider =
    AsyncNotifierProvider<ActiveMovementNotifier, List<MovementModel>>(
  ActiveMovementNotifier.new,
);
