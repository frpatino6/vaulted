import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/item_model.dart';
import '../data/search_repository_provider.dart';

class SearchNotifier extends AsyncNotifier<List<ItemModel>> {
  int _searchVersion = 0;

  @override
  Future<List<ItemModel>> build() async => [];

  Future<void> search(
    String query, {
    String? category,
    String? status,
  }) async {
    final normalizedQuery = query.trim();
    final currentVersion = ++_searchVersion;

    if (normalizedQuery.isEmpty) {
      state = const AsyncData([]);
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (currentVersion != _searchVersion) return;

    state = const AsyncLoading();
    final repository = ref.read(searchRepositoryProvider);
    state = await AsyncValue.guard(
      () => repository.search(
        query: normalizedQuery,
        category: category,
        status: status,
      ),
    );
  }

  void clear() {
    _searchVersion++;
    state = const AsyncData([]);
  }

  static String message(Object error) {
    if (error is DioException) {
      if (error.error is String && (error.error as String).isNotEmpty) {
        return error.error as String;
      }

      final data = error.response?.data;
      if (data is Map) {
        final responseError = data['error'];
        if (responseError is Map) {
          final message = responseError['message'];
          if (message is String && message.isNotEmpty) {
            return message;
          }
        }
      }
    }

    return 'Something went wrong. Please try again.';
  }
}

final searchNotifierProvider =
    AsyncNotifierProvider<SearchNotifier, List<ItemModel>>(SearchNotifier.new);
