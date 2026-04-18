// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presence_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PresenceUserImpl _$$PresenceUserImplFromJson(Map<String, dynamic> json) =>
    _$PresenceUserImpl(
      userId: json['userId'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      connectedAt: json['connectedAt'] as String,
      lastSeen: json['lastSeen'] as String,
    );

Map<String, dynamic> _$$PresenceUserImplToJson(_$PresenceUserImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'email': instance.email,
      'role': instance.role,
      'connectedAt': instance.connectedAt,
      'lastSeen': instance.lastSeen,
    };
