// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'movement_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MovementItemModel _$MovementItemModelFromJson(Map<String, dynamic> json) {
  return _MovementItemModel.fromJson(json);
}

/// @nodoc
mixin _$MovementItemModel {
  String get itemId => throw _privateConstructorUsedError;
  String get itemName => throw _privateConstructorUsedError;
  String get itemCategory => throw _privateConstructorUsedError;
  String get itemPhoto => throw _privateConstructorUsedError;
  String get fromPropertyId => throw _privateConstructorUsedError;
  String get fromRoomId => throw _privateConstructorUsedError;
  String get fromPropertyName => throw _privateConstructorUsedError;
  String get fromRoomName => throw _privateConstructorUsedError;
  String? get scannedAt => throw _privateConstructorUsedError;
  String? get checkedInAt => throw _privateConstructorUsedError;
  String? get checkedInBy => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  /// Serializes this MovementItemModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MovementItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MovementItemModelCopyWith<MovementItemModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MovementItemModelCopyWith<$Res> {
  factory $MovementItemModelCopyWith(
    MovementItemModel value,
    $Res Function(MovementItemModel) then,
  ) = _$MovementItemModelCopyWithImpl<$Res, MovementItemModel>;
  @useResult
  $Res call({
    String itemId,
    String itemName,
    String itemCategory,
    String itemPhoto,
    String fromPropertyId,
    String fromRoomId,
    String fromPropertyName,
    String fromRoomName,
    String? scannedAt,
    String? checkedInAt,
    String? checkedInBy,
    String status,
  });
}

/// @nodoc
class _$MovementItemModelCopyWithImpl<$Res, $Val extends MovementItemModel>
    implements $MovementItemModelCopyWith<$Res> {
  _$MovementItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MovementItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? itemName = null,
    Object? itemCategory = null,
    Object? itemPhoto = null,
    Object? fromPropertyId = null,
    Object? fromRoomId = null,
    Object? fromPropertyName = null,
    Object? fromRoomName = null,
    Object? scannedAt = freezed,
    Object? checkedInAt = freezed,
    Object? checkedInBy = freezed,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            itemId:
                null == itemId
                    ? _value.itemId
                    : itemId // ignore: cast_nullable_to_non_nullable
                        as String,
            itemName:
                null == itemName
                    ? _value.itemName
                    : itemName // ignore: cast_nullable_to_non_nullable
                        as String,
            itemCategory:
                null == itemCategory
                    ? _value.itemCategory
                    : itemCategory // ignore: cast_nullable_to_non_nullable
                        as String,
            itemPhoto:
                null == itemPhoto
                    ? _value.itemPhoto
                    : itemPhoto // ignore: cast_nullable_to_non_nullable
                        as String,
            fromPropertyId:
                null == fromPropertyId
                    ? _value.fromPropertyId
                    : fromPropertyId // ignore: cast_nullable_to_non_nullable
                        as String,
            fromRoomId:
                null == fromRoomId
                    ? _value.fromRoomId
                    : fromRoomId // ignore: cast_nullable_to_non_nullable
                        as String,
            fromPropertyName:
                null == fromPropertyName
                    ? _value.fromPropertyName
                    : fromPropertyName // ignore: cast_nullable_to_non_nullable
                        as String,
            fromRoomName:
                null == fromRoomName
                    ? _value.fromRoomName
                    : fromRoomName // ignore: cast_nullable_to_non_nullable
                        as String,
            scannedAt:
                freezed == scannedAt
                    ? _value.scannedAt
                    : scannedAt // ignore: cast_nullable_to_non_nullable
                        as String?,
            checkedInAt:
                freezed == checkedInAt
                    ? _value.checkedInAt
                    : checkedInAt // ignore: cast_nullable_to_non_nullable
                        as String?,
            checkedInBy:
                freezed == checkedInBy
                    ? _value.checkedInBy
                    : checkedInBy // ignore: cast_nullable_to_non_nullable
                        as String?,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MovementItemModelImplCopyWith<$Res>
    implements $MovementItemModelCopyWith<$Res> {
  factory _$$MovementItemModelImplCopyWith(
    _$MovementItemModelImpl value,
    $Res Function(_$MovementItemModelImpl) then,
  ) = __$$MovementItemModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String itemId,
    String itemName,
    String itemCategory,
    String itemPhoto,
    String fromPropertyId,
    String fromRoomId,
    String fromPropertyName,
    String fromRoomName,
    String? scannedAt,
    String? checkedInAt,
    String? checkedInBy,
    String status,
  });
}

/// @nodoc
class __$$MovementItemModelImplCopyWithImpl<$Res>
    extends _$MovementItemModelCopyWithImpl<$Res, _$MovementItemModelImpl>
    implements _$$MovementItemModelImplCopyWith<$Res> {
  __$$MovementItemModelImplCopyWithImpl(
    _$MovementItemModelImpl _value,
    $Res Function(_$MovementItemModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MovementItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? itemName = null,
    Object? itemCategory = null,
    Object? itemPhoto = null,
    Object? fromPropertyId = null,
    Object? fromRoomId = null,
    Object? fromPropertyName = null,
    Object? fromRoomName = null,
    Object? scannedAt = freezed,
    Object? checkedInAt = freezed,
    Object? checkedInBy = freezed,
    Object? status = null,
  }) {
    return _then(
      _$MovementItemModelImpl(
        itemId:
            null == itemId
                ? _value.itemId
                : itemId // ignore: cast_nullable_to_non_nullable
                    as String,
        itemName:
            null == itemName
                ? _value.itemName
                : itemName // ignore: cast_nullable_to_non_nullable
                    as String,
        itemCategory:
            null == itemCategory
                ? _value.itemCategory
                : itemCategory // ignore: cast_nullable_to_non_nullable
                    as String,
        itemPhoto:
            null == itemPhoto
                ? _value.itemPhoto
                : itemPhoto // ignore: cast_nullable_to_non_nullable
                    as String,
        fromPropertyId:
            null == fromPropertyId
                ? _value.fromPropertyId
                : fromPropertyId // ignore: cast_nullable_to_non_nullable
                    as String,
        fromRoomId:
            null == fromRoomId
                ? _value.fromRoomId
                : fromRoomId // ignore: cast_nullable_to_non_nullable
                    as String,
        fromPropertyName:
            null == fromPropertyName
                ? _value.fromPropertyName
                : fromPropertyName // ignore: cast_nullable_to_non_nullable
                    as String,
        fromRoomName:
            null == fromRoomName
                ? _value.fromRoomName
                : fromRoomName // ignore: cast_nullable_to_non_nullable
                    as String,
        scannedAt:
            freezed == scannedAt
                ? _value.scannedAt
                : scannedAt // ignore: cast_nullable_to_non_nullable
                    as String?,
        checkedInAt:
            freezed == checkedInAt
                ? _value.checkedInAt
                : checkedInAt // ignore: cast_nullable_to_non_nullable
                    as String?,
        checkedInBy:
            freezed == checkedInBy
                ? _value.checkedInBy
                : checkedInBy // ignore: cast_nullable_to_non_nullable
                    as String?,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MovementItemModelImpl implements _MovementItemModel {
  const _$MovementItemModelImpl({
    required this.itemId,
    required this.itemName,
    this.itemCategory = '',
    this.itemPhoto = '',
    this.fromPropertyId = '',
    this.fromRoomId = '',
    this.fromPropertyName = '',
    this.fromRoomName = '',
    this.scannedAt,
    this.checkedInAt,
    this.checkedInBy,
    this.status = 'out',
  });

  factory _$MovementItemModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MovementItemModelImplFromJson(json);

  @override
  final String itemId;
  @override
  final String itemName;
  @override
  @JsonKey()
  final String itemCategory;
  @override
  @JsonKey()
  final String itemPhoto;
  @override
  @JsonKey()
  final String fromPropertyId;
  @override
  @JsonKey()
  final String fromRoomId;
  @override
  @JsonKey()
  final String fromPropertyName;
  @override
  @JsonKey()
  final String fromRoomName;
  @override
  final String? scannedAt;
  @override
  final String? checkedInAt;
  @override
  final String? checkedInBy;
  @override
  @JsonKey()
  final String status;

  @override
  String toString() {
    return 'MovementItemModel(itemId: $itemId, itemName: $itemName, itemCategory: $itemCategory, itemPhoto: $itemPhoto, fromPropertyId: $fromPropertyId, fromRoomId: $fromRoomId, fromPropertyName: $fromPropertyName, fromRoomName: $fromRoomName, scannedAt: $scannedAt, checkedInAt: $checkedInAt, checkedInBy: $checkedInBy, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MovementItemModelImpl &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.itemCategory, itemCategory) ||
                other.itemCategory == itemCategory) &&
            (identical(other.itemPhoto, itemPhoto) ||
                other.itemPhoto == itemPhoto) &&
            (identical(other.fromPropertyId, fromPropertyId) ||
                other.fromPropertyId == fromPropertyId) &&
            (identical(other.fromRoomId, fromRoomId) ||
                other.fromRoomId == fromRoomId) &&
            (identical(other.fromPropertyName, fromPropertyName) ||
                other.fromPropertyName == fromPropertyName) &&
            (identical(other.fromRoomName, fromRoomName) ||
                other.fromRoomName == fromRoomName) &&
            (identical(other.scannedAt, scannedAt) ||
                other.scannedAt == scannedAt) &&
            (identical(other.checkedInAt, checkedInAt) ||
                other.checkedInAt == checkedInAt) &&
            (identical(other.checkedInBy, checkedInBy) ||
                other.checkedInBy == checkedInBy) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    itemId,
    itemName,
    itemCategory,
    itemPhoto,
    fromPropertyId,
    fromRoomId,
    fromPropertyName,
    fromRoomName,
    scannedAt,
    checkedInAt,
    checkedInBy,
    status,
  );

  /// Create a copy of MovementItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MovementItemModelImplCopyWith<_$MovementItemModelImpl> get copyWith =>
      __$$MovementItemModelImplCopyWithImpl<_$MovementItemModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MovementItemModelImplToJson(this);
  }
}

abstract class _MovementItemModel implements MovementItemModel {
  const factory _MovementItemModel({
    required final String itemId,
    required final String itemName,
    final String itemCategory,
    final String itemPhoto,
    final String fromPropertyId,
    final String fromRoomId,
    final String fromPropertyName,
    final String fromRoomName,
    final String? scannedAt,
    final String? checkedInAt,
    final String? checkedInBy,
    final String status,
  }) = _$MovementItemModelImpl;

  factory _MovementItemModel.fromJson(Map<String, dynamic> json) =
      _$MovementItemModelImpl.fromJson;

  @override
  String get itemId;
  @override
  String get itemName;
  @override
  String get itemCategory;
  @override
  String get itemPhoto;
  @override
  String get fromPropertyId;
  @override
  String get fromRoomId;
  @override
  String get fromPropertyName;
  @override
  String get fromRoomName;
  @override
  String? get scannedAt;
  @override
  String? get checkedInAt;
  @override
  String? get checkedInBy;
  @override
  String get status;

  /// Create a copy of MovementItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MovementItemModelImplCopyWith<_$MovementItemModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MovementModel _$MovementModelFromJson(Map<String, dynamic> json) {
  return _MovementModel.fromJson(json);
}

/// @nodoc
mixin _$MovementModel {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get operationType => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get destination => throw _privateConstructorUsedError;
  String get destinationPropertyId => throw _privateConstructorUsedError;
  String get destinationRoomId => throw _privateConstructorUsedError;
  String get destinationPropertyName => throw _privateConstructorUsedError;
  String get destinationRoomName => throw _privateConstructorUsedError;
  List<MovementItemModel> get items => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  String get propertyId => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;
  String? get updatedAt => throw _privateConstructorUsedError;
  String? get activatedAt => throw _privateConstructorUsedError;
  String? get completedAt => throw _privateConstructorUsedError;
  String? get dueDate => throw _privateConstructorUsedError;
  String get notes => throw _privateConstructorUsedError;

  /// Serializes this MovementModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MovementModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MovementModelCopyWith<MovementModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MovementModelCopyWith<$Res> {
  factory $MovementModelCopyWith(
    MovementModel value,
    $Res Function(MovementModel) then,
  ) = _$MovementModelCopyWithImpl<$Res, MovementModel>;
  @useResult
  $Res call({
    String id,
    String tenantId,
    String operationType,
    String status,
    String title,
    String description,
    String destination,
    String destinationPropertyId,
    String destinationRoomId,
    String destinationPropertyName,
    String destinationRoomName,
    List<MovementItemModel> items,
    String createdBy,
    String propertyId,
    String? createdAt,
    String? updatedAt,
    String? activatedAt,
    String? completedAt,
    String? dueDate,
    String notes,
  });
}

/// @nodoc
class _$MovementModelCopyWithImpl<$Res, $Val extends MovementModel>
    implements $MovementModelCopyWith<$Res> {
  _$MovementModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MovementModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? operationType = null,
    Object? status = null,
    Object? title = null,
    Object? description = null,
    Object? destination = null,
    Object? destinationPropertyId = null,
    Object? destinationRoomId = null,
    Object? destinationPropertyName = null,
    Object? destinationRoomName = null,
    Object? items = null,
    Object? createdBy = null,
    Object? propertyId = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? activatedAt = freezed,
    Object? completedAt = freezed,
    Object? dueDate = freezed,
    Object? notes = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            tenantId:
                null == tenantId
                    ? _value.tenantId
                    : tenantId // ignore: cast_nullable_to_non_nullable
                        as String,
            operationType:
                null == operationType
                    ? _value.operationType
                    : operationType // ignore: cast_nullable_to_non_nullable
                        as String,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            description:
                null == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String,
            destination:
                null == destination
                    ? _value.destination
                    : destination // ignore: cast_nullable_to_non_nullable
                        as String,
            destinationPropertyId:
                null == destinationPropertyId
                    ? _value.destinationPropertyId
                    : destinationPropertyId // ignore: cast_nullable_to_non_nullable
                        as String,
            destinationRoomId:
                null == destinationRoomId
                    ? _value.destinationRoomId
                    : destinationRoomId // ignore: cast_nullable_to_non_nullable
                        as String,
            destinationPropertyName:
                null == destinationPropertyName
                    ? _value.destinationPropertyName
                    : destinationPropertyName // ignore: cast_nullable_to_non_nullable
                        as String,
            destinationRoomName:
                null == destinationRoomName
                    ? _value.destinationRoomName
                    : destinationRoomName // ignore: cast_nullable_to_non_nullable
                        as String,
            items:
                null == items
                    ? _value.items
                    : items // ignore: cast_nullable_to_non_nullable
                        as List<MovementItemModel>,
            createdBy:
                null == createdBy
                    ? _value.createdBy
                    : createdBy // ignore: cast_nullable_to_non_nullable
                        as String,
            propertyId:
                null == propertyId
                    ? _value.propertyId
                    : propertyId // ignore: cast_nullable_to_non_nullable
                        as String,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as String?,
            updatedAt:
                freezed == updatedAt
                    ? _value.updatedAt
                    : updatedAt // ignore: cast_nullable_to_non_nullable
                        as String?,
            activatedAt:
                freezed == activatedAt
                    ? _value.activatedAt
                    : activatedAt // ignore: cast_nullable_to_non_nullable
                        as String?,
            completedAt:
                freezed == completedAt
                    ? _value.completedAt
                    : completedAt // ignore: cast_nullable_to_non_nullable
                        as String?,
            dueDate:
                freezed == dueDate
                    ? _value.dueDate
                    : dueDate // ignore: cast_nullable_to_non_nullable
                        as String?,
            notes:
                null == notes
                    ? _value.notes
                    : notes // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MovementModelImplCopyWith<$Res>
    implements $MovementModelCopyWith<$Res> {
  factory _$$MovementModelImplCopyWith(
    _$MovementModelImpl value,
    $Res Function(_$MovementModelImpl) then,
  ) = __$$MovementModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String tenantId,
    String operationType,
    String status,
    String title,
    String description,
    String destination,
    String destinationPropertyId,
    String destinationRoomId,
    String destinationPropertyName,
    String destinationRoomName,
    List<MovementItemModel> items,
    String createdBy,
    String propertyId,
    String? createdAt,
    String? updatedAt,
    String? activatedAt,
    String? completedAt,
    String? dueDate,
    String notes,
  });
}

/// @nodoc
class __$$MovementModelImplCopyWithImpl<$Res>
    extends _$MovementModelCopyWithImpl<$Res, _$MovementModelImpl>
    implements _$$MovementModelImplCopyWith<$Res> {
  __$$MovementModelImplCopyWithImpl(
    _$MovementModelImpl _value,
    $Res Function(_$MovementModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MovementModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? operationType = null,
    Object? status = null,
    Object? title = null,
    Object? description = null,
    Object? destination = null,
    Object? destinationPropertyId = null,
    Object? destinationRoomId = null,
    Object? destinationPropertyName = null,
    Object? destinationRoomName = null,
    Object? items = null,
    Object? createdBy = null,
    Object? propertyId = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? activatedAt = freezed,
    Object? completedAt = freezed,
    Object? dueDate = freezed,
    Object? notes = null,
  }) {
    return _then(
      _$MovementModelImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        tenantId:
            null == tenantId
                ? _value.tenantId
                : tenantId // ignore: cast_nullable_to_non_nullable
                    as String,
        operationType:
            null == operationType
                ? _value.operationType
                : operationType // ignore: cast_nullable_to_non_nullable
                    as String,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        description:
            null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String,
        destination:
            null == destination
                ? _value.destination
                : destination // ignore: cast_nullable_to_non_nullable
                    as String,
        destinationPropertyId:
            null == destinationPropertyId
                ? _value.destinationPropertyId
                : destinationPropertyId // ignore: cast_nullable_to_non_nullable
                    as String,
        destinationRoomId:
            null == destinationRoomId
                ? _value.destinationRoomId
                : destinationRoomId // ignore: cast_nullable_to_non_nullable
                    as String,
        destinationPropertyName:
            null == destinationPropertyName
                ? _value.destinationPropertyName
                : destinationPropertyName // ignore: cast_nullable_to_non_nullable
                    as String,
        destinationRoomName:
            null == destinationRoomName
                ? _value.destinationRoomName
                : destinationRoomName // ignore: cast_nullable_to_non_nullable
                    as String,
        items:
            null == items
                ? _value._items
                : items // ignore: cast_nullable_to_non_nullable
                    as List<MovementItemModel>,
        createdBy:
            null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                    as String,
        propertyId:
            null == propertyId
                ? _value.propertyId
                : propertyId // ignore: cast_nullable_to_non_nullable
                    as String,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as String?,
        updatedAt:
            freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                    as String?,
        activatedAt:
            freezed == activatedAt
                ? _value.activatedAt
                : activatedAt // ignore: cast_nullable_to_non_nullable
                    as String?,
        completedAt:
            freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                    as String?,
        dueDate:
            freezed == dueDate
                ? _value.dueDate
                : dueDate // ignore: cast_nullable_to_non_nullable
                    as String?,
        notes:
            null == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MovementModelImpl implements _MovementModel {
  const _$MovementModelImpl({
    required this.id,
    required this.tenantId,
    required this.operationType,
    required this.status,
    required this.title,
    this.description = '',
    this.destination = '',
    this.destinationPropertyId = '',
    this.destinationRoomId = '',
    this.destinationPropertyName = '',
    this.destinationRoomName = '',
    final List<MovementItemModel> items = const [],
    required this.createdBy,
    this.propertyId = '',
    this.createdAt,
    this.updatedAt,
    this.activatedAt,
    this.completedAt,
    this.dueDate,
    this.notes = '',
  }) : _items = items;

  factory _$MovementModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MovementModelImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String operationType;
  @override
  final String status;
  @override
  final String title;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey()
  final String destination;
  @override
  @JsonKey()
  final String destinationPropertyId;
  @override
  @JsonKey()
  final String destinationRoomId;
  @override
  @JsonKey()
  final String destinationPropertyName;
  @override
  @JsonKey()
  final String destinationRoomName;
  final List<MovementItemModel> _items;
  @override
  @JsonKey()
  List<MovementItemModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final String createdBy;
  @override
  @JsonKey()
  final String propertyId;
  @override
  final String? createdAt;
  @override
  final String? updatedAt;
  @override
  final String? activatedAt;
  @override
  final String? completedAt;
  @override
  final String? dueDate;
  @override
  @JsonKey()
  final String notes;

  @override
  String toString() {
    return 'MovementModel(id: $id, tenantId: $tenantId, operationType: $operationType, status: $status, title: $title, description: $description, destination: $destination, destinationPropertyId: $destinationPropertyId, destinationRoomId: $destinationRoomId, destinationPropertyName: $destinationPropertyName, destinationRoomName: $destinationRoomName, items: $items, createdBy: $createdBy, propertyId: $propertyId, createdAt: $createdAt, updatedAt: $updatedAt, activatedAt: $activatedAt, completedAt: $completedAt, dueDate: $dueDate, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MovementModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.operationType, operationType) ||
                other.operationType == operationType) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.destination, destination) ||
                other.destination == destination) &&
            (identical(other.destinationPropertyId, destinationPropertyId) ||
                other.destinationPropertyId == destinationPropertyId) &&
            (identical(other.destinationRoomId, destinationRoomId) ||
                other.destinationRoomId == destinationRoomId) &&
            (identical(
                  other.destinationPropertyName,
                  destinationPropertyName,
                ) ||
                other.destinationPropertyName == destinationPropertyName) &&
            (identical(other.destinationRoomName, destinationRoomName) ||
                other.destinationRoomName == destinationRoomName) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.propertyId, propertyId) ||
                other.propertyId == propertyId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.activatedAt, activatedAt) ||
                other.activatedAt == activatedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    tenantId,
    operationType,
    status,
    title,
    description,
    destination,
    destinationPropertyId,
    destinationRoomId,
    destinationPropertyName,
    destinationRoomName,
    const DeepCollectionEquality().hash(_items),
    createdBy,
    propertyId,
    createdAt,
    updatedAt,
    activatedAt,
    completedAt,
    dueDate,
    notes,
  ]);

  /// Create a copy of MovementModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MovementModelImplCopyWith<_$MovementModelImpl> get copyWith =>
      __$$MovementModelImplCopyWithImpl<_$MovementModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MovementModelImplToJson(this);
  }
}

abstract class _MovementModel implements MovementModel {
  const factory _MovementModel({
    required final String id,
    required final String tenantId,
    required final String operationType,
    required final String status,
    required final String title,
    final String description,
    final String destination,
    final String destinationPropertyId,
    final String destinationRoomId,
    final String destinationPropertyName,
    final String destinationRoomName,
    final List<MovementItemModel> items,
    required final String createdBy,
    final String propertyId,
    final String? createdAt,
    final String? updatedAt,
    final String? activatedAt,
    final String? completedAt,
    final String? dueDate,
    final String notes,
  }) = _$MovementModelImpl;

  factory _MovementModel.fromJson(Map<String, dynamic> json) =
      _$MovementModelImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String get operationType;
  @override
  String get status;
  @override
  String get title;
  @override
  String get description;
  @override
  String get destination;
  @override
  String get destinationPropertyId;
  @override
  String get destinationRoomId;
  @override
  String get destinationPropertyName;
  @override
  String get destinationRoomName;
  @override
  List<MovementItemModel> get items;
  @override
  String get createdBy;
  @override
  String get propertyId;
  @override
  String? get createdAt;
  @override
  String? get updatedAt;
  @override
  String? get activatedAt;
  @override
  String? get completedAt;
  @override
  String? get dueDate;
  @override
  String get notes;

  /// Create a copy of MovementModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MovementModelImplCopyWith<_$MovementModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
