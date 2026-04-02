import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wardrobe_stats_repository.dart';
import '../data/wardrobe_stats_repository_provider.dart';

final wardrobeStatsProvider = FutureProvider<WardrobeStatsModel>((ref) {
  return ref.read(wardrobeStatsRepositoryProvider).getStats();
});
