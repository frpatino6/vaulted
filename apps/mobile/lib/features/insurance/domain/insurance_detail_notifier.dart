import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/insurance_policy_model.dart';
import '../data/insurance_repository_provider.dart';

class InsuranceDetailNotifier
    extends AsyncNotifier<InsurancePolicyModel?> {
  @override
  Future<InsurancePolicyModel?> build() async => null;

  Future<void> load(String id) async {
    state = const AsyncLoading();
    try {
      final policy =
          await ref.read(insuranceRepositoryProvider).getPolicy(id);
      state = AsyncData(policy);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> attachItem(
    String policyId, {
    required String itemId,
    required double coveredValue,
    String currency = 'USD',
  }) async {
    final updated = await ref.read(insuranceRepositoryProvider).attachItem(
          policyId,
          itemId: itemId,
          coveredValue: coveredValue,
          currency: currency,
        );
    state = AsyncData(updated);
  }

  Future<void> detachItem(String policyId, String itemId) async {
    final updated = await ref
        .read(insuranceRepositoryProvider)
        .detachItem(policyId, itemId);
    state = AsyncData(updated);
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

final insuranceDetailNotifierProvider =
    AsyncNotifierProvider<InsuranceDetailNotifier, InsurancePolicyModel?>(
  InsuranceDetailNotifier.new,
);
