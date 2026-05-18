import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'orchestrator_remote_data_source.dart';

final orchestratorRemoteDataSourceProvider =
    Provider<OrchestratorRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrchestratorRemoteDataSource(apiClient.dio);
});
