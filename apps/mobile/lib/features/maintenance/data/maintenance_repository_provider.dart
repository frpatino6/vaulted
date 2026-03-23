import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'maintenance_remote_data_source.dart';
import 'maintenance_repository.dart';

final maintenanceRemoteDataSourceProvider =
    Provider<MaintenanceRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MaintenanceRemoteDataSource(apiClient.dio);
});

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepository(ref.watch(maintenanceRemoteDataSourceProvider));
});
