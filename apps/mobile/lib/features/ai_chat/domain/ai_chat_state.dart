import '../data/models/chat_message_model.dart';

class AiChatState {
  const AiChatState({
    this.messages = const [],
    this.sessionId,
    this.isLoading = false,
    this.error,
  });

  final List<ChatMessageModel> messages;
  final String? sessionId;
  final bool isLoading;
  final String? error;

  AiChatState copyWith({
    List<ChatMessageModel>? messages,
    String? sessionId,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      sessionId: sessionId ?? this.sessionId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
