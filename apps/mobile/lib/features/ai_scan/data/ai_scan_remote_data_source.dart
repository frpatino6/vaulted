import 'package:dio/dio.dart';

import 'models/ai_scan_result_model.dart';

class AiScanRemoteDataSource {
  AiScanRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AiScanResult> analyzeItem({
    required String productImageUrl,
    String? invoiceImageUrl,
    required List<Map<String, String>> propertyRooms,
  }) async {
    final body = <String, dynamic>{
      'productImageUrl': productImageUrl,
      if (invoiceImageUrl != null) 'invoiceImageUrl': invoiceImageUrl,
      if (propertyRooms.isNotEmpty) 'propertyRooms': propertyRooms,
    };

    final response = await _dio.post<Map<String, dynamic>>(
      'ai/vision/analyze',
      data: body,
    );

    final data = response.data;
    if (data == null || data['success'] != true) {
      final error = data?['error'] as Map<String, dynamic>?;
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
        error: error?['message'] ?? 'AI vision analysis failed',
      );
    }

    final payload = data['data'] as Map<String, dynamic>? ?? {};
    return AiScanResult.fromJson(payload);
  }
}
