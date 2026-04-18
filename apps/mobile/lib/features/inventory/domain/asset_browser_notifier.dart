import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/item_repository_provider.dart';
import '../data/models/item_model.dart';
import '../data/search_repository_provider.dart';
import 'search_notifier.dart';

const _recentLimit = 5;

enum AssetSortBy { recent, valueDesc, nameAsc }

class AssetBrowserState {
  const AssetBrowserState({
    this.items = const [],
    this.query = '',
    this.category,
    this.status,
    this.propertyId,
    this.unlocated = false,
    this.sortBy = AssetSortBy.recent,
  });

  final List<ItemModel> items;
  final String query;
  final String? category;
  final String? status;
  final String? propertyId;
  final bool unlocated;
  final AssetSortBy sortBy;

  bool get isFiltered =>
      query.isNotEmpty ||
      category != null ||
      status != null ||
      propertyId != null ||
      unlocated;
}

List<ItemModel> _applySortBy(List<ItemModel> items, AssetSortBy sortBy) {
  final sorted = List<ItemModel>.from(items);
  switch (sortBy) {
    case AssetSortBy.recent:
      break;
    case AssetSortBy.valueDesc:
      sorted.sort(
        (a, b) => (b.valuation?.currentValue ?? 0)
            .compareTo(a.valuation?.currentValue ?? 0),
      );
    case AssetSortBy.nameAsc:
      sorted.sort((a, b) => a.name.compareTo(b.name));
  }
  return sorted;
}

class AssetBrowserNotifier extends AsyncNotifier<AssetBrowserState> {
  int _version = 0;

  @override
  Future<AssetBrowserState> build() async => const AssetBrowserState();

  Future<void> loadInitial() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final recent = await ref
          .read(itemRepositoryProvider)
          .getItems(limit: _recentLimit);
      return AssetBrowserState(items: recent);
    });
  }

  Future<void> applyFilters({
    required String query,
    String? category,
    String? status,
    String? propertyId,
    bool unlocated = false,
    AssetSortBy sortBy = AssetSortBy.recent,
  }) async {
    final currentVersion = ++_version;
    final trimmed = query.trim();

    if (trimmed.isEmpty &&
        category == null &&
        status == null &&
        propertyId == null &&
        !unlocated) {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() async {
        final recent = await ref
            .read(itemRepositoryProvider)
            .getItems(limit: _recentLimit);
        return AssetBrowserState(items: _applySortBy(recent, sortBy), sortBy: sortBy);
      });
      return;
    }

    if (trimmed.isNotEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (currentVersion != _version) return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (currentVersion != _version) {
        return state.valueOrNull ?? const AssetBrowserState();
      }

      List<ItemModel> results;

      if (trimmed.isNotEmpty) {
        results = await ref.read(searchRepositoryProvider).search(
          query: trimmed,
          category: category,
          status: status,
        );
        // Client-side filter by propertyId/unlocated when search is active
        if (propertyId != null) {
          results = results.where((i) => i.propertyId == propertyId).toList();
        }
        if (unlocated) {
          results = results.where((i) => i.roomId == null || i.roomId!.isEmpty).toList();
        }
      } else {
        results = await ref.read(itemRepositoryProvider).getItems(
          propertyId: propertyId,
          category: category,
          status: status,
          unlocated: unlocated,
        );
      }

      return AssetBrowserState(
        items: _applySortBy(results, sortBy),
        query: trimmed,
        category: category,
        status: status,
        propertyId: propertyId,
        unlocated: unlocated,
        sortBy: sortBy,
      );
    });
  }

  static String message(Object error) => SearchNotifier.message(error);
}

final assetBrowserNotifierProvider =
    AsyncNotifierProvider<AssetBrowserNotifier, AssetBrowserState>(
  AssetBrowserNotifier.new,
);
