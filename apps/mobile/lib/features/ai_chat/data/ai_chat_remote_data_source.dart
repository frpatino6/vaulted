import 'package:dio/dio.dart';

import '../../../features/inventory/data/models/item_model.dart';
import 'models/chat_message_model.dart';

class AiChatRemoteDataSource {
  AiChatRemoteDataSource(this._dio);

  final Dio _dio;

  Future<({String answer, List<ChatItemResult> items, String sessionId, List<String> sources})> sendMessage({
    required String query,
    String? sessionId,
    String? propertyId,
  }) async {
    final body = <String, dynamic>{
      'query': query,
      'sessionId': sessionId,
      'propertyId': propertyId,
    };
    body.removeWhere((_, v) => v == null);

    final response = await _dio.post<Map<String, dynamic>>('ai/chat', data: body);

    final data = response.data;
    if (data == null || data['success'] != true) {
      final error = data?['error'] as Map<String, dynamic>?;
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
        error: error?['message'] ?? 'AI chat failed',
      );
    }

    final payload = data['data'] as Map<String, dynamic>? ?? {};
    final rawItems = payload['items'] as List? ?? [];

    final items = rawItems
        .whereType<Map>()
        .map((item) => ChatItemResult.fromJson(_normalizeItemJson(Map<String, dynamic>.from(item))))
        .toList();

    return (
      answer: payload['answer'] as String? ?? '',
      items: items,
      sessionId: payload['sessionId'] as String? ?? '',
      sources: (payload['sources'] as List?)?.whereType<String>().toList() ?? [],
    );
  }

  Future<void> reindex() async {
    await _dio.post<void>('ai/chat/reindex');
  }

  /// Converts a ChatItemResult to an ItemModel for use with existing widgets.
  static ItemModel chatItemToItemModel(ChatItemResult chatItem) {
    return ItemModel(
      id: chatItem.id,
      name: chatItem.name,
      category: chatItem.category,
      status: chatItem.status,
      propertyName: chatItem.propertyName,
      roomName: chatItem.roomName,
      photos: chatItem.photos,
      valuation: chatItem.valuation != null
          ? ItemValuationModel(
              currentValue: chatItem.valuation!.currentValue,
              currency: chatItem.valuation!.currency,
            )
          : null,
    );
  }

  static Map<String, dynamic> _normalizeItemJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['_id'];
    if (id != null) json['id'] = id is String ? id : id.toString();
    return json;
  }
}
