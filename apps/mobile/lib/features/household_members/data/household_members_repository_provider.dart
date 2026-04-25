import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'household_members_remote_data_source_provider.dart';
import 'household_members_repository.dart';

final householdMembersRepositoryProvider = Provider<HouseholdMembersRepository>((
  ref,
) {
  return HouseholdMembersRepository(
    ref.watch(householdMembersRemoteDataSourceProvider),
  );
});
