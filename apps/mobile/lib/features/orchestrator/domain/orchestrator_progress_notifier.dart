import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/orchestrator_plan_model.dart';
import '../data/orchestrator_repository_provider.dart';

class OrchestratorProgressNotifier
    extends AsyncNotifier<PlanProgressModel?> {
  @override
  Future<PlanProgressModel?> build() async => null;

  Future<void> load(String planId) async {
    state = const AsyncLoading();
    try {
      final progress =
          await ref.read(orchestratorRepositoryProvider).getProgress(planId);
      state = AsyncData(progress);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> refresh(String planId) => load(planId);

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

final orchestratorProgressNotifierProvider =
    AsyncNotifierProvider<OrchestratorProgressNotifier, PlanProgressModel?>(
  OrchestratorProgressNotifier.new,
);
