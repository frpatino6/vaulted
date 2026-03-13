import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'search_remote_data_source_provider.dart';
import 'search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(searchRemoteDataSourceProvider));
});
