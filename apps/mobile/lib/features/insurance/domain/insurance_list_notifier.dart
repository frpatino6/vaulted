import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/insurance_policy_model.dart';
import '../data/insurance_repository_provider.dart';

class InsuranceListNotifier
    extends AsyncNotifier<List<InsurancePolicyModel>> {
  @override
  Future<List<InsurancePolicyModel>> build() async => [];

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(insuranceRepositoryProvider).getPolicies(),
    );
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(insuranceRepositoryProvider).getPolicies(),
    );
  }

  Future<void> deletePolicy(String id) async {
    await ref.read(insuranceRepositoryProvider).deletePolicy(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((p) => p.id != id).toList());
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

final insuranceListNotifierProvider =
    AsyncNotifierProvider<InsuranceListNotifier, List<InsurancePolicyModel>>(
  InsuranceListNotifier.new,
);
