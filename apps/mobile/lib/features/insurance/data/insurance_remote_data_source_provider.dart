import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'insurance_remote_data_source.dart';

final insuranceRemoteDataSourceProvider =
    Provider<InsuranceRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InsuranceRemoteDataSource(apiClient.dio);
});
