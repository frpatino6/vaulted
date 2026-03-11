import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'property_remote_data_source_provider.dart';
import 'property_repository.dart';

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepository(ref.watch(propertyRemoteDataSourceProvider));
});
