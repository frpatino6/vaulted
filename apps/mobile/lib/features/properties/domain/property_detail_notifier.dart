import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/property_model.dart';
import '../data/property_repository_provider.dart';

class PropertyDetailNotifier extends AsyncNotifier<PropertyModel?> {
  String? _propertyId;

  @override
  Future<PropertyModel?> build() async => null;

  Future<PropertyModel?> load(String id) async {
    _propertyId = id;
    state = const AsyncLoading();
    try {
      final property = await ref.read(propertyRepositoryProvider).getProperty(id);
      state = AsyncData(property);
      return property;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<PropertyModel?> addFloor(String name) async {
    final id = _propertyId;
    if (id == null) return null;
    try {
      final property =
          await ref.read(propertyRepositoryProvider).addFloor(id, name);
      state = AsyncData(property);
      return property;
    } catch (_) {
      rethrow;
    }
  }

  Future<PropertyModel?> updateFloor(String floorId, String name) async {
    final id = _propertyId;
    if (id == null) return null;
    try {
      final property = await ref
          .read(propertyRepositoryProvider)
          .updateFloor(id, floorId, name);
      state = AsyncData(property);
      return property;
    } catch (_) {
      rethrow;
    }
  }

  Future<PropertyModel?> deleteFloor(String floorId) async {
    final id = _propertyId;
    if (id == null) return null;
    try {
      final property = await ref
          .read(propertyRepositoryProvider)
          .deleteFloor(id, floorId);
      state = AsyncData(property);
      return property;
    } catch (_) {
      rethrow;
    }
  }

  Future<PropertyModel?> addRoom(
    String floorId,
    String name,
    String type,
  ) async {
    final id = _propertyId;
    if (id == null) return null;
    try {
      final property = await ref
          .read(propertyRepositoryProvider)
          .addRoom(id, floorId, name, type);
      state = AsyncData(property);
      return property;
    } catch (_) {
      rethrow;
    }
  }

  Future<PropertyModel?> updateRoom(
    String floorId,
    String roomId,
    String name,
    String type,
  ) async {
    final id = _propertyId;
    if (id == null) return null;
    try {
      final property = await ref
          .read(propertyRepositoryProvider)
          .updateRoom(id, floorId, roomId, name, type);
      state = AsyncData(property);
      return property;
    } catch (_) {
      rethrow;
    }
  }

  Future<PropertyModel?> deleteRoom(String floorId, String roomId) async {
    final id = _propertyId;
    if (id == null) return null;
    try {
      final property = await ref
          .read(propertyRepositoryProvider)
          .deleteRoom(id, floorId, roomId);
      state = AsyncData(property);
      return property;
    } catch (_) {
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

final propertyDetailNotifierProvider =
    AsyncNotifierProvider<PropertyDetailNotifier, PropertyModel?>(
  PropertyDetailNotifier.new,
);
