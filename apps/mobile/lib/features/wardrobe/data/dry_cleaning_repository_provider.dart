import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'dry_cleaning_repository.dart';

final dryCleaningRepositoryProvider = Provider<DryCleaningRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DryCleaningRepository(apiClient.dio);
});
