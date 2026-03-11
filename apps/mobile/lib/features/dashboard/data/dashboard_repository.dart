import 'models/dashboard_model.dart';
import 'dashboard_remote_data_source.dart';

/// Repository for dashboard data.
class DashboardRepository {
  DashboardRepository(this._remote);

  final DashboardRemoteDataSource _remote;

  Future<DashboardModel> getDashboard() => _remote.getDashboard();
}
