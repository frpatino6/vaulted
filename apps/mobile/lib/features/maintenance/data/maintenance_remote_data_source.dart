import 'package:dio/dio.dart';

import 'models/maintenance_model.dart';

class MaintenanceRemoteDataSource {
  MaintenanceRemoteDataSource(this._dio);

  final Dio _dio;

  /// GET /maintenance?status=&itemId=&upcoming=true&daysAhead=30
  Future<List<MaintenanceModel>> getAll({
    String? status,
    String? itemId,
    bool upcoming = false,
    int? daysAhead,
  }) async {
    final params = <String, dynamic>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (itemId != null && itemId.isNotEmpty) params['itemId'] = itemId;
    if (upcoming) {
      params['upcoming'] = 'true';
      if (daysAhead != null) params['daysAhead'] = daysAhead.toString();
    }

    final response = await _dio.get<Map<String, dynamic>>(
      'maintenance',
      queryParameters: params.isEmpty ? null : params,
    );
    final list = _unwrapData(response);
    if (list is! List) return [];
    return list
        .map((e) => MaintenanceModel.fromJson(_normalize(Map<String, dynamic>.from(e as Map))))
        .toList();
  }

  /// GET /items/:itemId/maintenance
  Future<List<MaintenanceModel>> getByItem(String itemId) async {
    final response =
        await _dio.get<Map<String, dynamic>>('items/$itemId/maintenance');
    final list = _unwrapData(response);
    if (list is! List) return [];
    return list
        .map((e) => MaintenanceModel.fromJson(_normalize(Map<String, dynamic>.from(e as Map))))
        .toList();
  }

  /// POST /items/:itemId/maintenance
  Future<MaintenanceModel> create(
    String itemId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'items/$itemId/maintenance',
      data: body,
    );
    final data = _unwrapData(response);
    return MaintenanceModel.fromJson(_normalize(Map<String, dynamic>.from(data as Map)));
  }

  /// PUT /maintenance/:id
  Future<MaintenanceModel> update(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response =
        await _dio.put<Map<String, dynamic>>('maintenance/$id', data: body);
    final data = _unwrapData(response);
    return MaintenanceModel.fromJson(_normalize(Map<String, dynamic>.from(data as Map)));
  }

  /// DELETE /maintenance/:id
  Future<void> delete(String id) async {
    await _dio.delete<void>('maintenance/$id');
  }

  /// POST /ai/maintenance/analyze/:itemId
  Future<Map<String, dynamic>> analyzeWithAi(String itemId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'ai/maintenance/analyze/$itemId',
    );
    final data = _unwrapData(response);
    return Map<String, dynamic>.from(data as Map);
  }

  static Map<String, dynamic> _normalize(Map<String, dynamic> json) {
    final id = json['id'] ?? json['_id'];
    if (id != null) json['id'] = id is String ? id : id.toString();
    return json;
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
    if (data['success'] == true && data['data'] != null) return data['data'];
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
