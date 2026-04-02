import 'package:dio/dio.dart';

import 'dry_cleaning_model.dart';

class DryCleaningRepository {
  DryCleaningRepository(this._dio);

  final Dio _dio;

  Future<List<DryCleaningModel>> getHistory(String itemId) async {
    final Response<Map<String, dynamic>> response = await _dio.get<Map<String, dynamic>>(
      'wardrobe/dry-cleaning/$itemId',
    );
    final dynamic data = _unwrapData(response);
    if (data is! List) return <DryCleaningModel>[];

    return data
        .map(
          (dynamic e) => DryCleaningModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<void> markReturned(String recordId) async {
    await _dio.put<Map<String, dynamic>>('wardrobe/dry-cleaning/$recordId/return');
  }

  dynamic _unwrapData(Response<Map<String, dynamic>> response) {
    final Map<String, dynamic>? payload = response.data;
    if (payload == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }

    if (payload['success'] == true && payload['data'] != null) {
      return payload['data'];
    }

    final Map<String, dynamic>? error = payload['error'] as Map<String, dynamic>?;
    throw DioException(
      requestOptions: response.requestOptions,
      type: DioExceptionType.badResponse,
      response: response,
      error: error?['message'] ?? 'Unknown error',
    );
  }
}
