import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dry_cleaning_model.dart';
import '../data/dry_cleaning_repository_provider.dart';

class DryCleaningNotifier extends FamilyAsyncNotifier<List<DryCleaningModel>, String> {
  @override
  Future<List<DryCleaningModel>> build(String arg) {
    return _load(arg);
  }

  Future<void> refresh() async {
    final String itemId = arg;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(itemId));
  }

  Future<void> markReturned(String recordId) async {
    await ref.read(dryCleaningRepositoryProvider).markReturned(recordId);
    await refresh();
  }

  Future<List<DryCleaningModel>> _load(String itemId) {
    return ref.read(dryCleaningRepositoryProvider).getHistory(itemId);
  }
}

final dryCleaningNotifierProvider = AsyncNotifierProvider.family<
    DryCleaningNotifier,
    List<DryCleaningModel>,
    String>(DryCleaningNotifier.new);
