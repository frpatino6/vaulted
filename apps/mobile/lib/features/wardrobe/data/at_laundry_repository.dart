import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'at_laundry_model.dart';

final atLaundryRepositoryProvider = Provider<AtLaundryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AtLaundryRepository(apiClient.dio);
});

class AtLaundryRepository {
  AtLaundryRepository(this._dio);

  final Dio _dio;

  Future<AtLaundryData> getAtLaundry() async {
    final Response<Map<String, dynamic>> response =
        await _dio.get<Map<String, dynamic>>('wardrobe/at-laundry');
    final dynamic data = _unwrapData(response);
    return AtLaundryData.fromJson(Map<String, dynamic>.from(data as Map));
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

    final Map<String, dynamic>? error =
        payload['error'] as Map<String, dynamic>?;
    throw DioException(
      requestOptions: response.requestOptions,
      type: DioExceptionType.badResponse,
      response: response,
      error: error?['message'] ?? 'Unknown error',
    );
  }
}
