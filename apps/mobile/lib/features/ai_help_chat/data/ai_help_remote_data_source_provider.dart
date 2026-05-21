import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'ai_help_remote_data_source.dart';

final aiHelpRemoteDataSourceProvider = Provider<AiHelpRemoteDataSource>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return AiHelpRemoteDataSource(dio);
});
