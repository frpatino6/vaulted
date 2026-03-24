import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/maintenance_repository_provider.dart';
import '../data/models/maintenance_model.dart';

// ---------------------------------------------------------------------------
// Global list notifier — all maintenance records for the tenant
// ---------------------------------------------------------------------------

class MaintenanceListNotifier extends AsyncNotifier<List<MaintenanceModel>> {
  @override
  Future<List<MaintenanceModel>> build() async => [];

  Future<void> load({
    String? status,
    String? itemId,
    bool upcoming = false,
    int daysAhead = 30,
  }) async {
    state = const AsyncLoading();
    try {
      final records = await ref.read(maintenanceRepositoryProvider).getAll(
            status: status,
            itemId: itemId,
            upcoming: upcoming,
            daysAhead: daysAhead,
          );
      state = AsyncData(records);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> complete(String id) async {
    try {
      final updated = await ref.read(maintenanceRepositoryProvider).complete(id);
      state = state.whenData(
        (list) => list.map((r) => r.id == id ? updated : r).toList(),
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> cancel(String id) async {
    try {
      final updated = await ref.read(maintenanceRepositoryProvider).cancel(id);
      state = state.whenData(
        (list) => list.map((r) => r.id == id ? updated : r).toList(),
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> delete(String id) async {
    try {
      await ref.read(maintenanceRepositoryProvider).delete(id);
      state = state.whenData((list) => list.where((r) => r.id != id).toList());
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  static String errorMessage(Object e) {
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

final maintenanceListNotifierProvider =
    AsyncNotifierProvider<MaintenanceListNotifier, List<MaintenanceModel>>(
  MaintenanceListNotifier.new,
);

// ---------------------------------------------------------------------------
// Per-item notifier — maintenance records for a single item
// ---------------------------------------------------------------------------

class ItemMaintenanceNotifier
    extends FamilyAsyncNotifier<List<MaintenanceModel>, String> {
  @override
  Future<List<MaintenanceModel>> build(String itemId) async {
    return ref.read(maintenanceRepositoryProvider).getByItem(itemId);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    try {
      final records =
          await ref.read(maintenanceRepositoryProvider).getByItem(arg);
      state = AsyncData(records);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<MaintenanceModel?> schedule({
    required String title,
    required DateTime scheduledDate,
    String? description,
    bool isRecurring = false,
    int? recurrenceIntervalDays,
    String? providerName,
    String? providerContact,
    double? cost,
    String currency = 'USD',
    String? notes,
  }) async {
    try {
      final record = await ref.read(maintenanceRepositoryProvider).schedule(
            itemId: arg,
            title: title,
            scheduledDate: scheduledDate,
            description: description,
            isRecurring: isRecurring,
            recurrenceIntervalDays: recurrenceIntervalDays,
            providerName: providerName,
            providerContact: providerContact,
            cost: cost,
            currency: currency,
            notes: notes,
          );
      state = state.whenData((list) => [record, ...list]);
      return record;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return null;
    }
  }

  Future<void> complete(String id) async {
    try {
      final updated = await ref.read(maintenanceRepositoryProvider).complete(id);
      state = state.whenData(
        (list) => list.map((r) => r.id == id ? updated : r).toList(),
      );
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> delete(String id) async {
    try {
      await ref.read(maintenanceRepositoryProvider).delete(id);
      state = state.whenData((list) => list.where((r) => r.id != id).toList());
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Returns the AI result map, or null on error.
  /// Automatically reloads the list if a record was created.
  Future<Map<String, dynamic>?> analyzeWithAi() async {
    try {
      final result =
          await ref.read(maintenanceRepositoryProvider).analyzeWithAi(arg);
      if (result['recordCreated'] == true) {
        await reload();
      }
      return result;
    } catch (e) {
      return null;
    }
  }
}

final itemMaintenanceNotifierProvider = AsyncNotifierProviderFamily<
    ItemMaintenanceNotifier, List<MaintenanceModel>, String>(
  ItemMaintenanceNotifier.new,
);
