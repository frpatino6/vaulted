import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/orchestrator_plan_model.dart';
import '../data/orchestrator_repository_provider.dart';

class OrchestratorParseNotifier extends AsyncNotifier<ParsedPlanModel?> {
  @override
  Future<ParsedPlanModel?> build() async => null;

  /// Sends the NL command to POST /orchestrator/parse and returns the parsed
  /// plan. Stores the result in state so the UI can react. Returns null on
  /// error (state is set to AsyncError in that case).
  Future<ParsedPlanModel?> parse({
    required String command,
    String? propertyId,
    String? targetDate,
  }) async {
    state = const AsyncLoading();
    try {
      final parsed =
          await ref.read(orchestratorRepositoryProvider).parseCommand(
                command: command,
                propertyId: propertyId,
                targetDate: targetDate,
              );
      state = AsyncData(parsed);
      return parsed;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }

  /// Resets state back to null so the user can start a new command.
  Future<void> reset() async {
    state = const AsyncData(null);
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

final orchestratorParseNotifierProvider =
    AsyncNotifierProvider<OrchestratorParseNotifier, ParsedPlanModel?>(
  OrchestratorParseNotifier.new,
);
