import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'item_remote_data_source.dart';

final itemRemoteDataSourceProvider = Provider<ItemRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ItemRemoteDataSource(apiClient.dio);
});
