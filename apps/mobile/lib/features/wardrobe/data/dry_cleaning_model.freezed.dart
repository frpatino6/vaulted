// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_annotation_target, unnecessary_question_mark

part of 'dry_cleaning_model.dart';

// ***************************************************************************
// FreezedGenerator
// ***************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.',
);

DryCleaningModel _$DryCleaningModelFromJson(Map<String, dynamic> json) {
  return _DryCleaningModel.fromJson(json);
}

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

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  @JsonKey(includeFromJson: false, includeToJson: false)
  $DryCleaningModelCopyWith<DryCleaningModel> get copyWith =>
      throw _privateConstructorUsedError;
}

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

class _$DryCleaningModelCopyWithImpl<$Res, $Val extends DryCleaningModel>
    implements $DryCleaningModelCopyWith<$Res> {
  _$DryCleaningModelCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

  @override
  @pragma('vm:prefer-inline')
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
            id: null == id ? _value.id : id as String,
            itemId: null == itemId ? _value.itemId : itemId as String,
            sentDate: null == sentDate ? _value.sentDate : sentDate as DateTime,
            returnedDate: freezed == returnedDate
                ? _value.returnedDate
                : returnedDate as DateTime?,
            cleanerName: freezed == cleanerName
                ? _value.cleanerName
                : cleanerName as String?,
            cost: freezed == cost ? _value.cost : cost as double?,
            currency: null == currency ? _value.currency : currency as String,
            notes: freezed == notes ? _value.notes : notes as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt as String?,
          )
          as $Val,
    );
  }
}

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

class __$$DryCleaningModelImplCopyWithImpl<$Res>
    extends _$DryCleaningModelCopyWithImpl<$Res, _$DryCleaningModelImpl>
    implements _$$DryCleaningModelImplCopyWith<$Res> {
  __$$DryCleaningModelImplCopyWithImpl(
    _$DryCleaningModelImpl _value,
    $Res Function(_$DryCleaningModelImpl) _then,
  ) : super(_value, _then);

  @override
  @pragma('vm:prefer-inline')
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
        id: null == id ? _value.id : id as String,
        itemId: null == itemId ? _value.itemId : itemId as String,
        sentDate: null == sentDate ? _value.sentDate : sentDate as DateTime,
        returnedDate: freezed == returnedDate
            ? _value.returnedDate
            : returnedDate as DateTime?,
        cleanerName: freezed == cleanerName
            ? _value.cleanerName
            : cleanerName as String?,
        cost: freezed == cost ? _value.cost : cost as double?,
        currency: null == currency ? _value.currency : currency as String,
        notes: freezed == notes ? _value.notes : notes as String?,
        createdAt: freezed == createdAt ? _value.createdAt : createdAt as String?,
      ),
    );
  }
}

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
  Map<String, dynamic> toJson() {
    return _$$DryCleaningModelImplToJson(this);
  }

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$$DryCleaningModelImplCopyWith<_$DryCleaningModelImpl> get copyWith =>
      __$$DryCleaningModelImplCopyWithImpl(this, _$identity);
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

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DryCleaningModelImplCopyWith<_$DryCleaningModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
