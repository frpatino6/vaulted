// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dry_cleaning_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DryCleaningModel _$DryCleaningModelFromJson(Map<String, dynamic> json) {
  return _DryCleaningModel.fromJson(json);
}

/// @nodoc
mixin _$DryCleaningModel {
  String get id => throw _privateConstructorUsedError;
  String get itemId => throw _privateConstructorUsedError;
  DateTime get sentDate => throw _privateConstructorUsedError;
  DateTime? get returnedDate => throw _privateConstructorUsedError;
  String? get cleanerName => throw _privateConstructorUsedError;
  double? get cost => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this DryCleaningModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DryCleaningModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DryCleaningModelCopyWith<DryCleaningModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DryCleaningModelCopyWith<$Res> {
  factory $DryCleaningModelCopyWith(
    DryCleaningModel value,
    $Res Function(DryCleaningModel) then,
  ) = _$DryCleaningModelCopyWithImpl<$Res, DryCleaningModel>;
  @useResult
  $Res call({
    String id,
    String itemId,
    DateTime sentDate,
    DateTime? returnedDate,
    String? cleanerName,
    double? cost,
    String currency,
    String? notes,
    String? createdAt,
  });
}

/// @nodoc
class _$DryCleaningModelCopyWithImpl<$Res, $Val extends DryCleaningModel>
    implements $DryCleaningModelCopyWith<$Res> {
  _$DryCleaningModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DryCleaningModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? itemId = null,
    Object? sentDate = null,
    Object? returnedDate = freezed,
    Object? cleanerName = freezed,
    Object? cost = freezed,
    Object? currency = null,
    Object? notes = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            itemId:
                null == itemId
                    ? _value.itemId
                    : itemId // ignore: cast_nullable_to_non_nullable
                        as String,
            sentDate:
                null == sentDate
                    ? _value.sentDate
                    : sentDate // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            returnedDate:
                freezed == returnedDate
                    ? _value.returnedDate
                    : returnedDate // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            cleanerName:
                freezed == cleanerName
                    ? _value.cleanerName
                    : cleanerName // ignore: cast_nullable_to_non_nullable
                        as String?,
            cost:
                freezed == cost
                    ? _value.cost
                    : cost // ignore: cast_nullable_to_non_nullable
                        as double?,
            currency:
                null == currency
                    ? _value.currency
                    : currency // ignore: cast_nullable_to_non_nullable
                        as String,
            notes:
                freezed == notes
                    ? _value.notes
                    : notes // ignore: cast_nullable_to_non_nullable
                        as String?,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DryCleaningModelImplCopyWith<$Res>
    implements $DryCleaningModelCopyWith<$Res> {
  factory _$$DryCleaningModelImplCopyWith(
    _$DryCleaningModelImpl value,
    $Res Function(_$DryCleaningModelImpl) then,
  ) = __$$DryCleaningModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String itemId,
    DateTime sentDate,
    DateTime? returnedDate,
    String? cleanerName,
    double? cost,
    String currency,
    String? notes,
    String? createdAt,
  });
}

/// @nodoc
class __$$DryCleaningModelImplCopyWithImpl<$Res>
    extends _$DryCleaningModelCopyWithImpl<$Res, _$DryCleaningModelImpl>
    implements _$$DryCleaningModelImplCopyWith<$Res> {
  __$$DryCleaningModelImplCopyWithImpl(
    _$DryCleaningModelImpl _value,
    $Res Function(_$DryCleaningModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DryCleaningModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? itemId = null,
    Object? sentDate = null,
    Object? returnedDate = freezed,
    Object? cleanerName = freezed,
    Object? cost = freezed,
    Object? currency = null,
    Object? notes = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$DryCleaningModelImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        itemId:
            null == itemId
                ? _value.itemId
                : itemId // ignore: cast_nullable_to_non_nullable
                    as String,
        sentDate:
            null == sentDate
                ? _value.sentDate
                : sentDate // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        returnedDate:
            freezed == returnedDate
                ? _value.returnedDate
                : returnedDate // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        cleanerName:
            freezed == cleanerName
                ? _value.cleanerName
                : cleanerName // ignore: cast_nullable_to_non_nullable
                    as String?,
        cost:
            freezed == cost
                ? _value.cost
                : cost // ignore: cast_nullable_to_non_nullable
                    as double?,
        currency:
            null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                    as String,
        notes:
            freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                    as String?,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DryCleaningModelImpl implements _DryCleaningModel {
  const _$DryCleaningModelImpl({
    required this.id,
    required this.itemId,
    required this.sentDate,
    this.returnedDate,
    this.cleanerName,
    this.cost,
    this.currency = 'USD',
    this.notes,
    this.createdAt,
  });

  factory _$DryCleaningModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DryCleaningModelImplFromJson(json);

  @override
  final String id;
  @override
  final String itemId;
  @override
  final DateTime sentDate;
  @override
  final DateTime? returnedDate;
  @override
  final String? cleanerName;
  @override
  final double? cost;
  @override
  @JsonKey()
  final String currency;
  @override
  final String? notes;
  @override
  final String? createdAt;

  @override
  String toString() {
    return 'DryCleaningModel(id: $id, itemId: $itemId, sentDate: $sentDate, returnedDate: $returnedDate, cleanerName: $cleanerName, cost: $cost, currency: $currency, notes: $notes, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DryCleaningModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.sentDate, sentDate) ||
                other.sentDate == sentDate) &&
            (identical(other.returnedDate, returnedDate) ||
                other.returnedDate == returnedDate) &&
            (identical(other.cleanerName, cleanerName) ||
                other.cleanerName == cleanerName) &&
            (identical(other.cost, cost) || other.cost == cost) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    itemId,
    sentDate,
    returnedDate,
    cleanerName,
    cost,
    currency,
    notes,
    createdAt,
  );

  /// Create a copy of DryCleaningModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DryCleaningModelImplCopyWith<_$DryCleaningModelImpl> get copyWith =>
      __$$DryCleaningModelImplCopyWithImpl<_$DryCleaningModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DryCleaningModelImplToJson(this);
  }
}

abstract class _DryCleaningModel implements DryCleaningModel {
  const factory _DryCleaningModel({
    required final String id,
    required final String itemId,
    required final DateTime sentDate,
    final DateTime? returnedDate,
    final String? cleanerName,
    final double? cost,
    final String currency,
    final String? notes,
    final String? createdAt,
  }) = _$DryCleaningModelImpl;

  factory _DryCleaningModel.fromJson(Map<String, dynamic> json) =
      _$DryCleaningModelImpl.fromJson;

  @override
  String get id;
  @override
  String get itemId;
  @override
  DateTime get sentDate;
  @override
  DateTime? get returnedDate;
  @override
  String? get cleanerName;
  @override
  double? get cost;
  @override
  String get currency;
  @override
  String? get notes;
  @override
  String? get createdAt;

  /// Create a copy of DryCleaningModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DryCleaningModelImplCopyWith<_$DryCleaningModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
