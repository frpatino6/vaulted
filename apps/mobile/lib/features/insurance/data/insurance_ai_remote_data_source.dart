import 'package:dio/dio.dart';

import 'models/insurance_ai_model.dart';

/// Remote data source for AI-powered insurance endpoints.
class InsuranceAiRemoteDataSource {
  InsuranceAiRemoteDataSource(this._dio);

  final Dio _dio;

  /// POST /ai/insurance/policies/:policyId/analyze
  Future<CoverageAnalysisModel> analyzeCoverage(String policyId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'ai/insurance/policies/$policyId/analyze',
    );
    final data = _unwrapData(response);
    return CoverageAnalysisModel.fromJson(
      Map<String, dynamic>.from(data is Map ? data : {}),
    );
  }

  /// POST /ai/insurance/claim-draft
  Future<ClaimDraftModel> draftClaim({
    required String policyId,
    String? itemId,
    required String incidentDescription,
  }) async {
    final body = <String, dynamic>{
      'policyId': policyId,
      'incidentDescription': incidentDescription,
      if (itemId != null) 'itemId': itemId,
    };

    final response = await _dio.post<Map<String, dynamic>>(
      'ai/insurance/claim-draft',
      data: body,
    );
    final data = _unwrapData(response);
    return ClaimDraftModel.fromJson(
      Map<String, dynamic>.from(data is Map ? data : {}),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  dynamic _unwrapData(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }
    if (data['success'] == true && data.containsKey('data')) {
      return data['data'];
    }
    if (data['success'] == true) {
      return null;
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
