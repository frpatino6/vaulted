import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_chat_remote_data_source_provider.dart';
import 'ai_chat_repository.dart';

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  final remote = ref.watch(aiChatRemoteDataSourceProvider);
  return AiChatRepository(remote);
});
