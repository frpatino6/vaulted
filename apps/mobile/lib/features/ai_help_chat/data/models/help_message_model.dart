enum HelpMessageRole { user, assistant }

class HelpMessageModel {
  const HelpMessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.suggestions = const [],
    this.sessionId,
    this.createdAt,
    this.isLoading = false,
  });

  final String id;
  final HelpMessageRole role;
  final String content;
  final List<String> suggestions;
  final String? sessionId;
  final DateTime? createdAt;
  final bool isLoading;
}
