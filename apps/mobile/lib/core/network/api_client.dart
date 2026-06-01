import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../storage/auth_token_store.dart';
import '../storage/secure_storage.dart';
import 'dio_credentials.dart';

/// Shared Dio instance with auth interceptor and certificate pinning.
/// Access token in memory (AuthTokenStore), refresh token in SecureStorage.
class ApiClient {
  ApiClient({
    required SecureStorage secureStorage,
    required AuthTokenStore tokenStore,
    VoidCallback? onAuthFailure,
    VoidCallback? onMfaRequired,
    void Function(String newToken)? onTokenRefreshed,
  }) : _secureStorage = secureStorage,
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
    applyWebCredentials(_dio);
    _applyCertificatePinning(_dio);
    _dio.interceptors.add(
      _AuthInterceptor(
        dio: _dio,
        secureStorage: _secureStorage,
        tokenStore: _tokenStore,
        onAuthFailure: _onAuthFailure,
        onMfaRequired: _onMfaRequired,
        onTokenRefreshed: onTokenRefreshed,
      ),
    );
  }

  final SecureStorage _secureStorage;
  final AuthTokenStore _tokenStore;
  final VoidCallback? _onAuthFailure;
  final VoidCallback? _onMfaRequired;
  final Dio _dio;

  Dio get dio => _dio;

  /// Enforces certificate pinning on native platforms (iOS/Android).
  /// Web is skipped because browsers own TLS validation. Debug builds allow
  /// local development certificates; release builds validate every trusted
  /// server certificate against the configured SHA-256 DER fingerprints.
  static void _applyCertificatePinning(Dio dio) {
    if (kIsWeb) return;
    final adapter = dio.httpClientAdapter as IOHttpClientAdapter;

    if (kDebugMode) {
      adapter.createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
      return;
    }

    adapter.validateCertificate = (cert, host, port) {
      if (cert == null) return false;
      final fingerprint = sha256.convert(cert.der).toString();
      return AppConfig.pinnedCertFingerprints.contains(fingerprint);
    };
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({
    required Dio dio,
    required SecureStorage secureStorage,
    required AuthTokenStore tokenStore,
    VoidCallback? onAuthFailure,
    VoidCallback? onMfaRequired,
    void Function(String newToken)? onTokenRefreshed,
  }) : _dio = dio,
       _secureStorage = secureStorage,
       _tokenStore = tokenStore,
       _onAuthFailure = onAuthFailure,
       _onMfaRequired = onMfaRequired,
       _onTokenRefreshed = onTokenRefreshed;

  final Dio _dio;
  final SecureStorage _secureStorage;
  final AuthTokenStore _tokenStore;
  final VoidCallback? _onAuthFailure;
  final VoidCallback? _onMfaRequired;
  final void Function(String newToken)? _onTokenRefreshed;

  Future<String?>? _refreshFuture;
  final List<({RequestOptions options, ErrorInterceptorHandler handler})>
  _pending = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenStore.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final body = err.response?.data;

    if ((status == 403 || status == 401) && _isMfaRequiredMessage(body)) {
      _tokenStore.setMfaPending(true);
      _onMfaRequired?.call();
      return handler.next(err);
    }

    if (status != 401) {
      return handler.next(err);
    }

    final uriPath = err.requestOptions.uri.path;

    if (uriPath.contains('auth/refresh')) {
      _clearAndNotify();
      return handler.next(err);
    }

    if (uriPath.contains('auth/')) {
      return handler.next(err);
    }

    if (err.requestOptions.extra['_refreshed'] == true) {
      _clearAndNotify();
      return handler.next(err);
    }

    if (_refreshFuture != null) {
      _pending.add((options: err.requestOptions, handler: handler));
      return;
    }

    _refreshFuture = _doRefresh();

    try {
      final newToken = await _refreshFuture;
      if (newToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        err.requestOptions.extra['_refreshed'] = true;
        final retry = await _dio.fetch(err.requestOptions);
        _processPending(newToken);
        return handler.resolve(retry);
      } else {
        _clearAndNotify();
        _processPending(null);
        handler.next(err);
      }
    } catch (_) {
      _clearAndNotify();
      _processPending(null);
      handler.next(err);
    } finally {
      _refreshFuture = null;
    }
  }

  Future<String?> _doRefresh() async {
    try {
      final Options refreshOptions;
      if (kIsWeb) {
        refreshOptions = Options();
      } else {
        final refreshToken = await _secureStorage.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) return null;
        refreshOptions = Options(
          headers: {'Cookie': 'refresh_token=$refreshToken'},
        );
      }

      final response = await _dio.post<Map<String, dynamic>>(
        'auth/refresh',
        options: refreshOptions,
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        final inner = data['data'];
        if (inner is Map<String, dynamic> && inner['accessToken'] != null) {
          final accessToken = inner['accessToken'] as String;
          if (!kIsWeb) {
            final setCookie =
                response.headers.value('set-cookie') ??
                response.headers.value('Set-Cookie');
            final rotatedRefreshToken = _parseRefreshToken(setCookie);
            if (rotatedRefreshToken != null && rotatedRefreshToken.isNotEmpty) {
              await _secureStorage.saveRefreshToken(rotatedRefreshToken);
            }
          }
          _tokenStore.setToken(accessToken);
          _onTokenRefreshed?.call(accessToken);
          return accessToken;
        }
      }
    } catch (_) {
      // Refresh failed
    }
    return null;
  }

  static String? _parseRefreshToken(String? setCookie) {
    if (setCookie == null || setCookie.isEmpty) return null;
    const prefix = 'refresh_token=';
    final start = setCookie.indexOf(prefix);
    if (start == -1) return null;
    final valueStart = start + prefix.length;
    final end = setCookie.indexOf(';', valueStart);
    return end == -1
        ? setCookie.substring(valueStart).trim()
        : setCookie.substring(valueStart, end).trim();
  }

  void _processPending(String? newToken) {
    for (final p in List.of(_pending)) {
      if (newToken != null) {
        p.options.headers['Authorization'] = 'Bearer $newToken';
        p.options.extra['_refreshed'] = true;
        _dio
            .fetch(p.options)
            .then(
              (r) => p.handler.resolve(r),
              onError: (e) {
                if (e is DioException) {
                  p.handler.next(e);
                } else {
                  p.handler.next(
                    DioException(requestOptions: p.options, error: e),
                  );
                }
              },
            );
      } else {
        p.handler.next(
          DioException(
            requestOptions: p.options,
            type: DioExceptionType.unknown,
          ),
        );
      }
    }
    _pending.clear();
  }

  void _clearAndNotify() {
    _tokenStore.clear();
    _secureStorage.deleteRefreshToken();
    _onAuthFailure?.call();
  }

  static bool _isMfaRequiredMessage(dynamic body) {
    if (body is! Map) return false;
    final msg =
        body['error'] is Map
            ? (body['error'] as Map)['message']
            : body['message'];
    final s = msg?.toString().toLowerCase() ?? '';
    return s.contains('mfa') &&
        (s.contains('verification') || s.contains('required'));
  }
}
