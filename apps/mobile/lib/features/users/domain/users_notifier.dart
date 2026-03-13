import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/user_model.dart';
import '../data/users_repository_provider.dart';

class UsersNotifier extends AutoDisposeAsyncNotifier<List<UserModel>> {
  @override
  Future<List<UserModel>> build() =>
      ref.read(usersRepositoryProvider).getUsers();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(usersRepositoryProvider).getUsers(),
    );
  }

  Future<void> invite({
    required String email,
    required String role,
    required List<String> propertyIds,
    String? expiresAt,
  }) async {
    await ref.read(usersRepositoryProvider).inviteUser(
          email: email,
          role: role,
          propertyIds: propertyIds,
          expiresAt: expiresAt,
        );
    await refresh();
  }

  Future<void> updateUser(
    String id, {
    String? role,
    bool? isActive,
    List<String>? propertyIds,
  }) async {
    await ref.read(usersRepositoryProvider).updateUser(
          id,
          role: role,
          isActive: isActive,
          propertyIds: propertyIds,
        );
    await refresh();
  }

  Future<void> deactivateUser(String id) async {
    await ref.read(usersRepositoryProvider).deactivateUser(id);
    await refresh();
  }

  static String message(Object e) => e is DioException
      ? (e.response?.data?['error']?['message']?.toString() ?? 'Request failed')
      : e.toString();
}

final usersNotifierProvider =
    AsyncNotifierProvider.autoDispose<UsersNotifier, List<UserModel>>(
  UsersNotifier.new,
);
