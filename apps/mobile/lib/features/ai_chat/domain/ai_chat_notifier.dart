import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_chat_repository_provider.dart';
import '../data/models/chat_message_model.dart';
import 'ai_chat_state.dart';

class AiChatNotifier extends Notifier<AiChatState> {
  @override
  AiChatState build() => const AiChatState();

  Future<void> sendMessage(String query, {String? propertyId}) async {
    final userMsgId = 'msg_${DateTime.now().microsecondsSinceEpoch}';
    final loadingMsgId = 'msg_${DateTime.now().microsecondsSinceEpoch + 1}';

    final userMsg = ChatMessageModel(
      id: userMsgId,
      role: ChatRole.user,
      content: query,
      createdAt: DateTime.now(),
    );
    final loadingMsg = ChatMessageModel(
      id: loadingMsgId,
      role: ChatRole.assistant,
      content: '',
      isLoading: true,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, loadingMsg],
      isLoading: true,
      clearError: true,
    );

    try {
      final result = await ref.read(aiChatRepositoryProvider).sendMessage(
            query: query,
            sessionId: state.sessionId,
            propertyId: propertyId,
          );

      final assistantMsg = ChatMessageModel(
        id: loadingMsgId,
        role: ChatRole.assistant,
        content: result.answer,
        items: result.items,
        sources: result.sources,
        sessionId: result.sessionId,
        createdAt: DateTime.now(),
        isLoading: false,
      );

      final updated = state.messages
          .map((m) => m.id == loadingMsgId ? assistantMsg : m)
          .toList();

      state = state.copyWith(
        messages: updated,
        sessionId: result.sessionId,
        isLoading: false,
      );
    } catch (e) {
      final updated = state.messages.where((m) => m.id != loadingMsgId).toList();
      state = state.copyWith(
        messages: updated,
        isLoading: false,
        error: _errorMessage(e),
      );
    }
  }

  void clearSession() {
    state = const AiChatState();
  }

  static String _errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['error']?['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
      if (e.response?.statusCode == 429) return 'Rate limit reached. Try again in a minute.';
    }
    return 'Something went wrong. Please try again.';
  }
}

final aiChatNotifierProvider = NotifierProvider<AiChatNotifier, AiChatState>(AiChatNotifier.new);
