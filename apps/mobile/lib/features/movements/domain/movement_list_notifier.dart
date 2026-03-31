import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/movement_model.dart';
import '../data/movement_repository_provider.dart';

class MovementListNotifier extends AsyncNotifier<List<MovementModel>> {
  @override
  Future<List<MovementModel>> build() async => [];

  Future<void> load({String? status}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(movementRepositoryProvider).getMovements(status: status),
    );
  }

  Future<void> loadActive() => load(status: 'draft,active');

  Future<void> refresh() => load();

  static String message(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['error']?['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
      if (e.error is String) return e.error as String;
    }
    return 'Something went wrong. Please try again.';
  }
}

final movementListNotifierProvider =
    AsyncNotifierProvider<MovementListNotifier, List<MovementModel>>(
  MovementListNotifier.new,
);
