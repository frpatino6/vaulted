// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'insurance_policy_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

InsuredItemModel _$InsuredItemModelFromJson(Map<String, dynamic> json) {
  return _InsuredItemModel.fromJson(json);
}

/// @nodoc
mixin _$InsuredItemModel {
  String get id => throw _privateConstructorUsedError;
  String get policyId => throw _privateConstructorUsedError;
  String get itemId => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get coveredValue => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;
  String? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this InsuredItemModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InsuredItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InsuredItemModelCopyWith<InsuredItemModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InsuredItemModelCopyWith<$Res> {
  factory $InsuredItemModelCopyWith(
    InsuredItemModel value,
    $Res Function(InsuredItemModel) then,
  ) = _$InsuredItemModelCopyWithImpl<$Res, InsuredItemModel>;
  @useResult
  $Res call({
    String id,
    String policyId,
    String itemId,
    @JsonKey(fromJson: _parseDouble) double coveredValue,
    String currency,
    String? createdAt,
    String? updatedAt,
  });
}

/// @nodoc
class _$InsuredItemModelCopyWithImpl<$Res, $Val extends InsuredItemModel>
    implements $InsuredItemModelCopyWith<$Res> {
  _$InsuredItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InsuredItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? policyId = null,
    Object? itemId = null,
    Object? coveredValue = null,
    Object? currency = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            policyId:
                null == policyId
                    ? _value.policyId
                    : policyId // ignore: cast_nullable_to_non_nullable
                        as String,
            itemId:
                null == itemId
                    ? _value.itemId
                    : itemId // ignore: cast_nullable_to_non_nullable
                        as String,
            coveredValue:
                null == coveredValue
                    ? _value.coveredValue
                    : coveredValue // ignore: cast_nullable_to_non_nullable
                        as double,
            currency:
                null == currency
                    ? _value.currency
                    : currency // ignore: cast_nullable_to_non_nullable
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InsuredItemModelImplCopyWith<$Res>
    implements $InsuredItemModelCopyWith<$Res> {
  factory _$$InsuredItemModelImplCopyWith(
    _$InsuredItemModelImpl value,
    $Res Function(_$InsuredItemModelImpl) then,
  ) = __$$InsuredItemModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String policyId,
    String itemId,
    @JsonKey(fromJson: _parseDouble) double coveredValue,
    String currency,
    String? createdAt,
    String? updatedAt,
  });
}

/// @nodoc
class __$$InsuredItemModelImplCopyWithImpl<$Res>
    extends _$InsuredItemModelCopyWithImpl<$Res, _$InsuredItemModelImpl>
    implements _$$InsuredItemModelImplCopyWith<$Res> {
  __$$InsuredItemModelImplCopyWithImpl(
    _$InsuredItemModelImpl _value,
    $Res Function(_$InsuredItemModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InsuredItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? policyId = null,
    Object? itemId = null,
    Object? coveredValue = null,
    Object? currency = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$InsuredItemModelImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        policyId:
            null == policyId
                ? _value.policyId
                : policyId // ignore: cast_nullable_to_non_nullable
                    as String,
        itemId:
            null == itemId
                ? _value.itemId
                : itemId // ignore: cast_nullable_to_non_nullable
                    as String,
        coveredValue:
            null == coveredValue
                ? _value.coveredValue
                : coveredValue // ignore: cast_nullable_to_non_nullable
                    as double,
        currency:
            null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InsuredItemModelImpl implements _InsuredItemModel {
  const _$InsuredItemModelImpl({
    required this.id,
    required this.policyId,
    required this.itemId,
    @JsonKey(fromJson: _parseDouble) this.coveredValue = 0.0,
    this.currency = 'USD',
    this.createdAt,
    this.updatedAt,
  });

  factory _$InsuredItemModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$InsuredItemModelImplFromJson(json);

  @override
  final String id;
  @override
  final String policyId;
  @override
  final String itemId;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double coveredValue;
  @override
  @JsonKey()
  final String currency;
  @override
  final String? createdAt;
  @override
  final String? updatedAt;

  @override
  String toString() {
    return 'InsuredItemModel(id: $id, policyId: $policyId, itemId: $itemId, coveredValue: $coveredValue, currency: $currency, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InsuredItemModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.policyId, policyId) ||
                other.policyId == policyId) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.coveredValue, coveredValue) ||
                other.coveredValue == coveredValue) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    policyId,
    itemId,
    coveredValue,
    currency,
    createdAt,
    updatedAt,
  );

  /// Create a copy of InsuredItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InsuredItemModelImplCopyWith<_$InsuredItemModelImpl> get copyWith =>
      __$$InsuredItemModelImplCopyWithImpl<_$InsuredItemModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$InsuredItemModelImplToJson(this);
  }
}

abstract class _InsuredItemModel implements InsuredItemModel {
  const factory _InsuredItemModel({
    required final String id,
    required final String policyId,
    required final String itemId,
    @JsonKey(fromJson: _parseDouble) final double coveredValue,
    final String currency,
    final String? createdAt,
    final String? updatedAt,
  }) = _$InsuredItemModelImpl;

  factory _InsuredItemModel.fromJson(Map<String, dynamic> json) =
      _$InsuredItemModelImpl.fromJson;

  @override
  String get id;
  @override
  String get policyId;
  @override
  String get itemId;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get coveredValue;
  @override
  String get currency;
  @override
  String? get createdAt;
  @override
  String? get updatedAt;

  /// Create a copy of InsuredItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InsuredItemModelImplCopyWith<_$InsuredItemModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InsurancePolicyModel _$InsurancePolicyModelFromJson(Map<String, dynamic> json) {
  return _InsurancePolicyModel.fromJson(json);
}

/// @nodoc
mixin _$InsurancePolicyModel {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get provider => throw _privateConstructorUsedError;
  String get policyNumber => throw _privateConstructorUsedError;
  String get coverageType => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get totalCoverageAmount => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDoubleNullable)
  double? get premium => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String get startDate => throw _privateConstructorUsedError;
  String get expiresAt => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  List<InsuredItemModel> get insuredItems => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;
  String? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this InsurancePolicyModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InsurancePolicyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InsurancePolicyModelCopyWith<InsurancePolicyModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InsurancePolicyModelCopyWith<$Res> {
  factory $InsurancePolicyModelCopyWith(
    InsurancePolicyModel value,
    $Res Function(InsurancePolicyModel) then,
  ) = _$InsurancePolicyModelCopyWithImpl<$Res, InsurancePolicyModel>;
  @useResult
  $Res call({
    String id,
    String tenantId,
    String provider,
    String policyNumber,
    String coverageType,
    @JsonKey(fromJson: _parseDouble) double totalCoverageAmount,
    @JsonKey(fromJson: _parseDoubleNullable) double? premium,
    String currency,
    String startDate,
    String expiresAt,
    String status,
    String? notes,
    List<InsuredItemModel> insuredItems,
    String? createdAt,
    String? updatedAt,
  });
}

/// @nodoc
class _$InsurancePolicyModelCopyWithImpl<
  $Res,
  $Val extends InsurancePolicyModel
>
    implements $InsurancePolicyModelCopyWith<$Res> {
  _$InsurancePolicyModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InsurancePolicyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? provider = null,
    Object? policyNumber = null,
    Object? coverageType = null,
    Object? totalCoverageAmount = null,
    Object? premium = freezed,
    Object? currency = null,
    Object? startDate = null,
    Object? expiresAt = null,
    Object? status = null,
    Object? notes = freezed,
    Object? insuredItems = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
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
            provider:
                null == provider
                    ? _value.provider
                    : provider // ignore: cast_nullable_to_non_nullable
                        as String,
            policyNumber:
                null == policyNumber
                    ? _value.policyNumber
                    : policyNumber // ignore: cast_nullable_to_non_nullable
                        as String,
            coverageType:
                null == coverageType
                    ? _value.coverageType
                    : coverageType // ignore: cast_nullable_to_non_nullable
                        as String,
            totalCoverageAmount:
                null == totalCoverageAmount
                    ? _value.totalCoverageAmount
                    : totalCoverageAmount // ignore: cast_nullable_to_non_nullable
                        as double,
            premium:
                freezed == premium
                    ? _value.premium
                    : premium // ignore: cast_nullable_to_non_nullable
                        as double?,
            currency:
                null == currency
                    ? _value.currency
                    : currency // ignore: cast_nullable_to_non_nullable
                        as String,
            startDate:
                null == startDate
                    ? _value.startDate
                    : startDate // ignore: cast_nullable_to_non_nullable
                        as String,
            expiresAt:
                null == expiresAt
                    ? _value.expiresAt
                    : expiresAt // ignore: cast_nullable_to_non_nullable
                        as String,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            notes:
                freezed == notes
                    ? _value.notes
                    : notes // ignore: cast_nullable_to_non_nullable
                        as String?,
            insuredItems:
                null == insuredItems
                    ? _value.insuredItems
                    : insuredItems // ignore: cast_nullable_to_non_nullable
                        as List<InsuredItemModel>,
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InsurancePolicyModelImplCopyWith<$Res>
    implements $InsurancePolicyModelCopyWith<$Res> {
  factory _$$InsurancePolicyModelImplCopyWith(
    _$InsurancePolicyModelImpl value,
    $Res Function(_$InsurancePolicyModelImpl) then,
  ) = __$$InsurancePolicyModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String tenantId,
    String provider,
    String policyNumber,
    String coverageType,
    @JsonKey(fromJson: _parseDouble) double totalCoverageAmount,
    @JsonKey(fromJson: _parseDoubleNullable) double? premium,
    String currency,
    String startDate,
    String expiresAt,
    String status,
    String? notes,
    List<InsuredItemModel> insuredItems,
    String? createdAt,
    String? updatedAt,
  });
}

/// @nodoc
class __$$InsurancePolicyModelImplCopyWithImpl<$Res>
    extends _$InsurancePolicyModelCopyWithImpl<$Res, _$InsurancePolicyModelImpl>
    implements _$$InsurancePolicyModelImplCopyWith<$Res> {
  __$$InsurancePolicyModelImplCopyWithImpl(
    _$InsurancePolicyModelImpl _value,
    $Res Function(_$InsurancePolicyModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InsurancePolicyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? provider = null,
    Object? policyNumber = null,
    Object? coverageType = null,
    Object? totalCoverageAmount = null,
    Object? premium = freezed,
    Object? currency = null,
    Object? startDate = null,
    Object? expiresAt = null,
    Object? status = null,
    Object? notes = freezed,
    Object? insuredItems = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$InsurancePolicyModelImpl(
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
        provider:
            null == provider
                ? _value.provider
                : provider // ignore: cast_nullable_to_non_nullable
                    as String,
        policyNumber:
            null == policyNumber
                ? _value.policyNumber
                : policyNumber // ignore: cast_nullable_to_non_nullable
                    as String,
        coverageType:
            null == coverageType
                ? _value.coverageType
                : coverageType // ignore: cast_nullable_to_non_nullable
                    as String,
        totalCoverageAmount:
            null == totalCoverageAmount
                ? _value.totalCoverageAmount
                : totalCoverageAmount // ignore: cast_nullable_to_non_nullable
                    as double,
        premium:
            freezed == premium
                ? _value.premium
                : premium // ignore: cast_nullable_to_non_nullable
                    as double?,
        currency:
            null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                    as String,
        startDate:
            null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                    as String,
        expiresAt:
            null == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                    as String,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
        notes:
            freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                    as String?,
        insuredItems:
            null == insuredItems
                ? _value._insuredItems
                : insuredItems // ignore: cast_nullable_to_non_nullable
                    as List<InsuredItemModel>,
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InsurancePolicyModelImpl implements _InsurancePolicyModel {
  const _$InsurancePolicyModelImpl({
    required this.id,
    required this.tenantId,
    required this.provider,
    required this.policyNumber,
    required this.coverageType,
    @JsonKey(fromJson: _parseDouble) this.totalCoverageAmount = 0.0,
    @JsonKey(fromJson: _parseDoubleNullable) this.premium,
    this.currency = 'USD',
    required this.startDate,
    required this.expiresAt,
    this.status = 'active',
    this.notes,
    final List<InsuredItemModel> insuredItems = const [],
    this.createdAt,
    this.updatedAt,
  }) : _insuredItems = insuredItems;

  factory _$InsurancePolicyModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$InsurancePolicyModelImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String provider;
  @override
  final String policyNumber;
  @override
  final String coverageType;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double totalCoverageAmount;
  @override
  @JsonKey(fromJson: _parseDoubleNullable)
  final double? premium;
  @override
  @JsonKey()
  final String currency;
  @override
  final String startDate;
  @override
  final String expiresAt;
  @override
  @JsonKey()
  final String status;
  @override
  final String? notes;
  final List<InsuredItemModel> _insuredItems;
  @override
  @JsonKey()
  List<InsuredItemModel> get insuredItems {
    if (_insuredItems is EqualUnmodifiableListView) return _insuredItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_insuredItems);
  }

  @override
  final String? createdAt;
  @override
  final String? updatedAt;

  @override
  String toString() {
    return 'InsurancePolicyModel(id: $id, tenantId: $tenantId, provider: $provider, policyNumber: $policyNumber, coverageType: $coverageType, totalCoverageAmount: $totalCoverageAmount, premium: $premium, currency: $currency, startDate: $startDate, expiresAt: $expiresAt, status: $status, notes: $notes, insuredItems: $insuredItems, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InsurancePolicyModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.provider, provider) ||
                other.provider == provider) &&
            (identical(other.policyNumber, policyNumber) ||
                other.policyNumber == policyNumber) &&
            (identical(other.coverageType, coverageType) ||
                other.coverageType == coverageType) &&
            (identical(other.totalCoverageAmount, totalCoverageAmount) ||
                other.totalCoverageAmount == totalCoverageAmount) &&
            (identical(other.premium, premium) || other.premium == premium) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            const DeepCollectionEquality().equals(
              other._insuredItems,
              _insuredItems,
            ) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    tenantId,
    provider,
    policyNumber,
    coverageType,
    totalCoverageAmount,
    premium,
    currency,
    startDate,
    expiresAt,
    status,
    notes,
    const DeepCollectionEquality().hash(_insuredItems),
    createdAt,
    updatedAt,
  );

  /// Create a copy of InsurancePolicyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InsurancePolicyModelImplCopyWith<_$InsurancePolicyModelImpl>
  get copyWith =>
      __$$InsurancePolicyModelImplCopyWithImpl<_$InsurancePolicyModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$InsurancePolicyModelImplToJson(this);
  }
}

abstract class _InsurancePolicyModel implements InsurancePolicyModel {
  const factory _InsurancePolicyModel({
    required final String id,
    required final String tenantId,
    required final String provider,
    required final String policyNumber,
    required final String coverageType,
    @JsonKey(fromJson: _parseDouble) final double totalCoverageAmount,
    @JsonKey(fromJson: _parseDoubleNullable) final double? premium,
    final String currency,
    required final String startDate,
    required final String expiresAt,
    final String status,
    final String? notes,
    final List<InsuredItemModel> insuredItems,
    final String? createdAt,
    final String? updatedAt,
  }) = _$InsurancePolicyModelImpl;

  factory _InsurancePolicyModel.fromJson(Map<String, dynamic> json) =
      _$InsurancePolicyModelImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String get provider;
  @override
  String get policyNumber;
  @override
  String get coverageType;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get totalCoverageAmount;
  @override
  @JsonKey(fromJson: _parseDoubleNullable)
  double? get premium;
  @override
  String get currency;
  @override
  String get startDate;
  @override
  String get expiresAt;
  @override
  String get status;
  @override
  String? get notes;
  @override
  List<InsuredItemModel> get insuredItems;
  @override
  String? get createdAt;
  @override
  String? get updatedAt;

  /// Create a copy of InsurancePolicyModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InsurancePolicyModelImplCopyWith<_$InsurancePolicyModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

CoverageGapItemModel _$CoverageGapItemModelFromJson(Map<String, dynamic> json) {
  return _CoverageGapItemModel.fromJson(json);
}

/// @nodoc
mixin _$CoverageGapItemModel {
  String get itemId => throw _privateConstructorUsedError;
  String get itemName => throw _privateConstructorUsedError;
  double get currentValue => throw _privateConstructorUsedError;
  double? get coveredValue => throw _privateConstructorUsedError;
  double get gap => throw _privateConstructorUsedError;
  bool get fullyUninsured => throw _privateConstructorUsedError;

  /// Serializes this CoverageGapItemModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CoverageGapItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CoverageGapItemModelCopyWith<CoverageGapItemModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CoverageGapItemModelCopyWith<$Res> {
  factory $CoverageGapItemModelCopyWith(
    CoverageGapItemModel value,
    $Res Function(CoverageGapItemModel) then,
  ) = _$CoverageGapItemModelCopyWithImpl<$Res, CoverageGapItemModel>;
  @useResult
  $Res call({
    String itemId,
    String itemName,
    double currentValue,
    double? coveredValue,
    double gap,
    bool fullyUninsured,
  });
}

/// @nodoc
class _$CoverageGapItemModelCopyWithImpl<
  $Res,
  $Val extends CoverageGapItemModel
>
    implements $CoverageGapItemModelCopyWith<$Res> {
  _$CoverageGapItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CoverageGapItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? itemName = null,
    Object? currentValue = null,
    Object? coveredValue = freezed,
    Object? gap = null,
    Object? fullyUninsured = null,
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
            currentValue:
                null == currentValue
                    ? _value.currentValue
                    : currentValue // ignore: cast_nullable_to_non_nullable
                        as double,
            coveredValue:
                freezed == coveredValue
                    ? _value.coveredValue
                    : coveredValue // ignore: cast_nullable_to_non_nullable
                        as double?,
            gap:
                null == gap
                    ? _value.gap
                    : gap // ignore: cast_nullable_to_non_nullable
                        as double,
            fullyUninsured:
                null == fullyUninsured
                    ? _value.fullyUninsured
                    : fullyUninsured // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CoverageGapItemModelImplCopyWith<$Res>
    implements $CoverageGapItemModelCopyWith<$Res> {
  factory _$$CoverageGapItemModelImplCopyWith(
    _$CoverageGapItemModelImpl value,
    $Res Function(_$CoverageGapItemModelImpl) then,
  ) = __$$CoverageGapItemModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String itemId,
    String itemName,
    double currentValue,
    double? coveredValue,
    double gap,
    bool fullyUninsured,
  });
}

/// @nodoc
class __$$CoverageGapItemModelImplCopyWithImpl<$Res>
    extends _$CoverageGapItemModelCopyWithImpl<$Res, _$CoverageGapItemModelImpl>
    implements _$$CoverageGapItemModelImplCopyWith<$Res> {
  __$$CoverageGapItemModelImplCopyWithImpl(
    _$CoverageGapItemModelImpl _value,
    $Res Function(_$CoverageGapItemModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CoverageGapItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? itemName = null,
    Object? currentValue = null,
    Object? coveredValue = freezed,
    Object? gap = null,
    Object? fullyUninsured = null,
  }) {
    return _then(
      _$CoverageGapItemModelImpl(
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
        currentValue:
            null == currentValue
                ? _value.currentValue
                : currentValue // ignore: cast_nullable_to_non_nullable
                    as double,
        coveredValue:
            freezed == coveredValue
                ? _value.coveredValue
                : coveredValue // ignore: cast_nullable_to_non_nullable
                    as double?,
        gap:
            null == gap
                ? _value.gap
                : gap // ignore: cast_nullable_to_non_nullable
                    as double,
        fullyUninsured:
            null == fullyUninsured
                ? _value.fullyUninsured
                : fullyUninsured // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CoverageGapItemModelImpl implements _CoverageGapItemModel {
  const _$CoverageGapItemModelImpl({
    required this.itemId,
    required this.itemName,
    required this.currentValue,
    this.coveredValue,
    required this.gap,
    required this.fullyUninsured,
  });

  factory _$CoverageGapItemModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CoverageGapItemModelImplFromJson(json);

  @override
  final String itemId;
  @override
  final String itemName;
  @override
  final double currentValue;
  @override
  final double? coveredValue;
  @override
  final double gap;
  @override
  final bool fullyUninsured;

  @override
  String toString() {
    return 'CoverageGapItemModel(itemId: $itemId, itemName: $itemName, currentValue: $currentValue, coveredValue: $coveredValue, gap: $gap, fullyUninsured: $fullyUninsured)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CoverageGapItemModelImpl &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.currentValue, currentValue) ||
                other.currentValue == currentValue) &&
            (identical(other.coveredValue, coveredValue) ||
                other.coveredValue == coveredValue) &&
            (identical(other.gap, gap) || other.gap == gap) &&
            (identical(other.fullyUninsured, fullyUninsured) ||
                other.fullyUninsured == fullyUninsured));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    itemId,
    itemName,
    currentValue,
    coveredValue,
    gap,
    fullyUninsured,
  );

  /// Create a copy of CoverageGapItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CoverageGapItemModelImplCopyWith<_$CoverageGapItemModelImpl>
  get copyWith =>
      __$$CoverageGapItemModelImplCopyWithImpl<_$CoverageGapItemModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CoverageGapItemModelImplToJson(this);
  }
}

abstract class _CoverageGapItemModel implements CoverageGapItemModel {
  const factory _CoverageGapItemModel({
    required final String itemId,
    required final String itemName,
    required final double currentValue,
    final double? coveredValue,
    required final double gap,
    required final bool fullyUninsured,
  }) = _$CoverageGapItemModelImpl;

  factory _CoverageGapItemModel.fromJson(Map<String, dynamic> json) =
      _$CoverageGapItemModelImpl.fromJson;

  @override
  String get itemId;
  @override
  String get itemName;
  @override
  double get currentValue;
  @override
  double? get coveredValue;
  @override
  double get gap;
  @override
  bool get fullyUninsured;

  /// Create a copy of CoverageGapItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CoverageGapItemModelImplCopyWith<_$CoverageGapItemModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

CoverageGapReportModel _$CoverageGapReportModelFromJson(
  Map<String, dynamic> json,
) {
  return _CoverageGapReportModel.fromJson(json);
}

/// @nodoc
mixin _$CoverageGapReportModel {
  String get policyId => throw _privateConstructorUsedError;
  double get totalInventoryValue => throw _privateConstructorUsedError;
  double get totalCoveredValue => throw _privateConstructorUsedError;
  double get totalGap => throw _privateConstructorUsedError;
  List<CoverageGapItemModel> get items => throw _privateConstructorUsedError;

  /// Serializes this CoverageGapReportModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CoverageGapReportModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CoverageGapReportModelCopyWith<CoverageGapReportModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CoverageGapReportModelCopyWith<$Res> {
  factory $CoverageGapReportModelCopyWith(
    CoverageGapReportModel value,
    $Res Function(CoverageGapReportModel) then,
  ) = _$CoverageGapReportModelCopyWithImpl<$Res, CoverageGapReportModel>;
  @useResult
  $Res call({
    String policyId,
    double totalInventoryValue,
    double totalCoveredValue,
    double totalGap,
    List<CoverageGapItemModel> items,
  });
}

/// @nodoc
class _$CoverageGapReportModelCopyWithImpl<
  $Res,
  $Val extends CoverageGapReportModel
>
    implements $CoverageGapReportModelCopyWith<$Res> {
  _$CoverageGapReportModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CoverageGapReportModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? policyId = null,
    Object? totalInventoryValue = null,
    Object? totalCoveredValue = null,
    Object? totalGap = null,
    Object? items = null,
  }) {
    return _then(
      _value.copyWith(
            policyId:
                null == policyId
                    ? _value.policyId
                    : policyId // ignore: cast_nullable_to_non_nullable
                        as String,
            totalInventoryValue:
                null == totalInventoryValue
                    ? _value.totalInventoryValue
                    : totalInventoryValue // ignore: cast_nullable_to_non_nullable
                        as double,
            totalCoveredValue:
                null == totalCoveredValue
                    ? _value.totalCoveredValue
                    : totalCoveredValue // ignore: cast_nullable_to_non_nullable
                        as double,
            totalGap:
                null == totalGap
                    ? _value.totalGap
                    : totalGap // ignore: cast_nullable_to_non_nullable
                        as double,
            items:
                null == items
                    ? _value.items
                    : items // ignore: cast_nullable_to_non_nullable
                        as List<CoverageGapItemModel>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CoverageGapReportModelImplCopyWith<$Res>
    implements $CoverageGapReportModelCopyWith<$Res> {
  factory _$$CoverageGapReportModelImplCopyWith(
    _$CoverageGapReportModelImpl value,
    $Res Function(_$CoverageGapReportModelImpl) then,
  ) = __$$CoverageGapReportModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String policyId,
    double totalInventoryValue,
    double totalCoveredValue,
    double totalGap,
    List<CoverageGapItemModel> items,
  });
}

/// @nodoc
class __$$CoverageGapReportModelImplCopyWithImpl<$Res>
    extends
        _$CoverageGapReportModelCopyWithImpl<$Res, _$CoverageGapReportModelImpl>
    implements _$$CoverageGapReportModelImplCopyWith<$Res> {
  __$$CoverageGapReportModelImplCopyWithImpl(
    _$CoverageGapReportModelImpl _value,
    $Res Function(_$CoverageGapReportModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CoverageGapReportModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? policyId = null,
    Object? totalInventoryValue = null,
    Object? totalCoveredValue = null,
    Object? totalGap = null,
    Object? items = null,
  }) {
    return _then(
      _$CoverageGapReportModelImpl(
        policyId:
            null == policyId
                ? _value.policyId
                : policyId // ignore: cast_nullable_to_non_nullable
                    as String,
        totalInventoryValue:
            null == totalInventoryValue
                ? _value.totalInventoryValue
                : totalInventoryValue // ignore: cast_nullable_to_non_nullable
                    as double,
        totalCoveredValue:
            null == totalCoveredValue
                ? _value.totalCoveredValue
                : totalCoveredValue // ignore: cast_nullable_to_non_nullable
                    as double,
        totalGap:
            null == totalGap
                ? _value.totalGap
                : totalGap // ignore: cast_nullable_to_non_nullable
                    as double,
        items:
            null == items
                ? _value._items
                : items // ignore: cast_nullable_to_non_nullable
                    as List<CoverageGapItemModel>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CoverageGapReportModelImpl implements _CoverageGapReportModel {
  const _$CoverageGapReportModelImpl({
    required this.policyId,
    required this.totalInventoryValue,
    required this.totalCoveredValue,
    required this.totalGap,
    final List<CoverageGapItemModel> items = const [],
  }) : _items = items;

  factory _$CoverageGapReportModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CoverageGapReportModelImplFromJson(json);

  @override
  final String policyId;
  @override
  final double totalInventoryValue;
  @override
  final double totalCoveredValue;
  @override
  final double totalGap;
  final List<CoverageGapItemModel> _items;
  @override
  @JsonKey()
  List<CoverageGapItemModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'CoverageGapReportModel(policyId: $policyId, totalInventoryValue: $totalInventoryValue, totalCoveredValue: $totalCoveredValue, totalGap: $totalGap, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CoverageGapReportModelImpl &&
            (identical(other.policyId, policyId) ||
                other.policyId == policyId) &&
            (identical(other.totalInventoryValue, totalInventoryValue) ||
                other.totalInventoryValue == totalInventoryValue) &&
            (identical(other.totalCoveredValue, totalCoveredValue) ||
                other.totalCoveredValue == totalCoveredValue) &&
            (identical(other.totalGap, totalGap) ||
                other.totalGap == totalGap) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    policyId,
    totalInventoryValue,
    totalCoveredValue,
    totalGap,
    const DeepCollectionEquality().hash(_items),
  );

  /// Create a copy of CoverageGapReportModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CoverageGapReportModelImplCopyWith<_$CoverageGapReportModelImpl>
  get copyWith =>
      __$$CoverageGapReportModelImplCopyWithImpl<_$CoverageGapReportModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CoverageGapReportModelImplToJson(this);
  }
}

abstract class _CoverageGapReportModel implements CoverageGapReportModel {
  const factory _CoverageGapReportModel({
    required final String policyId,
    required final double totalInventoryValue,
    required final double totalCoveredValue,
    required final double totalGap,
    final List<CoverageGapItemModel> items,
  }) = _$CoverageGapReportModelImpl;

  factory _CoverageGapReportModel.fromJson(Map<String, dynamic> json) =
      _$CoverageGapReportModelImpl.fromJson;

  @override
  String get policyId;
  @override
  double get totalInventoryValue;
  @override
  double get totalCoveredValue;
  @override
  double get totalGap;
  @override
  List<CoverageGapItemModel> get items;

  /// Create a copy of CoverageGapReportModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CoverageGapReportModelImplCopyWith<_$CoverageGapReportModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
