import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client_provider.dart';
import '../../features/auth/data/auth_remote_data_source.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSource(apiClient.dio);
});
