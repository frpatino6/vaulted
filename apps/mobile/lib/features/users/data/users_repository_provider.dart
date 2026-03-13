import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'users_remote_data_source_provider.dart';
import 'users_repository.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(ref.watch(usersRemoteDataSourceProvider));
});
