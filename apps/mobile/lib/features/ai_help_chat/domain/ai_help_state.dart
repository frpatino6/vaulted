import '../data/models/help_message_model.dart';

class AiHelpState {
  const AiHelpState({
    this.messages = const [],
    this.sessionId,
    this.isLoading = false,
    this.error,
  });

  final List<HelpMessageModel> messages;
  final String? sessionId;
  final bool isLoading;
  final String? error;

  AiHelpState copyWith({
    List<HelpMessageModel>? messages,
    String? sessionId,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AiHelpState(
      messages: messages ?? this.messages,
      sessionId: sessionId ?? this.sessionId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
