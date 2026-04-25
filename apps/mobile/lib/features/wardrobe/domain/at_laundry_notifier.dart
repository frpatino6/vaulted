import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/at_laundry_model.dart';
import '../data/at_laundry_repository.dart';

class AtLaundryNotifier extends AsyncNotifier<AtLaundryData?> {
  @override
  Future<AtLaundryData?> build() {
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<AtLaundryData?> _load() {
    return ref.read(atLaundryRepositoryProvider).getAtLaundry();
  }
}

final atLaundryNotifierProvider =
    AsyncNotifierProvider<AtLaundryNotifier, AtLaundryData?>(
  AtLaundryNotifier.new,
);
