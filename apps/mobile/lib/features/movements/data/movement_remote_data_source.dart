import 'package:dio/dio.dart';

import 'models/movement_model.dart';

class MovementRemoteDataSource {
  MovementRemoteDataSource(this._dio);

  final Dio _dio;

  static const String _path = 'movements';

  Future<MovementModel> createMovement({
    required String operationType,
    required String title,
    String description = '',
    String destination = '',
    String? dueDate,
    String notes = '',
    String? propertyId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path,
      data: {
        'operationType': operationType,
        'title': title,
        if (description.isNotEmpty) 'description': description,
        if (destination.isNotEmpty) 'destination': destination,
        if (dueDate != null) 'dueDate': dueDate,
        if (notes.isNotEmpty) 'notes': notes,
        if (propertyId != null && propertyId.isNotEmpty)
          'propertyId': propertyId,
      },
    );
    return MovementModel.fromJson(_normalize(_unwrap(response)));
  }

  Future<List<MovementModel>> getMovements({String? status}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _path,
      queryParameters: status != null ? {'status': status} : null,
    );
    final list = _unwrap(response);
    if (list is! List) return [];
    return list
        .map(
          (e) => MovementModel.fromJson(
            _normalize(Map<String, dynamic>.from(e as Map)),
          ),
        )
        .toList();
  }

  Future<MovementModel?> getActiveDraft() async {
    final response =
        await _dio.get<Map<String, dynamic>>('$_path/draft');
    final data = _unwrap(response);
    if (data == null) return null;
    return MovementModel.fromJson(_normalize(Map<String, dynamic>.from(data as Map)));
  }

  Future<MovementModel> getMovement(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('$_path/$id');
    return MovementModel.fromJson(_normalize(_unwrap(response)));
  }

  Future<MovementModel> addItem(String movementId, String itemId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_path/$movementId/items',
      data: {'itemId': itemId},
    );
    return MovementModel.fromJson(_normalize(_unwrap(response)));
  }

  Future<MovementModel> removeItem(
      String movementId, String itemId) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '$_path/$movementId/items/$itemId',
    );
    return MovementModel.fromJson(_normalize(_unwrap(response)));
  }

  Future<MovementModel> activate(String movementId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_path/$movementId/activate',
    );
    return MovementModel.fromJson(_normalize(_unwrap(response)));
  }

  Future<MovementModel> checkinItem(
      String movementId, String itemId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_path/$movementId/checkin',
      data: {'itemId': itemId},
    );
    return MovementModel.fromJson(_normalize(_unwrap(response)));
  }

  Future<MovementModel> complete(String movementId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_path/$movementId/complete',
    );
    return MovementModel.fromJson(_normalize(_unwrap(response)));
  }

  Future<MovementModel> cancel(String movementId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_path/$movementId/cancel',
    );
    return MovementModel.fromJson(_normalize(_unwrap(response)));
  }

  // -------------------------------------------------------------------------

  dynamic _unwrap(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }
    if (data['success'] == true) return data['data'];
    final error = data['error'] as Map<String, dynamic>?;
    final message = error?['message'] as String? ?? 'Unknown error';
    throw DioException(
      requestOptions: response.requestOptions,
      type: DioExceptionType.badResponse,
      response: response,
      error: message,
    );
  }

  Map<String, dynamic> _normalize(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    final id = json['id'] ?? json['_id'];
    if (id != null) json['id'] = id is String ? id : id.toString();
    // Normalize nested items
    if (json['items'] is List) {
      json['items'] = (json['items'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return json;
  }
}
