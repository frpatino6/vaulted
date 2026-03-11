import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'media_remote_data_source_provider.dart';
import 'media_repository.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final remote = ref.watch(mediaRemoteDataSourceProvider);
  return MediaRepository(remote);
});
