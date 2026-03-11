import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_remote_data_source_provider.dart';
import 'dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dashboardRemoteDataSourceProvider)),
);
