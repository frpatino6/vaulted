import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/household_members_repository_provider.dart';
import '../data/models/household_member_model.dart';

class HouseholdMembersNotifier extends AsyncNotifier<List<HouseholdMemberModel>> {
  @override
  Future<List<HouseholdMemberModel>> build() {
    return ref.read(householdMembersRepositoryProvider).getMembers();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(householdMembersRepositoryProvider).getMembers(),
    );
  }

  Future<void> createMember({
    required String name,
    String? relationship,
    bool isMinor = false,
  }) async {
    await ref.read(householdMembersRepositoryProvider).createMember(
      name: name,
      relationship: relationship,
      isMinor: isMinor,
    );
    await refresh();
  }

  Future<void> updateMember(
    String id, {
    String? name,
    String? relationship,
    bool? isMinor,
  }) async {
    await ref.read(householdMembersRepositoryProvider).updateMember(
      id,
      name: name,
      relationship: relationship,
      isMinor: isMinor,
    );
    await refresh();
  }

  Future<void> archiveMember(String id) async {
    await ref.read(householdMembersRepositoryProvider).archiveMember(id);
    await refresh();
  }

  static String message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message =
            (data['error'] as Map<String, dynamic>?)?['message'] as String?;
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
      if (error.error is String && (error.error as String).isNotEmpty) {
        return error.error as String;
      }
    }
    return 'Unable to load household members';
  }
}

final householdMembersNotifierProvider =
    AsyncNotifierProvider<HouseholdMembersNotifier, List<HouseholdMemberModel>>(
      HouseholdMembersNotifier.new,
    );
