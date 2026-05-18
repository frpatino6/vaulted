import 'package:dio/dio.dart';

class NotificationRemoteDatasource {
  NotificationRemoteDatasource(this._dio);

  final Dio _dio;

  static const _base = 'notifications';

  Future<void> registerDeviceToken(String token, String platform) async {
    await _dio.post<void>(
      '$_base/device-token',
      data: {'token': token, 'platform': platform},
    );
  }

  Future<void> unregisterDeviceToken(String token) async {
    await _dio.delete<void>('$_base/device-token/$token');
  }

  Future<Map<String, dynamic>> getPreferences() async {
    final response =
        await _dio.get<Map<String, dynamic>>('$_base/preferences');
    return _unwrap(response);
  }

  Future<Map<String, dynamic>> updatePreferences(
    Map<String, dynamic> updates,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_base/preferences',
      data: updates,
    );
    return _unwrap(response);
  }

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base',
      queryParameters: {'page': page, 'limit': limit},
    );
    return _unwrap(response);
  }

  Future<void> markRead(String notificationId) async {
    await _dio.patch<void>('$_base/$notificationId/read');
  }

  Future<Map<String, dynamic>> markAllRead() async {
    final response =
        await _dio.post<Map<String, dynamic>>('$_base/mark-all-read');
    return _unwrap(response);
  }

  Map<String, dynamic> _unwrap(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }
    if (data['success'] == true && data['data'] != null) {
      return data['data'] as Map<String, dynamic>;
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
