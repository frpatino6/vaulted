import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'movement_remote_data_source_provider.dart';
import 'movement_repository.dart';

final movementRepositoryProvider = Provider<MovementRepository>((ref) {
  return MovementRepository(ref.watch(movementRemoteDataSourceProvider));
});
