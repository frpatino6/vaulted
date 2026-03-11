import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/item_model.dart';
import '../data/item_repository_provider.dart';

class ItemDetailNotifier extends AsyncNotifier<ItemModel?> {
  @override
  Future<ItemModel?> build() async => null;

  Future<ItemModel?> load(String id) async {
    state = const AsyncLoading();
    try {
      final item = await ref.read(itemRepositoryProvider).getItem(id);
      state = AsyncData(item);
      return item;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
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

final itemDetailNotifierProvider =
    AsyncNotifierProvider<ItemDetailNotifier, ItemModel?>(ItemDetailNotifier.new);
