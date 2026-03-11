import 'package:dio/dio.dart';

import 'models/property_model.dart';

/// Remote data source for properties API.
/// Uses shared Dio instance; auth interceptor attaches Bearer token.
class PropertyRemoteDataSource {
  PropertyRemoteDataSource(this._dio);

  final Dio _dio;

  static const String _path = 'properties';

  /// GET /properties
  Future<List<PropertyModel>> getProperties() async {
    final response = await _dio.get<Map<String, dynamic>>(_path);
    final list = _unwrapData(response);
    if (list is! List) return [];
    return list
        .map(
          (e) => PropertyModel.fromJson(
            Map<String, dynamic>.from(e as Map<String, dynamic>),
          ),
        )
        .toList();
  }

  /// POST /properties
  Future<PropertyModel> createProperty(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(_path, data: body);
    final data = _unwrapData(response);
    return PropertyModel.fromJson(
      Map<String, dynamic>.from(data is Map ? data : {}),
    );
  }

  /// GET /properties/:id
  Future<PropertyModel> getProperty(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('$_path/$id');
    final data = _unwrapData(response);
    return PropertyModel.fromJson(
      Map<String, dynamic>.from(data is Map ? data : {}),
    );
  }

  /// PUT /properties/:id
  Future<PropertyModel> updateProperty(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_path/$id',
      data: body,
    );
    final data = _unwrapData(response);
    return PropertyModel.fromJson(
      Map<String, dynamic>.from(data is Map ? data : {}),
    );
  }

  /// DELETE /properties/:id
  Future<void> deleteProperty(String id) async {
    await _dio.delete<Map<String, dynamic>>('$_path/$id');
  }

  /// POST /properties/:id/floors
  Future<PropertyModel> addFloor(String propertyId, String name) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_path/$propertyId/floors',
      data: {'name': name},
    );
    final data = _unwrapData(response);
    return PropertyModel.fromJson(
      Map<String, dynamic>.from(data is Map ? data : {}),
    );
  }

  /// POST /properties/:id/floors/:floorId/rooms
  Future<PropertyModel> addRoom(
    String propertyId,
    String floorId,
    String name,
    String type,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_path/$propertyId/floors/$floorId/rooms',
      data: {'name': name, 'type': type},
    );
    final data = _unwrapData(response);
    return PropertyModel.fromJson(
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
