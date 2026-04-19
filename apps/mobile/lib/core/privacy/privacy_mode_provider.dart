import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage_provider.dart';

class PrivacyModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return ref.read(secureStorageProvider).getPrivacyMode();
  }

  Future<void> toggle() async {
    final current = state.valueOrNull ?? false;
    final next = !current;
    state = AsyncData(next);
    await ref.read(secureStorageProvider).savePrivacyMode(next);
  }

  Future<void> reset() async {
    state = const AsyncData(false);
    await ref.read(secureStorageProvider).deletePrivacyMode();
  }
}

final privacyModeProvider =
    AsyncNotifierProvider<PrivacyModeNotifier, bool>(PrivacyModeNotifier.new);
