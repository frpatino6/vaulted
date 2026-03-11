import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'media_remote_data_source.dart';

final mediaRemoteDataSourceProvider = Provider<MediaRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return MediaRemoteDataSource(dio);
});
