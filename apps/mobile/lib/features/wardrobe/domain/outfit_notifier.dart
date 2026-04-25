import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/outfit_model.dart';
import '../data/outfit_repository_provider.dart';

class OutfitNotifier extends AsyncNotifier<List<OutfitModel>> {
  String? _selectedMemberId;
  @override
  Future<List<OutfitModel>> build() {
    return _load();
  }

  Future<void> setOwnerMemberFilter(String? memberId) async {
    _selectedMemberId = memberId;
    await refresh();
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
    String? ownerMemberId,
  }) async {
    await ref.read(outfitRepositoryProvider).createOutfit({
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      if (season != null && season.isNotEmpty) 'season': season,
      if (occasion != null && occasion.isNotEmpty) 'occasion': occasion,
      'itemIds': itemIds,
      if (ownerMemberId != null && ownerMemberId.isNotEmpty)
        'ownerMemberId': ownerMemberId,
    });
    await refresh();
  }

  Future<void> deleteOutfit(String id) async {
    await ref.read(outfitRepositoryProvider).deleteOutfit(id);
    await refresh();
  }

  Future<List<OutfitModel>> _load() {
    return ref
        .read(outfitRepositoryProvider)
        .getOutfits(ownerMemberId: _selectedMemberId);
  }
}

final outfitNotifierProvider = AsyncNotifierProvider<OutfitNotifier, List<OutfitModel>>(
  OutfitNotifier.new,
);
