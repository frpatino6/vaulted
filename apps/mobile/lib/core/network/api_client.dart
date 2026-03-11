import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../storage/auth_token_store.dart';
import '../storage/secure_storage.dart';

/// Shared Dio instance with auth interceptor.
/// Access token in memory (AuthTokenStore), refresh token in SecureStorage.
// TODO: add certificate pinning before production
class ApiClient {
  ApiClient({
    required SecureStorage secureStorage,
    required AuthTokenStore tokenStore,
    VoidCallback? onAuthFailure,
    VoidCallback? onMfaRequired,
  })  : _secureStorage = secureStorage,
        _tokenStore = tokenStore,
        _onAuthFailure = onAuthFailure,
        _onMfaRequired = onMfaRequired,
        _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(_AuthInterceptor(
      dio: _dio,
      secureStorage: _secureStorage,
      tokenStore: _tokenStore,
      onAuthFailure: _onAuthFailure,
      onMfaRequired: _onMfaRequired,
    ));
  }

  final SecureStorage _secureStorage;
  final AuthTokenStore _tokenStore;
  final VoidCallback? _onAuthFailure;
  final VoidCallback? _onMfaRequired;
  final Dio _dio;

  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({
    required Dio dio,
    required SecureStorage secureStorage,
    required AuthTokenStore tokenStore,
    VoidCallback? onAuthFailure,
    VoidCallback? onMfaRequired,
  })  : _dio = dio,
        _secureStorage = secureStorage,
        _tokenStore = tokenStore,
        _onAuthFailure = onAuthFailure,
        _onMfaRequired = onMfaRequired;

  final Dio _dio;
  final SecureStorage _secureStorage;
  final AuthTokenStore _tokenStore;
  final VoidCallback? _onAuthFailure;
  final VoidCallback? _onMfaRequired;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenStore.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final body = err.response?.data;

    // 403/401 with "MFA verification required" → redirect to MFA screen (keep token)
    if ((status == 403 || status == 401) && _isMfaRequiredMessage(body)) {
      _tokenStore.setMfaPending(true);
      _onMfaRequired?.call();
      return handler.next(err);
    }

    if (status != 401) {
      return handler.next(err);
    }

    // Use the full URI path for reliable matching (path alone may lack leading slash)
    final uriPath = err.requestOptions.uri.path;

    // Avoid retry loop on refresh endpoint
    if (uriPath.contains('auth/refresh')) {
      _clearAndNotify();
      return handler.next(err);
    }

    // Never intercept other auth endpoints (login, mfa/verify, etc.)
    // Let errors propagate so the UI can handle them directly.
    if (uriPath.contains('auth/')) {
      return handler.next(err);
    }

    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _clearAndNotify();
        return handler.next(err);
      }

      final response = await _dio.post<Map<String, dynamic>>(
        'auth/refresh',
        options: Options(
          headers: {'Cookie': 'refresh_token=$refreshToken'},
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final inner = data['data'];
        if (inner is Map<String, dynamic> && inner['accessToken'] != null) {
          final accessToken = inner['accessToken'] as String;
          _tokenStore.setToken(accessToken);

          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $accessToken';

          final retry = await _dio.fetch(opts);
          return handler.resolve(Response(
            requestOptions: opts,
            data: retry.data,
            statusCode: retry.statusCode,
          ));
        }
      }
    } catch (_) {
      // Refresh failed
    }

    _clearAndNotify();
    handler.next(err);
  }

  void _clearAndNotify() {
    _tokenStore.clear();
    _secureStorage.deleteRefreshToken();
    _onAuthFailure?.call();
  }

  static bool _isMfaRequiredMessage(dynamic body) {
    if (body is! Map) return false;
    final msg = body['error'] is Map ? (body['error'] as Map)['message'] : body['message'];
    final s = msg?.toString().toLowerCase() ?? '';
    return s.contains('mfa') && (s.contains('verification') || s.contains('required'));
  }
}
