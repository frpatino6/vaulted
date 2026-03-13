import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'search_remote_data_source.dart';

final searchRemoteDataSourceProvider = Provider<SearchRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SearchRemoteDataSource(apiClient.dio);
});
