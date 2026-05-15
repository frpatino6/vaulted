import 'models/orchestrator_plan_model.dart';
import 'orchestrator_remote_data_source.dart';

class OrchestratorRepository {
  OrchestratorRepository(this._remote);

  final OrchestratorRemoteDataSource _remote;

  Future<ParsedPlanModel> parseCommand({
    required String command,
    String? propertyId,
    String? targetDate,
  }) =>
      _remote.parseCommand(
        command: command,
        propertyId: propertyId,
        targetDate: targetDate,
      );

  Future<OrchestratorPlanModel> createPlan(Map<String, dynamic> body) =>
      _remote.createPlan(body);

  Future<List<OrchestratorPlanModel>> getPlans({
    String? status,
    String? propertyId,
    int page = 1,
    int limit = 20,
  }) =>
      _remote.getPlans(
        status: status,
        propertyId: propertyId,
        page: page,
        limit: limit,
      );

  Future<OrchestratorPlanModel> getPlan(String planId) =>
      _remote.getPlan(planId);

  Future<OrchestratorPlanModel> updatePlan(
    String planId,
    Map<String, dynamic> body,
  ) =>
      _remote.updatePlan(planId, body);

  Future<OrchestratorPlanModel> publishPlan(String planId) =>
      _remote.publishPlan(planId);

  Future<OrchestratorPlanModel> completeStep({
    required String planId,
    required String groupId,
    required String stepId,
    String? note,
    String? completionPhotoUrl,
  }) =>
      _remote.completeStep(
        planId: planId,
        groupId: groupId,
        stepId: stepId,
        note: note,
        completionPhotoUrl: completionPhotoUrl,
      );

  Future<PlanProgressModel> getProgress(String planId) =>
      _remote.getProgress(planId);

  Future<List<OrchestratorPlanModel>> getMyTasks() => _remote.getMyTasks();
}
