import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'insurance_ai_remote_data_source.dart';

final insuranceAiRemoteDataSourceProvider =
    Provider<InsuranceAiRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InsuranceAiRemoteDataSource(apiClient.dio);
});
