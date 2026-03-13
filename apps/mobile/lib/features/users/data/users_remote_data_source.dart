import 'package:dio/dio.dart';

import 'models/user_model.dart';

/// Remote data source for users API.
class UsersRemoteDataSource {
  UsersRemoteDataSource(this._dio);

  final Dio _dio;

  static const String _path = 'users';

  dynamic _unwrapData(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }
    if (data['success'] == true && data['data'] != null) {
      return data['data'];
    }
    final error = data['error'] as Map<String, dynamic>?;
    final message = error?['message'] as String? ?? 'Unknown error';
    throw DioException(
      requestOptions: response.requestOptions,
      type: DioExceptionType.badResponse,
      response: response,
      error: message,
    );
  }

  /// GET /users
  Future<List<UserModel>> getUsers() async {
    final response = await _dio.get<Map<String, dynamic>>(_path);
    final list = _unwrapData(response);
    if (list is! List) return [];
    return list
        .map(
          (e) => UserModel.fromJson(
            Map<String, dynamic>.from(e as Map<String, dynamic>),
          ),
        )
        .toList();
  }

  /// POST /users/invite
  Future<UserModel> inviteUser({
    required String email,
    required String role,
    required List<String> propertyIds,
    String? expiresAt,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'role': role,
      'propertyIds': propertyIds,
    };
    if (expiresAt != null) body['expiresAt'] = expiresAt;
    final response =
        await _dio.post<Map<String, dynamic>>('$_path/invite', data: body);
    final data = _unwrapData(response);
    return UserModel.fromJson(
      Map<String, dynamic>.from(data is Map ? data : {}),
    );
  }

  /// PUT /users/:id
  Future<UserModel> updateUser(
    String id, {
    String? role,
    bool? isActive,
    List<String>? propertyIds,
  }) async {
    final body = <String, dynamic>{};
    if (role != null) body['role'] = role;
    if (isActive != null) body['isActive'] = isActive;
    if (propertyIds != null) body['propertyIds'] = propertyIds;
    final response =
        await _dio.put<Map<String, dynamic>>('$_path/$id', data: body);
    final data = _unwrapData(response);
    return UserModel.fromJson(
      Map<String, dynamic>.from(data is Map ? data : {}),
    );
  }

  /// DELETE /users/:id
  Future<void> deactivateUser(String id) async {
    await _dio.delete<Map<String, dynamic>>('$_path/$id');
  }
}
