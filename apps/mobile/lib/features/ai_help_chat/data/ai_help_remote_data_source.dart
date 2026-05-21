import 'package:dio/dio.dart';

class AiHelpRemoteDataSource {
  AiHelpRemoteDataSource(this._dio);

  final Dio _dio;

  Future<({String answer, String sessionId, List<String> suggestions})> chat({
    required String query,
    String? sessionId,
    String? currentScreen,
  }) async {
    final body = <String, dynamic>{
      'query': query,
      'sessionId': sessionId,
      'currentScreen': currentScreen,
    };
    body.removeWhere((_, value) => value == null);

    final response = await _dio.post<Map<String, dynamic>>(
      'ai/help/chat',
      data: body,
    );

    final data = response.data;
    if (data == null || data['success'] != true) {
      final error = data?['error'] as Map<String, dynamic>?;
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
        error: error?['message'] ?? 'Vaulted Guide failed',
      );
    }

    final payload = data['data'] as Map<String, dynamic>? ?? {};
    return (
      answer: payload['answer'] as String? ?? '',
      sessionId: payload['sessionId'] as String? ?? '',
      suggestions:
          (payload['suggestions'] as List?)?.whereType<String>().toList() ??
              const <String>[],
    );
  }
}
