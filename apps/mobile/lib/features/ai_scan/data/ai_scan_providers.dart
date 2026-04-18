import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import '../../media/data/media_repository_provider.dart';
import 'ai_scan_remote_data_source.dart';
import 'ai_scan_repository.dart';

final aiScanRemoteDataSourceProvider = Provider<AiScanRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return AiScanRemoteDataSource(dio);
});

final aiScanRepositoryProvider = Provider<AiScanRepository>((ref) {
  final remote = ref.watch(aiScanRemoteDataSourceProvider);
  final media = ref.watch(mediaRepositoryProvider);
  return AiScanRepository(remote, media);
});
