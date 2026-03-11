import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/item_model.dart';
import '../data/item_repository_provider.dart';

class ItemListNotifier extends AsyncNotifier<List<ItemModel>> {
  @override
  Future<List<ItemModel>> build() async => [];

  Future<void> load(String propertyId, String roomId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref
        .read(itemRepositoryProvider)
        .getItems(propertyId: propertyId, roomId: roomId));
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

final itemListNotifierProvider =
    AsyncNotifierProvider<ItemListNotifier, List<ItemModel>>(ItemListNotifier.new);
