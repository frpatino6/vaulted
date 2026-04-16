import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/insurance_ai_model.dart';
import '../data/insurance_ai_remote_data_source_provider.dart';

// ─── Coverage Analysis ────────────────────────────────────────────────────────

class CoverageAnalysisNotifier
    extends AsyncNotifier<CoverageAnalysisModel?> {
  @override
  Future<CoverageAnalysisModel?> build() async => null;

  Future<void> load(String policyId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(insuranceAiRemoteDataSourceProvider)
          .analyzeCoverage(policyId),
    );
  }

  static String message(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['error']?['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
      if (e.response?.statusCode == 429) {
        return 'AI rate limit reached. Please try again in an hour.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}

final coverageAnalysisNotifierProvider =
    AsyncNotifierProvider<CoverageAnalysisNotifier, CoverageAnalysisModel?>(
  CoverageAnalysisNotifier.new,
);

// ─── Claim Draft ──────────────────────────────────────────────────────────────

class ClaimDraftNotifier extends AsyncNotifier<ClaimDraftModel?> {
  @override
  Future<ClaimDraftModel?> build() async => null;

  Future<void> draft(
    String policyId,
    String? itemId,
    String incidentDescription,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(insuranceAiRemoteDataSourceProvider).draftClaim(
            policyId: policyId,
            itemId: itemId,
            incidentDescription: incidentDescription,
          ),
    );
  }

  static String message(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['error']?['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
      if (e.response?.statusCode == 429) {
        return 'AI rate limit reached. Please try again in an hour.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}

final claimDraftNotifierProvider =
    AsyncNotifierProvider<ClaimDraftNotifier, ClaimDraftModel?>(
  ClaimDraftNotifier.new,
);
