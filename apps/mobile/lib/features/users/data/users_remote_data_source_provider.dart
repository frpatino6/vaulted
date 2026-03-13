import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'users_remote_data_source.dart';

final usersRemoteDataSourceProvider = Provider<UsersRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UsersRemoteDataSource(apiClient.dio);
});
