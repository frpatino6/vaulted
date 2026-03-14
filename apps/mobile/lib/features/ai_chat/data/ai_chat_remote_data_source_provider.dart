import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'ai_chat_remote_data_source.dart';

final aiChatRemoteDataSourceProvider = Provider<AiChatRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return AiChatRemoteDataSource(dio);
});
