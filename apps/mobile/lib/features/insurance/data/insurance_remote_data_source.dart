import 'package:dio/dio.dart';

import 'models/insurance_policy_model.dart';

/// Remote data source for the Insurance API.
class InsuranceRemoteDataSource {
  InsuranceRemoteDataSource(this._dio);

  final Dio _dio;

  static const String _path = 'insurance';

  // ─── Policies ─────────────────────────────────────────────────────────────

  /// GET /insurance
  Future<List<InsurancePolicyModel>> getPolicies() async {
    final response = await _dio.get<Map<String, dynamic>>(_path);
    final list = _unwrapData(response);
    if (list is! List) return [];
    return list
        .map((e) => InsurancePolicyModel.fromJson(
              Map<String, dynamic>.from(e as Map<String, dynamic>),
            ))
        .toList();
  }

  /// GET /insurance/:id
  Future<InsurancePolicyModel> getPolicy(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('$_path/$id');
    final data = _unwrapData(response);
    return InsurancePolicyModel.fromJson(
      Map<String, dynamic>.from(data is Map ? data : {}),
    );
  }

  /// POST /insurance
  Future<InsurancePolicyModel> createPolicy(Map<String, dynamic> body) async {
    final response =
        await _dio.post<Map<String, dynamic>>(_path, data: body);
    final data = _unwrapData(response);
    return InsurancePolicyModel.fromJson(
      Map<String, dynamic>.from(data is Map ? data : {}),
    );
  }

  /// PATCH /insurance/:id
  Future<InsurancePolicyModel> updatePolicy(
      String id, Map<String, dynamic> body) async {
    final response =
        await _dio.patch<Map<String, dynamic>>('$_path/$id', data: body);
    final data = _unwrapData(response);
    return InsurancePolicyModel.fromJson(
      Map<String, dynamic>.from(data is Map ? data : {}),
    );
  }

  /// DELETE /insurance/:id  →  {success: true}  (no data key)
  Future<void> deletePolicy(String id) async {
    await _dio.delete<Map<String, dynamic>>('$_path/$id');
  }

  // ─── Insured Items ─────────────────────────────────────────────────────────

  /// POST /insurance/:id/items
  Future<InsurancePolicyModel> attachItem(
      String policyId, Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_path/$policyId/items',
      data: body,
    );
    final data = _unwrapData(response);
    return InsurancePolicyModel.fromJson(
      Map<String, dynamic>.from(data is Map ? data : {}),
    );
  }

  /// DELETE /insurance/:id/items/:itemId
  Future<InsurancePolicyModel> detachItem(
      String policyId, String itemId) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '$_path/$policyId/items/$itemId',
    );
    final data = _unwrapData(response);
    return InsurancePolicyModel.fromJson(
      Map<String, dynamic>.from(data is Map ? data : {}),
    );
  }

  // ─── Coverage Gaps ─────────────────────────────────────────────────────────

  /// GET /insurance/:id/coverage-gaps
  Future<CoverageGapReportModel> getCoverageGaps(String policyId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_path/$policyId/coverage-gaps',
    );
    final data = _unwrapData(response);
    return CoverageGapReportModel.fromJson(
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
    // DELETE policy returns {success: true} with no data key — that's fine.
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
