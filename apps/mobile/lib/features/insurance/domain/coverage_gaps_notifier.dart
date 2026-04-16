import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/insurance_policy_model.dart';
import '../data/insurance_repository_provider.dart';

class CoverageGapsNotifier
    extends AsyncNotifier<CoverageGapReportModel?> {
  @override
  Future<CoverageGapReportModel?> build() async => null;

  Future<void> load(String policyId) async {
    state = const AsyncLoading();
    try {
      final report =
          await ref.read(insuranceRepositoryProvider).getCoverageGaps(policyId);
      state = AsyncData(report);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  static String message(Object e) {
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

final coverageGapsNotifierProvider =
    AsyncNotifierProvider<CoverageGapsNotifier, CoverageGapReportModel?>(
  CoverageGapsNotifier.new,
);
