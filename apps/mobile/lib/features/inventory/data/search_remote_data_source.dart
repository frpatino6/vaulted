import 'package:dio/dio.dart';

import 'models/item_model.dart';

class SearchRemoteDataSource {
  SearchRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ItemModel>> search({
    String? query,
    String? category,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      if (category != null && category.isNotEmpty) 'category': category,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final response = await _dio.get<Map<String, dynamic>>(
      'items/search',
      queryParameters: queryParameters,
    );

    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }

    if (data['success'] != true) {
      final error = data['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String? ?? 'Unknown error';
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
        error: message,
      );
    }

    final body = data['data'];
    if (body is! Map<String, dynamic>) return [];

    final items = body['items'];
    if (items is! List) return [];

    return items
        .whereType<Map>()
        .map(
          (item) => ItemModel.fromJson(
            _normalizeItemJson(Map<String, dynamic>.from(item)),
          ),
        )
        .toList();
  }

  Map<String, dynamic> _normalizeItemJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['_id'];
    if (id != null) {
      json['id'] = id is String ? id : id.toString();
    }

    final propertyId = json['propertyId'];
    if (propertyId != null) {
      json['propertyId'] = propertyId is String
          ? propertyId
          : propertyId.toString();
    }

    final roomId = json['roomId'];
    if (roomId != null) {
      json['roomId'] = roomId is String ? roomId : roomId.toString();
    }

    return json;
  }
}
