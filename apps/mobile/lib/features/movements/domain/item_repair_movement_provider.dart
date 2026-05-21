import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/movement_model.dart';
import '../data/movement_repository_provider.dart';

/// Returns the active or draft repair movement that contains [itemId], or null
/// if none exists (item is stuck / movement already completed).
final itemRepairMovementProvider =
    FutureProvider.family<MovementModel?, String>((ref, itemId) async {
  final movements = await ref
      .read(movementRepositoryProvider)
      .getMovementsForItem(itemId);
  return movements.where((m) => m.isActive || m.isDraft).firstOrNull;
});
