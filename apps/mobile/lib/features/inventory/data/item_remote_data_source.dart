import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import 'models/item_history_model.dart';
import 'models/item_model.dart';

/// Remote data source for inventory/items API.
class ItemRemoteDataSource {
  ItemRemoteDataSource(this._dio);

  final Dio _dio;

  static const String _path = 'items';

  /// GET /items?propertyId=&roomId=&category=&status=&unlocated=true&limit=N
  Future<List<ItemModel>> getItems({
    String? propertyId,
    String? roomId,
    String? category,
    String? status,
    bool unlocated = false,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{};
    if (propertyId != null && propertyId.isNotEmpty) queryParams['propertyId'] = propertyId;
    if (roomId != null && roomId.isNotEmpty) queryParams['roomId'] = roomId;
    if (category != null && category.isNotEmpty) queryParams['category'] = category;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (unlocated) queryParams['unlocated'] = 'true';
    if (limit != null && limit > 0) queryParams['limit'] = limit.toString();

    final response = await _dio.get<Map<String, dynamic>>(
      _path,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final list = _unwrapData(response);
    if (list is! List) return [];
    return list
        .map(
          (e) => ItemModel.fromJson(
            _normalizeItemJson(Map<String, dynamic>.from(e as Map<String, dynamic>)),
          ),
        )
        .toList();
  }

  /// GET /items/:id
  Future<ItemModel> getItem(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('$_path/$id');
    final data = _unwrapData(response);
    return ItemModel.fromJson(
      _normalizeItemJson(Map<String, dynamic>.from(data is Map ? data : {})),
    );
  }

  static Map<String, dynamic> _normalizeItemJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['_id'];
    if (id != null) json['id'] = id is String ? id : id.toString();

    final rawPhotos = json['photos'];
    if (rawPhotos is List) {
      final apiHost = Uri.tryParse(AppConfig.apiBaseUrl)?.host ?? '';
      json['photos'] = rawPhotos.whereType<String>().where((url) {
        if (url.startsWith('/')) return true;
        final uri = Uri.tryParse(url);
        return uri != null && uri.host == apiHost;
      }).toList();
    }

    return json;
  }

  /// POST /items
  Future<ItemModel> createItem(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(_path, data: body);
    final data = _unwrapData(response);
    final raw = Map<String, dynamic>.from(data is Map ? data : <String, dynamic>{});
    return ItemModel.fromJson(_normalizeItemJson(raw));
  }

  /// PUT /items/:id
  Future<ItemModel> updateItem(String id, Map<String, dynamic> body) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '$_path/$id',
      data: body,
    );
    final data = _unwrapData(response);
    final raw = Map<String, dynamic>.from(data is Map ? data : <String, dynamic>{});
    return ItemModel.fromJson(_normalizeItemJson(raw));
  }

  /// DELETE /items/:id
  Future<void> deleteItem(String id) async {
    await _dio.delete<Map<String, dynamic>>('$_path/$id');
  }

  /// GET /items/:id/history
  Future<List<ItemHistoryModel>> getItemHistory(String itemId) async {
    final response =
        await _dio.get<Map<String, dynamic>>('$_path/$itemId/history');
    final list = _unwrapData(response);
    if (list is! List) return [];
    return list
        .map(
          (e) => ItemHistoryModel.fromJson(
            Map<String, dynamic>.from(e as Map<String, dynamic>),
          ),
        )
        .toList();
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
