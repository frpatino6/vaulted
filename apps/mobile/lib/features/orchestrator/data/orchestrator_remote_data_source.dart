import 'package:dio/dio.dart';

import 'models/orchestrator_plan_model.dart';

class OrchestratorRemoteDataSource {
  OrchestratorRemoteDataSource(this._dio);

  final Dio _dio;

  // ---------------------------------------------------------------------------
  // POST /orchestrator/parse
  // ---------------------------------------------------------------------------

  Future<ParsedPlanModel> parseCommand({
    required String command,
    String? propertyId,
    String? targetDate,
  }) async {
    final body = <String, dynamic>{
      'command': command,
      if (propertyId != null && propertyId.isNotEmpty) 'propertyId': propertyId,
      if (targetDate != null && targetDate.isNotEmpty) 'targetDate': targetDate,
    };
    final response = await _dio.post<Map<String, dynamic>>(
      'orchestrator/parse',
      data: body,
    );
    final data = _unwrapData(response);
    return ParsedPlanModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // ---------------------------------------------------------------------------
  // POST /orchestrator/plans
  // ---------------------------------------------------------------------------

  Future<OrchestratorPlanModel> createPlan(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'orchestrator/plans',
      data: body,
    );
    final data = _unwrapData(response);
    return OrchestratorPlanModel.fromJson(
        _normalize(Map<String, dynamic>.from(data as Map)));
  }

  // ---------------------------------------------------------------------------
  // GET /orchestrator/plans
  // ---------------------------------------------------------------------------

  Future<List<OrchestratorPlanModel>> getPlans({
    String? status,
    String? propertyId,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
      if (propertyId != null && propertyId.isNotEmpty) 'propertyId': propertyId,
    };
    final response = await _dio.get<Map<String, dynamic>>(
      'orchestrator/plans',
      queryParameters: params,
    );
    final data = _unwrapData(response);
    // Backend returns { items: [...], total: number }
    final raw = data is Map ? (data['items'] ?? data) : data;
    if (raw is! List) return [];
    return raw
        .map((e) => OrchestratorPlanModel.fromJson(
            _normalize(Map<String, dynamic>.from(e as Map))))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // GET /orchestrator/plans/:id
  // ---------------------------------------------------------------------------

  Future<OrchestratorPlanModel> getPlan(String planId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'orchestrator/plans/$planId',
    );
    final data = _unwrapData(response);
    return OrchestratorPlanModel.fromJson(
        _normalize(Map<String, dynamic>.from(data as Map)));
  }

  // ---------------------------------------------------------------------------
  // PATCH /orchestrator/plans/:id
  // ---------------------------------------------------------------------------

  Future<OrchestratorPlanModel> updatePlan(
    String planId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      'orchestrator/plans/$planId',
      data: body,
    );
    final data = _unwrapData(response);
    return OrchestratorPlanModel.fromJson(
        _normalize(Map<String, dynamic>.from(data as Map)));
  }

  // ---------------------------------------------------------------------------
  // POST /orchestrator/plans/:id/publish
  // ---------------------------------------------------------------------------

  Future<OrchestratorPlanModel> publishPlan(String planId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'orchestrator/plans/$planId/publish',
    );
    final data = _unwrapData(response);
    return OrchestratorPlanModel.fromJson(
        _normalize(Map<String, dynamic>.from(data as Map)));
  }

  // ---------------------------------------------------------------------------
  // PATCH /orchestrator/plans/:planId/groups/:groupId/steps/:stepId/complete
  // ---------------------------------------------------------------------------

  Future<OrchestratorPlanModel> completeStep({
    required String planId,
    required String groupId,
    required String stepId,
    String? note,
    String? completionPhotoUrl,
  }) async {
    final body = <String, dynamic>{
      if (note != null && note.isNotEmpty) 'note': note,
      if (completionPhotoUrl != null && completionPhotoUrl.isNotEmpty)
        'completionPhotoUrl': completionPhotoUrl,
    };
    final response = await _dio.patch<Map<String, dynamic>>(
      'orchestrator/plans/$planId/groups/$groupId/steps/$stepId/complete',
      data: body,
    );
    final data = _unwrapData(response);
    return OrchestratorPlanModel.fromJson(
        _normalize(Map<String, dynamic>.from(data as Map)));
  }

  // ---------------------------------------------------------------------------
  // GET /orchestrator/plans/:id/progress
  // ---------------------------------------------------------------------------

  Future<PlanProgressModel> getProgress(String planId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'orchestrator/plans/$planId/progress',
    );
    final data = _unwrapData(response);
    return PlanProgressModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // ---------------------------------------------------------------------------
  // GET /orchestrator/plans/my-tasks
  // ---------------------------------------------------------------------------

  Future<List<OrchestratorPlanModel>> getMyTasks() async {
    final response = await _dio.get<Map<String, dynamic>>(
      'orchestrator/plans/my-tasks',
    );
    final data = _unwrapData(response);
    if (data is! List) return [];
    return data
        .map((e) => OrchestratorPlanModel.fromJson(
            _normalize(Map<String, dynamic>.from(e as Map))))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _normalize(Map<String, dynamic> json) {
    // MongoDB returns _id; map to id if not already present
    final id = json['id'] ?? json['_id'];
    if (id != null) json['id'] = id is String ? id : id.toString();
    return json;
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
    if (data['success'] == true && data['data'] != null) return data['data'];
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
