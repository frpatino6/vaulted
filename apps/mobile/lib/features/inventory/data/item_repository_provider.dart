import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'item_remote_data_source_provider.dart';
import 'item_repository.dart';
import 'models/item_history_model.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(ref.watch(itemRemoteDataSourceProvider));
});

final itemHistoryProvider =
    FutureProvider.family<List<ItemHistoryModel>, String>((ref, itemId) {
  return ref.read(itemRepositoryProvider).getItemHistory(itemId);
});
