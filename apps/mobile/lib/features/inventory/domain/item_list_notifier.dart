import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/item_model.dart';
import '../data/item_repository_provider.dart';

class ItemListNotifier extends AsyncNotifier<List<ItemModel>> {
  String? _propertyId;
  String? _roomId;

  @override
  Future<List<ItemModel>> build() async => [];

  Future<void> load(String propertyId, String roomId) async {
    _propertyId = propertyId;
    _roomId = roomId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref
        .read(itemRepositoryProvider)
        .getItems(propertyId: propertyId, roomId: roomId));
  }

  Future<void> refresh() async {
    final propertyId = _propertyId;
    final roomId = _roomId;
    if (propertyId == null || roomId == null) return;

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
