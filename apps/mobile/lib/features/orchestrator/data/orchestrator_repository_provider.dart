import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'orchestrator_remote_data_source_provider.dart';
import 'orchestrator_repository.dart';

final orchestratorRepositoryProvider = Provider<OrchestratorRepository>((ref) {
  final dataSource = ref.watch(orchestratorRemoteDataSourceProvider);
  return OrchestratorRepository(dataSource);
});
