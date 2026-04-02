import 'package:dio/dio.dart';

import 'outfit_model.dart';

class OutfitRepository {
  OutfitRepository(this._dio);

  final Dio _dio;
  static const String _path = 'wardrobe/outfits';

  Future<List<OutfitModel>> getOutfits() async {
    final Response<Map<String, dynamic>> response = await _dio.get<Map<String, dynamic>>(_path);
    final dynamic data = _unwrapData(response);
    if (data is! List) return <OutfitModel>[];
    return data
        .map((dynamic e) => OutfitModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<OutfitModel> createOutfit(Map<String, dynamic> payload) async {
    final Response<Map<String, dynamic>> response = await _dio.post<Map<String, dynamic>>(_path, data: payload);
    final dynamic data = _unwrapData(response);
    final Map<String, dynamic> raw = Map<String, dynamic>.from(data as Map);
    return OutfitModel.fromJson(raw);
  }

  Future<OutfitModel> getOutfitById(String id) async {
    final Response<Map<String, dynamic>> response = await _dio.get<Map<String, dynamic>>('$_path/$id');
    final dynamic data = _unwrapData(response);
    final Map<String, dynamic> raw = Map<String, dynamic>.from(data as Map);
    return OutfitModel.fromJson(raw);
  }

  Future<void> deleteOutfit(String id) async {
    await _dio.delete<Map<String, dynamic>>('$_path/$id');
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
