import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'property_remote_data_source.dart';

final propertyRemoteDataSourceProvider = Provider<PropertyRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PropertyRemoteDataSource(apiClient.dio);
});
