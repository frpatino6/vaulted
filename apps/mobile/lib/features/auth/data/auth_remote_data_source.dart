import 'package:dio/dio.dart';

/// Remote data source for auth API calls.
/// Uses the shared Dio instance — auth interceptor handles tokens.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  /// POST /auth/login
  /// Returns (data, setCookieHeader) for repository to persist refresh token.
  /// Response format: { success: true, data: { accessToken, mfaRequired } }
  Future<({Map<String, dynamic> data, String? setCookie})> login(
    String email,
    String password,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'auth/login',
      data: {'email': email, 'password': password},
    );
    final setCookie = response.headers.value('set-cookie') ??
        response.headers.value('Set-Cookie');
    return (data: _unwrapData(response), setCookie: setCookie);
  }

  /// POST /auth/mfa/verify
  /// Requires Authorization: Bearer {accessToken from login}
  /// Returns { accessToken }.
  Future<Map<String, dynamic>> verifyMfa(String code) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'auth/mfa/verify',
      data: {'code': code},
    );
    return _unwrapData(response);
  }

  /// POST /auth/logout
  Future<void> logout() async {
    await _dio.post('auth/logout');
  }

  /// POST /auth/refresh
  /// Sends refresh token via Cookie header.
  /// Returns { accessToken }.
  Future<Map<String, dynamic>> refresh() async {
    // Note: Typically called by the auth interceptor with Cookie header.
    // This method is for explicit refresh if needed.
    final response = await _dio.post<Map<String, dynamic>>('auth/refresh');
    return _unwrapData(response);
  }

  Map<String, dynamic> _unwrapData(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }
    if (data['success'] == true && data['data'] != null) {
      return data['data'] as Map<String, dynamic>;
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
}
