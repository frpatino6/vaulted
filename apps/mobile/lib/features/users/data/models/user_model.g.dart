// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isActive: json['isActive'] as bool,
      status: json['status'] as String,
      mfaEnabled: json['mfaEnabled'] as bool,
      propertyIds:
          (json['propertyIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      lastLogin: json['lastLogin'] as String?,
      expiresAt: json['expiresAt'] as String?,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'role': instance.role,
      'isActive': instance.isActive,
      'status': instance.status,
      'mfaEnabled': instance.mfaEnabled,
      'propertyIds': instance.propertyIds,
      'lastLogin': instance.lastLogin,
      'expiresAt': instance.expiresAt,
      'createdAt': instance.createdAt,
    };
