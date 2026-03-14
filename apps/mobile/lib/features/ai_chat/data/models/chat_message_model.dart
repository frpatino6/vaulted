import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message_model.freezed.dart';
part 'chat_message_model.g.dart';

enum ChatRole { user, assistant }

@freezed
class ChatItemResult with _$ChatItemResult {
  const factory ChatItemResult({
    required String id,
    required String name,
    required String category,
    required String status,
    String? propertyName,
    String? roomName,
    @Default([]) List<String> photos,
    ChatItemValuation? valuation,
    @Default(0.0) double score,
  }) = _ChatItemResult;

  factory ChatItemResult.fromJson(Map<String, dynamic> json) =>
      _$ChatItemResultFromJson(json);
}

@freezed
class ChatItemValuation with _$ChatItemValuation {
  const factory ChatItemValuation({
    required int currentValue,
    @Default('USD') String currency,
  }) = _ChatItemValuation;

  factory ChatItemValuation.fromJson(Map<String, dynamic> json) =>
      _$ChatItemValuationFromJson(json);
}

@freezed
class ChatMessageModel with _$ChatMessageModel {
  const factory ChatMessageModel({
    required String id,
    required ChatRole role,
    required String content,
    @Default([]) List<ChatItemResult> items,
    @Default([]) List<String> sources,
    String? sessionId,
    DateTime? createdAt,
    @Default(false) bool isLoading,
  }) = _ChatMessageModel;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);
}
