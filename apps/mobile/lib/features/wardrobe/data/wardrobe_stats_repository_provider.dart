import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'wardrobe_stats_repository.dart';

final wardrobeStatsRepositoryProvider = Provider<WardrobeStatsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WardrobeStatsRepository(apiClient.dio);
});
