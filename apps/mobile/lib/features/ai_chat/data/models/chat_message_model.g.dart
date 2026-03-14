// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatItemResultImpl _$$ChatItemResultImplFromJson(
  Map<String, dynamic> json,
) => _$ChatItemResultImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  category: json['category'] as String,
  status: json['status'] as String,
  propertyName: json['propertyName'] as String?,
  roomName: json['roomName'] as String?,
  photos:
      (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  valuation: json['valuation'] == null
      ? null
      : ChatItemValuation.fromJson(json['valuation'] as Map<String, dynamic>),
  score: (json['score'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$ChatItemResultImplToJson(
  _$ChatItemResultImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'category': instance.category,
  'status': instance.status,
  'propertyName': instance.propertyName,
  'roomName': instance.roomName,
  'photos': instance.photos,
  'valuation': instance.valuation,
  'score': instance.score,
};

_$ChatItemValuationImpl _$$ChatItemValuationImplFromJson(
  Map<String, dynamic> json,
) => _$ChatItemValuationImpl(
  currentValue: (json['currentValue'] as num).toInt(),
  currency: json['currency'] as String? ?? 'USD',
);

Map<String, dynamic> _$$ChatItemValuationImplToJson(
  _$ChatItemValuationImpl instance,
) => <String, dynamic>{
  'currentValue': instance.currentValue,
  'currency': instance.currency,
};

_$ChatMessageModelImpl _$$ChatMessageModelImplFromJson(
  Map<String, dynamic> json,
) => _$ChatMessageModelImpl(
  id: json['id'] as String,
  role: $enumDecode(_$ChatRoleEnumMap, json['role']),
  content: json['content'] as String,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => ChatItemResult.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  sources:
      (json['sources'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  sessionId: json['sessionId'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  isLoading: json['isLoading'] as bool? ?? false,
);

Map<String, dynamic> _$$ChatMessageModelImplToJson(
  _$ChatMessageModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'role': _$ChatRoleEnumMap[instance.role]!,
  'content': instance.content,
  'items': instance.items,
  'sources': instance.sources,
  'sessionId': instance.sessionId,
  'createdAt': instance.createdAt?.toIso8601String(),
  'isLoading': instance.isLoading,
};

const _$ChatRoleEnumMap = {
  ChatRole.user: 'user',
  ChatRole.assistant: 'assistant',
};
