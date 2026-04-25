import 'package:dio/dio.dart';

import 'models/household_member_model.dart';

class HouseholdMembersRemoteDataSource {
  HouseholdMembersRemoteDataSource(this._dio);

  final Dio _dio;
  static const String _path = 'household-members';

  dynamic _unwrap(Response<Map<String, dynamic>> response) {
    final payload = response.data;
    if (payload == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }
    if (payload['success'] == true && payload['data'] != null) {
      return payload['data'];
    }
    throw DioException(
      requestOptions: response.requestOptions,
      type: DioExceptionType.badResponse,
      response: response,
      error: (payload['error'] as Map<String, dynamic>?)?['message'] ??
          'Unknown error',
    );
  }

  Future<List<HouseholdMemberModel>> getMembers() async {
    final response = await _dio.get<Map<String, dynamic>>(_path);
    final data = _unwrap(response);
    if (data is! List) return const [];
    return data
        .map((e) => HouseholdMemberModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<HouseholdMemberModel> createMember({
    required String name,
    String? relationship,
    bool isMinor = false,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _path,
      data: {
        'name': name,
        if (relationship != null && relationship.isNotEmpty)
          'relationship': relationship,
        'isMinor': isMinor,
      },
    );
    final data = _unwrap(response);
    return HouseholdMemberModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> archiveMember(String id) async {
    await _dio.delete<Map<String, dynamic>>('$_path/$id');
  }
}
