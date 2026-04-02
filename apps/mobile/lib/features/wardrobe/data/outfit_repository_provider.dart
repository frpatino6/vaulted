import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'outfit_repository.dart';

final outfitRepositoryProvider = Provider<OutfitRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OutfitRepository(apiClient.dio);
});
