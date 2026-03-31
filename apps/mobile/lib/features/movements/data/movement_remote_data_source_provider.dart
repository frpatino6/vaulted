import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'movement_remote_data_source.dart';

final movementRemoteDataSourceProvider =
    Provider<MovementRemoteDataSource>((ref) {
  return MovementRemoteDataSource(ref.watch(apiClientProvider));
});
