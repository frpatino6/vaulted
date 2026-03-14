import 'models/chat_message_model.dart';
import 'ai_chat_remote_data_source.dart';

class AiChatRepository {
  AiChatRepository(this._remote);

  final AiChatRemoteDataSource _remote;

  Future<({String answer, List<ChatItemResult> items, String sessionId, List<String> sources})>
      sendMessage({
    required String query,
    String? sessionId,
    String? propertyId,
  }) =>
          _remote.sendMessage(query: query, sessionId: sessionId, propertyId: propertyId);

  Future<void> reindex() => _remote.reindex();
}
