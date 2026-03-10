import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/auth_token_store.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../../core/network/auth_remote_data_source_provider.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    remote: ref.watch(authRemoteDataSourceProvider),
    secureStorage: ref.watch(secureStorageProvider),
    tokenStore: AuthTokenStore.instance,
  );
});
