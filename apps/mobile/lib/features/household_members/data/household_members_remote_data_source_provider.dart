import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client_provider.dart';
import 'household_members_remote_data_source.dart';

final householdMembersRemoteDataSourceProvider =
    Provider<HouseholdMembersRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HouseholdMembersRemoteDataSource(apiClient.dio);
});
