import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/orchestrator_plan_model.dart';
import '../data/orchestrator_repository_provider.dart';

class OrchestratorDetailNotifier
    extends AsyncNotifier<OrchestratorPlanModel?> {
  String? _planId;

  @override
  Future<OrchestratorPlanModel?> build() async => null;

  Future<void> load(String planId) async {
    _planId = planId;
    state = const AsyncLoading();
    try {
      final plan =
          await ref.read(orchestratorRepositoryProvider).getPlan(planId);
      state = AsyncData(plan);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> publish() async {
    final planId = _planId;
    if (planId == null) return;
    try {
      final updated =
          await ref.read(orchestratorRepositoryProvider).publishPlan(planId);
      state = AsyncData(updated);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> cancel() async {
    final planId = _planId;
    if (planId == null) return;
    try {
      final updated = await ref
          .read(orchestratorRepositoryProvider)
          .updatePlan(planId, {'status': 'cancelled'});
      state = AsyncData(updated);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> completeStep({
    required String groupId,
    required String stepId,
    String? note,
    String? completionPhotoUrl,
  }) async {
    final planId = _planId;
    if (planId == null) return;
    try {
      final updated =
          await ref.read(orchestratorRepositoryProvider).completeStep(
                planId: planId,
                groupId: groupId,
                stepId: stepId,
                note: note,
                completionPhotoUrl: completionPhotoUrl,
              );
      state = AsyncData(updated);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> updateAssignments(
      List<Map<String, dynamic>> taskGroups) async {
    final planId = _planId;
    if (planId == null) return;
    try {
      final updated = await ref
          .read(orchestratorRepositoryProvider)
          .updatePlan(planId, {'taskGroups': taskGroups});
      state = AsyncData(updated);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  static String errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['error']?['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    }
    return 'Something went wrong. Please try again.';
  }
}

final orchestratorDetailNotifierProvider =
    AsyncNotifierProvider<OrchestratorDetailNotifier, OrchestratorPlanModel?>(
  OrchestratorDetailNotifier.new,
);
