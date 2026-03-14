import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inventory/data/item_repository_provider.dart';
import '../../inventory/data/models/item_model.dart';
import '../../inventory/data/search_repository_provider.dart';

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
    return _loadWardrobeItems();
  }

  Future<List<ItemModel>> _loadWardrobeItems() async {
    final searchItems = await ref
        .read(searchRepositoryProvider)
        .search(category: 'wardrobe');
    final normalizedSearch = _onlyWardrobe(searchItems);
    if (normalizedSearch.isNotEmpty) return normalizedSearch;

    final allItems = await ref
        .read(itemRepositoryProvider)
        .getItems(propertyId: '', roomId: '');
    return _onlyWardrobe(allItems);
  }

  List<ItemModel> _onlyWardrobe(List<ItemModel> items) {
    return items.where((item) => _isWardrobeCategory(item.category)).toList();
  }

  bool _isWardrobeCategory(String category) {
    return category.trim().toLowerCase() == 'wardrobe';
  }

  Future<void> updateCleaningStatus({
    required ItemModel item,
    required String cleaningStatus,
  }) async {
    final current = state.valueOrNull;
    if (current == null) {
      final latest = await _loadWardrobeItems();
      state = AsyncData(latest);
      return;
    }

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
      await _refreshSilently();
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

  Future<void> _refreshSilently() async {
    final latest = await _loadWardrobeItems();
    state = AsyncData(latest);
  }
}

final wardrobeNotifierProvider =
    AsyncNotifierProvider<WardrobeNotifier, List<ItemModel>>(
      WardrobeNotifier.new,
    );
