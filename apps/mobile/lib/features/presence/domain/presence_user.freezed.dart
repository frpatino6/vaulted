// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'presence_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PresenceUser _$PresenceUserFromJson(Map<String, dynamic> json) {
  return _PresenceUser.fromJson(json);
}

/// @nodoc
mixin _$PresenceUser {
  String get userId => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  String get connectedAt => throw _privateConstructorUsedError;
  String get lastSeen => throw _privateConstructorUsedError;

  /// Serializes this PresenceUser to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PresenceUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PresenceUserCopyWith<PresenceUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PresenceUserCopyWith<$Res> {
  factory $PresenceUserCopyWith(
    PresenceUser value,
    $Res Function(PresenceUser) then,
  ) = _$PresenceUserCopyWithImpl<$Res, PresenceUser>;
  @useResult
  $Res call({
    String userId,
    String email,
    String role,
    String connectedAt,
    String lastSeen,
  });
}

/// @nodoc
class _$PresenceUserCopyWithImpl<$Res, $Val extends PresenceUser>
    implements $PresenceUserCopyWith<$Res> {
  _$PresenceUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PresenceUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? email = null,
    Object? role = null,
    Object? connectedAt = null,
    Object? lastSeen = null,
  }) {
    return _then(
      _value.copyWith(
            userId:
                null == userId
                    ? _value.userId
                    : userId // ignore: cast_nullable_to_non_nullable
                        as String,
            email:
                null == email
                    ? _value.email
                    : email // ignore: cast_nullable_to_non_nullable
                        as String,
            role:
                null == role
                    ? _value.role
                    : role // ignore: cast_nullable_to_non_nullable
                        as String,
            connectedAt:
                null == connectedAt
                    ? _value.connectedAt
                    : connectedAt // ignore: cast_nullable_to_non_nullable
                        as String,
            lastSeen:
                null == lastSeen
                    ? _value.lastSeen
                    : lastSeen // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PresenceUserImplCopyWith<$Res>
    implements $PresenceUserCopyWith<$Res> {
  factory _$$PresenceUserImplCopyWith(
    _$PresenceUserImpl value,
    $Res Function(_$PresenceUserImpl) then,
  ) = __$$PresenceUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String email,
    String role,
    String connectedAt,
    String lastSeen,
  });
}

/// @nodoc
class __$$PresenceUserImplCopyWithImpl<$Res>
    extends _$PresenceUserCopyWithImpl<$Res, _$PresenceUserImpl>
    implements _$$PresenceUserImplCopyWith<$Res> {
  __$$PresenceUserImplCopyWithImpl(
    _$PresenceUserImpl _value,
    $Res Function(_$PresenceUserImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PresenceUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? email = null,
    Object? role = null,
    Object? connectedAt = null,
    Object? lastSeen = null,
  }) {
    return _then(
      _$PresenceUserImpl(
        userId:
            null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                    as String,
        email:
            null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                    as String,
        role:
            null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                    as String,
        connectedAt:
            null == connectedAt
                ? _value.connectedAt
                : connectedAt // ignore: cast_nullable_to_non_nullable
                    as String,
        lastSeen:
            null == lastSeen
                ? _value.lastSeen
                : lastSeen // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PresenceUserImpl implements _PresenceUser {
  const _$PresenceUserImpl({
    required this.userId,
    required this.email,
    required this.role,
    required this.connectedAt,
    required this.lastSeen,
  });

  factory _$PresenceUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$PresenceUserImplFromJson(json);

  @override
  final String userId;
  @override
  final String email;
  @override
  final String role;
  @override
  final String connectedAt;
  @override
  final String lastSeen;

  @override
  String toString() {
    return 'PresenceUser(userId: $userId, email: $email, role: $role, connectedAt: $connectedAt, lastSeen: $lastSeen)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PresenceUserImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.connectedAt, connectedAt) ||
                other.connectedAt == connectedAt) &&
            (identical(other.lastSeen, lastSeen) ||
                other.lastSeen == lastSeen));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, userId, email, role, connectedAt, lastSeen);

  /// Create a copy of PresenceUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PresenceUserImplCopyWith<_$PresenceUserImpl> get copyWith =>
      __$$PresenceUserImplCopyWithImpl<_$PresenceUserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PresenceUserImplToJson(this);
  }
}

abstract class _PresenceUser implements PresenceUser {
  const factory _PresenceUser({
    required final String userId,
    required final String email,
    required final String role,
    required final String connectedAt,
    required final String lastSeen,
  }) = _$PresenceUserImpl;

  factory _PresenceUser.fromJson(Map<String, dynamic> json) =
      _$PresenceUserImpl.fromJson;

  @override
  String get userId;
  @override
  String get email;
  @override
  String get role;
  @override
  String get connectedAt;
  @override
  String get lastSeen;

  /// Create a copy of PresenceUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PresenceUserImplCopyWith<_$PresenceUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
