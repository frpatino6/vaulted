import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/movement_model.dart';
import '../data/movement_repository_provider.dart';

class MovementDetailNotifier
    extends AutoDisposeAsyncNotifier<MovementModel?> {
  String? _id;

  @override
  Future<MovementModel?> build() async => null;

  Future<void> load(String id) async {
    _id = id;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(movementRepositoryProvider).getMovement(id),
    );
  }

  Future<void> checkin(String itemId) async {
    final id = _id;
    if (id == null) return;
    final movement =
        await ref.read(movementRepositoryProvider).checkinItem(id, itemId);
    state = AsyncData(movement);
  }

  Future<void> complete() async {
    final id = _id;
    if (id == null) return;
    final movement =
        await ref.read(movementRepositoryProvider).complete(id);
    state = AsyncData(movement);
  }

  Future<void> cancel() async {
    final id = _id;
    if (id == null) return;
    await ref.read(movementRepositoryProvider).cancel(id);
    state = const AsyncData(null);
  }

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

final movementDetailNotifierProvider =
    AutoDisposeAsyncNotifierProvider<MovementDetailNotifier, MovementModel?>(
  MovementDetailNotifier.new,
);
