import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/movement_model.dart';
import '../data/movement_repository_provider.dart';

/// Manages the in-progress movement draft for the current user.
/// Persists to the backend on every action so state is recoverable
/// if the app closes mid-operation.
class ActiveMovementNotifier extends AsyncNotifier<MovementModel?> {
  @override
  Future<MovementModel?> build() async {
    try {
      return await ref.read(movementRepositoryProvider).getActiveDraft();
    } catch (_) {
      return null;
    }
  }

  /// Creates a new draft movement. Throws if one already exists.
  Future<MovementModel> startMovement({
    required String operationType,
    required String title,
    String description = '',
    String destination = '',
    String? dueDate,
    String notes = '',
    String? propertyId,
  }) async {
    state = const AsyncLoading();
    final movement = await ref.read(movementRepositoryProvider).createMovement(
          operationType: operationType,
          title: title,
          description: description,
          destination: destination,
          dueDate: dueDate,
          notes: notes,
          propertyId: propertyId,
        );
    state = AsyncData(movement);
    return movement;
  }

  /// Adds an item by its ID and immediately persists. Returns updated movement.
  Future<MovementModel> addItem(String movementId, String itemId) async {
    final movement =
        await ref.read(movementRepositoryProvider).addItem(movementId, itemId);
    state = AsyncData(movement);
    return movement;
  }

  /// Removes an item from the draft.
  Future<void> removeItem(String movementId, String itemId) async {
    final movement = await ref
        .read(movementRepositoryProvider)
        .removeItem(movementId, itemId);
    state = AsyncData(movement);
  }

  /// Activates the draft → status becomes 'active' (or 'completed' for disposal).
  Future<MovementModel> activate(String movementId) async {
    final movement =
        await ref.read(movementRepositoryProvider).activate(movementId);
    // After activation the draft is gone; clear state
    state = const AsyncData(null);
    return movement;
  }

  /// Cancels the movement and restores item statuses.
  Future<void> cancel(String movementId) async {
    await ref.read(movementRepositoryProvider).cancel(movementId);
    state = const AsyncData(null);
  }

  /// Clears local state (e.g. after navigating away).
  void clear() => state = const AsyncData(null);

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
    AsyncNotifierProvider<ActiveMovementNotifier, MovementModel?>(
  ActiveMovementNotifier.new,
);
