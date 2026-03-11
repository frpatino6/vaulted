import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dashboard_repository_provider.dart';
import '../data/models/dashboard_model.dart';

final dashboardNotifierProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardModel?>(DashboardNotifier.new);

class DashboardNotifier extends AsyncNotifier<DashboardModel?> {
  @override
  Future<DashboardModel?> build() async {
    return load();
  }

  Future<DashboardModel?> load() async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(dashboardRepositoryProvider);
      final data = await repo.getDashboard();
      state = AsyncData(data);
      return data;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  static String message(Object error) {
    return error.toString().replaceFirst('DioException: ', '');
  }
}
