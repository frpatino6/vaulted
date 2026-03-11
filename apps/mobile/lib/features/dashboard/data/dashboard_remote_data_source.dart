import 'package:dio/dio.dart';

import 'models/dashboard_model.dart';

/// Remote data source for GET /dashboard.
class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._dio);

  final Dio _dio;

  static const String _path = 'dashboard';

  Future<DashboardModel> getDashboard() async {
    final response = await _dio.get<Map<String, dynamic>>(_path);
    final data = _unwrapData(response);
    return DashboardModel.fromJson(
      Map<String, dynamic>.from(data is Map ? data : {}),
    );
  }

  dynamic _unwrapData(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }
    if (data['success'] == true && data['data'] != null) {
      return data['data'];
    }
    final error = data['error'] as Map<String, dynamic>?;
    final message = error?['message'] as String? ?? 'Unknown error';
    throw DioException(
      requestOptions: response.requestOptions,
      type: DioExceptionType.badResponse,
      response: response,
      error: message,
    );
  }
}
