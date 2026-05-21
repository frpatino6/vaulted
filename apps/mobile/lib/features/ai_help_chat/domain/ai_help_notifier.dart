import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_help_repository_provider.dart';
import '../data/models/help_message_model.dart';
import 'ai_help_state.dart';

class AiHelpNotifier extends Notifier<AiHelpState> {
  @override
  AiHelpState build() => const AiHelpState();

  Future<void> sendMessage(String query, {String? currentScreen}) async {
    final userMsgId = 'help_${DateTime.now().microsecondsSinceEpoch}';
    final loadingMsgId =
        'help_${DateTime.now().microsecondsSinceEpoch + 1}';

    final userMsg = HelpMessageModel(
      id: userMsgId,
      role: HelpMessageRole.user,
      content: query,
      createdAt: DateTime.now(),
    );
    final loadingMsg = HelpMessageModel(
      id: loadingMsgId,
      role: HelpMessageRole.assistant,
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
      final result = await ref.read(aiHelpRepositoryProvider).chat(
            query: query,
            sessionId: state.sessionId,
            currentScreen: currentScreen,
          );

      final assistantMsg = HelpMessageModel(
        id: loadingMsgId,
        role: HelpMessageRole.assistant,
        content: result.answer,
        suggestions: result.suggestions,
        sessionId: result.sessionId,
        createdAt: DateTime.now(),
      );

      final updated = state.messages
          .map((message) => message.id == loadingMsgId ? assistantMsg : message)
          .toList();

      state = state.copyWith(
        messages: updated,
        sessionId: result.sessionId,
        isLoading: false,
      );
    } catch (e) {
      final updated = state.messages
          .where((message) => message.id != loadingMsgId)
          .toList();
      state = state.copyWith(
        messages: updated,
        isLoading: false,
        error: _errorMessage(e),
      );
    }
  }

  void clearSession() {
    state = const AiHelpState();
  }

  static String _errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['error'] is Map
            ? (data['error'] as Map)['message']
            : data['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
      if (e.response?.statusCode == 429) {
        return 'Rate limit reached. Try again in a minute.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}

final aiHelpNotifierProvider =
    NotifierProvider<AiHelpNotifier, AiHelpState>(AiHelpNotifier.new);
