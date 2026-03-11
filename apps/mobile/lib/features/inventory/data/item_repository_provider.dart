import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'item_remote_data_source_provider.dart';
import 'item_repository.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(ref.watch(itemRemoteDataSourceProvider));
});
