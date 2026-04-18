// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_section_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RoomSectionModel _$RoomSectionModelFromJson(Map<String, dynamic> json) {
  return _RoomSectionModel.fromJson(json);
}

/// @nodoc
mixin _$RoomSectionModel {
  String get sectionId => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this RoomSectionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RoomSectionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoomSectionModelCopyWith<RoomSectionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoomSectionModelCopyWith<$Res> {
  factory $RoomSectionModelCopyWith(
    RoomSectionModel value,
    $Res Function(RoomSectionModel) then,
  ) = _$RoomSectionModelCopyWithImpl<$Res, RoomSectionModel>;
  @useResult
  $Res call({
    String sectionId,
    String code,
    String name,
    String type,
    String? notes,
  });
}

/// @nodoc
class _$RoomSectionModelCopyWithImpl<$Res, $Val extends RoomSectionModel>
    implements $RoomSectionModelCopyWith<$Res> {
  _$RoomSectionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RoomSectionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sectionId = null,
    Object? code = null,
    Object? name = null,
    Object? type = null,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            sectionId:
                null == sectionId
                    ? _value.sectionId
                    : sectionId // ignore: cast_nullable_to_non_nullable
                        as String,
            code:
                null == code
                    ? _value.code
                    : code // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            type:
                null == type
                    ? _value.type
                    : type // ignore: cast_nullable_to_non_nullable
                        as String,
            notes:
                freezed == notes
                    ? _value.notes
                    : notes // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RoomSectionModelImplCopyWith<$Res>
    implements $RoomSectionModelCopyWith<$Res> {
  factory _$$RoomSectionModelImplCopyWith(
    _$RoomSectionModelImpl value,
    $Res Function(_$RoomSectionModelImpl) then,
  ) = __$$RoomSectionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String sectionId,
    String code,
    String name,
    String type,
    String? notes,
  });
}

/// @nodoc
class __$$RoomSectionModelImplCopyWithImpl<$Res>
    extends _$RoomSectionModelCopyWithImpl<$Res, _$RoomSectionModelImpl>
    implements _$$RoomSectionModelImplCopyWith<$Res> {
  __$$RoomSectionModelImplCopyWithImpl(
    _$RoomSectionModelImpl _value,
    $Res Function(_$RoomSectionModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RoomSectionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sectionId = null,
    Object? code = null,
    Object? name = null,
    Object? type = null,
    Object? notes = freezed,
  }) {
    return _then(
      _$RoomSectionModelImpl(
        sectionId:
            null == sectionId
                ? _value.sectionId
                : sectionId // ignore: cast_nullable_to_non_nullable
                    as String,
        code:
            null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        type:
            null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as String,
        notes:
            freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RoomSectionModelImpl implements _RoomSectionModel {
  const _$RoomSectionModelImpl({
    required this.sectionId,
    required this.code,
    required this.name,
    required this.type,
    this.notes,
  });

  factory _$RoomSectionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoomSectionModelImplFromJson(json);

  @override
  final String sectionId;
  @override
  final String code;
  @override
  final String name;
  @override
  final String type;
  @override
  final String? notes;

  @override
  String toString() {
    return 'RoomSectionModel(sectionId: $sectionId, code: $code, name: $name, type: $type, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoomSectionModelImpl &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, sectionId, code, name, type, notes);

  /// Create a copy of RoomSectionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoomSectionModelImplCopyWith<_$RoomSectionModelImpl> get copyWith =>
      __$$RoomSectionModelImplCopyWithImpl<_$RoomSectionModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RoomSectionModelImplToJson(this);
  }
}

abstract class _RoomSectionModel implements RoomSectionModel {
  const factory _RoomSectionModel({
    required final String sectionId,
    required final String code,
    required final String name,
    required final String type,
    final String? notes,
  }) = _$RoomSectionModelImpl;

  factory _RoomSectionModel.fromJson(Map<String, dynamic> json) =
      _$RoomSectionModelImpl.fromJson;

  @override
  String get sectionId;
  @override
  String get code;
  @override
  String get name;
  @override
  String get type;
  @override
  String? get notes;

  /// Create a copy of RoomSectionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoomSectionModelImplCopyWith<_$RoomSectionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
