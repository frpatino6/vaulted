import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'insurance_remote_data_source_provider.dart';
import 'insurance_repository.dart';

final insuranceRepositoryProvider = Provider<InsuranceRepository>((ref) {
  return InsuranceRepository(ref.watch(insuranceRemoteDataSourceProvider));
});
