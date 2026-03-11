import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/property_model.dart';
import '../data/property_repository_provider.dart';

class PropertiesNotifier extends AsyncNotifier<List<PropertyModel>> {
  @override
  Future<List<PropertyModel>> build() async {
    return load();
  }

  Future<List<PropertyModel>> load() async {
    state = const AsyncLoading();
    try {
      final list = await ref.read(propertyRepositoryProvider).getProperties();
      state = AsyncData(list);
      return list;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<PropertyModel?> create({
    required String name,
    required String type,
    required String street,
    required String city,
    required String state,
    required String zip,
    String country = 'USA',
  }) async {
    try {
      final property = await ref.read(propertyRepositoryProvider).createProperty(
            name: name,
            type: type,
            street: street,
            city: city,
            state: state,
            zip: zip,
            country: country,
          );
      await load();
      return property;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    await ref.read(propertyRepositoryProvider).deleteProperty(id);
    await load();
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

final propertiesNotifierProvider =
    AsyncNotifierProvider<PropertiesNotifier, List<PropertyModel>>(
  PropertiesNotifier.new,
);
