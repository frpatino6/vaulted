import 'package:dio/dio.dart';

/// Builds a [Response] with typed JSON [data] for Dio stubs.
Response<Map<String, dynamic>> makeMapResponse({
  required RequestOptions requestOptions,
  Map<String, dynamic>? data,
  int statusCode = 200,
  Headers? headers,
}) {
  return Response<Map<String, dynamic>>(
    requestOptions: requestOptions,
    data: data,
    statusCode: statusCode,
    headers: headers,
  );
}
