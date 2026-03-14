import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inventory/data/item_repository_provider.dart';
import '../../inventory/data/models/item_model.dart';

class WardrobeNotifier extends AsyncNotifier<List<ItemModel>> {
  @override
  Future<List<ItemModel>> build() {
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<List<ItemModel>> _load() {
    return ref
        .read(itemRepositoryProvider)
        .getItems(propertyId: '', roomId: '', category: 'wardrobe');
  }

  Future<void> updateCleaningStatus({
    required ItemModel item,
    required String cleaningStatus,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final originalAttributes = item.attributes == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(item.attributes!);
    final nextAttributes = Map<String, dynamic>.from(originalAttributes)
      ..['cleaningStatus'] = cleaningStatus;

    state = AsyncData(
      current.map((entry) {
        if (entry.id != item.id) return entry;
        return entry.copyWith(attributes: nextAttributes);
      }).toList(),
    );

    try {
      final updated = await ref
          .read(itemRepositoryProvider)
          .updateItem(item.id, attributes: nextAttributes);
      final latest = state.valueOrNull;
      if (latest == null) return;
      state = AsyncData(
        latest.map((entry) {
          if (entry.id != item.id) return entry;
          return updated;
        }).toList(),
      );
    } catch (_) {
      final latest = state.valueOrNull;
      if (latest == null) return;
      state = AsyncData(
        latest.map((entry) {
          if (entry.id != item.id) return entry;
          return entry.copyWith(attributes: originalAttributes);
        }).toList(),
      );
      rethrow;
    }
  }
}

final wardrobeNotifierProvider =
    AsyncNotifierProvider<WardrobeNotifier, List<ItemModel>>(
      WardrobeNotifier.new,
    );
