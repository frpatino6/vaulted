import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/orchestrator_plan_model.dart';
import '../data/orchestrator_repository_provider.dart';

class OrchestratorListNotifier
    extends AsyncNotifier<List<OrchestratorPlanModel>> {
  String? _lastStatus;
  String? _lastPropertyId;

  @override
  Future<List<OrchestratorPlanModel>> build() async => [];

  Future<void> load({String? status, String? propertyId}) async {
    _lastStatus = status;
    _lastPropertyId = propertyId;
    state = const AsyncLoading();
    try {
      final plans = await ref.read(orchestratorRepositoryProvider).getPlans(
            status: status,
            propertyId: propertyId,
          );
      state = AsyncData(plans);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> refresh() => load(
        status: _lastStatus,
        propertyId: _lastPropertyId,
      );

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

final orchestratorListNotifierProvider =
    AsyncNotifierProvider<OrchestratorListNotifier, List<OrchestratorPlanModel>>(
  OrchestratorListNotifier.new,
);
