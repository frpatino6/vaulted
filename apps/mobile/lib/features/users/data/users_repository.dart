import 'models/user_model.dart';
import 'users_remote_data_source.dart';

class UsersRepository {
  UsersRepository(this._remote);

  final UsersRemoteDataSource _remote;

  Future<List<UserModel>> getUsers() => _remote.getUsers();

  Future<UserModel> inviteUser({
    required String email,
    required String role,
    required List<String> propertyIds,
    String? expiresAt,
  }) =>
      _remote.inviteUser(
        email: email,
        role: role,
        propertyIds: propertyIds,
        expiresAt: expiresAt,
      );

  Future<UserModel> updateUser(
    String id, {
    String? role,
    bool? isActive,
    List<String>? propertyIds,
  }) =>
      _remote.updateUser(
        id,
        role: role,
        isActive: isActive,
        propertyIds: propertyIds,
      );

  Future<void> deactivateUser(String id) => _remote.deactivateUser(id);
}
