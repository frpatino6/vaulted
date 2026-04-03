import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/outfit_model.dart';
import '../data/outfit_repository_provider.dart';

class OutfitNotifier extends AsyncNotifier<List<OutfitModel>> {
  @override
  Future<List<OutfitModel>> build() {
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> createOutfit({
    required String name,
    String? description,
    String? season,
    String? occasion,
    required List<String> itemIds,
  }) async {
    await ref.read(outfitRepositoryProvider).createOutfit({
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      if (season != null && season.isNotEmpty) 'season': season,
      if (occasion != null && occasion.isNotEmpty) 'occasion': occasion,
      'itemIds': itemIds,
    });
    await refresh();
  }

  Future<void> deleteOutfit(String id) async {
    await ref.read(outfitRepositoryProvider).deleteOutfit(id);
    await refresh();
  }

  Future<List<OutfitModel>> _load() {
    return ref.read(outfitRepositoryProvider).getOutfits();
  }
}

final outfitNotifierProvider = AsyncNotifierProvider<OutfitNotifier, List<OutfitModel>>(
  OutfitNotifier.new,
);
