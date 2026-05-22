import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_help_remote_data_source_provider.dart';
import 'ai_help_repository.dart';

final aiHelpRepositoryProvider = Provider<AiHelpRepository>((ref) {
  final remote = ref.watch(aiHelpRemoteDataSourceProvider);
  return AiHelpRepository(remote);
});
