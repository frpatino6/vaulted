// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'at_laundry_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AtLaundryItem _$AtLaundryItemFromJson(Map<String, dynamic> json) {
  return _AtLaundryItem.fromJson(json);
}

/// @nodoc
mixin _$AtLaundryItem {
  @JsonKey(name: 'recordId')
  String get recordId => throw _privateConstructorUsedError;
  @JsonKey(name: 'itemId')
  String get itemId => throw _privateConstructorUsedError;
  @JsonKey(name: 'itemName')
  String get itemName => throw _privateConstructorUsedError;
  @JsonKey(name: 'photoUrl')
  String? get photoUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'cleanerName')
  String? get cleanerName => throw _privateConstructorUsedError;
  @JsonKey(name: 'sentDate')
  DateTime get sentDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'daysAtCleaner')
  int get daysAtCleaner => throw _privateConstructorUsedError;
  @JsonKey(name: 'isOverdue')
  bool get isOverdue => throw _privateConstructorUsedError;
  double? get cost => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;

  /// Serializes this AtLaundryItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AtLaundryItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AtLaundryItemCopyWith<AtLaundryItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AtLaundryItemCopyWith<$Res> {
  factory $AtLaundryItemCopyWith(
    AtLaundryItem value,
    $Res Function(AtLaundryItem) then,
  ) = _$AtLaundryItemCopyWithImpl<$Res, AtLaundryItem>;
  @useResult
  $Res call({
    @JsonKey(name: 'recordId') String recordId,
    @JsonKey(name: 'itemId') String itemId,
    @JsonKey(name: 'itemName') String itemName,
    @JsonKey(name: 'photoUrl') String? photoUrl,
    @JsonKey(name: 'cleanerName') String? cleanerName,
    @JsonKey(name: 'sentDate') DateTime sentDate,
    @JsonKey(name: 'daysAtCleaner') int daysAtCleaner,
    @JsonKey(name: 'isOverdue') bool isOverdue,
    double? cost,
    String currency,
  });
}

/// @nodoc
class _$AtLaundryItemCopyWithImpl<$Res, $Val extends AtLaundryItem>
    implements $AtLaundryItemCopyWith<$Res> {
  _$AtLaundryItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AtLaundryItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recordId = null,
    Object? itemId = null,
    Object? itemName = null,
    Object? photoUrl = freezed,
    Object? cleanerName = freezed,
    Object? sentDate = null,
    Object? daysAtCleaner = null,
    Object? isOverdue = null,
    Object? cost = freezed,
    Object? currency = null,
  }) {
    return _then(
      _value.copyWith(
            recordId:
                null == recordId
                    ? _value.recordId
                    : recordId // ignore: cast_nullable_to_non_nullable
                        as String,
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
            photoUrl:
                freezed == photoUrl
                    ? _value.photoUrl
                    : photoUrl // ignore: cast_nullable_to_non_nullable
                        as String?,
            cleanerName:
                freezed == cleanerName
                    ? _value.cleanerName
                    : cleanerName // ignore: cast_nullable_to_non_nullable
                        as String?,
            sentDate:
                null == sentDate
                    ? _value.sentDate
                    : sentDate // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            daysAtCleaner:
                null == daysAtCleaner
                    ? _value.daysAtCleaner
                    : daysAtCleaner // ignore: cast_nullable_to_non_nullable
                        as int,
            isOverdue:
                null == isOverdue
                    ? _value.isOverdue
                    : isOverdue // ignore: cast_nullable_to_non_nullable
                        as bool,
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AtLaundryItemImplCopyWith<$Res>
    implements $AtLaundryItemCopyWith<$Res> {
  factory _$$AtLaundryItemImplCopyWith(
    _$AtLaundryItemImpl value,
    $Res Function(_$AtLaundryItemImpl) then,
  ) = __$$AtLaundryItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'recordId') String recordId,
    @JsonKey(name: 'itemId') String itemId,
    @JsonKey(name: 'itemName') String itemName,
    @JsonKey(name: 'photoUrl') String? photoUrl,
    @JsonKey(name: 'cleanerName') String? cleanerName,
    @JsonKey(name: 'sentDate') DateTime sentDate,
    @JsonKey(name: 'daysAtCleaner') int daysAtCleaner,
    @JsonKey(name: 'isOverdue') bool isOverdue,
    double? cost,
    String currency,
  });
}

/// @nodoc
class __$$AtLaundryItemImplCopyWithImpl<$Res>
    extends _$AtLaundryItemCopyWithImpl<$Res, _$AtLaundryItemImpl>
    implements _$$AtLaundryItemImplCopyWith<$Res> {
  __$$AtLaundryItemImplCopyWithImpl(
    _$AtLaundryItemImpl _value,
    $Res Function(_$AtLaundryItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AtLaundryItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recordId = null,
    Object? itemId = null,
    Object? itemName = null,
    Object? photoUrl = freezed,
    Object? cleanerName = freezed,
    Object? sentDate = null,
    Object? daysAtCleaner = null,
    Object? isOverdue = null,
    Object? cost = freezed,
    Object? currency = null,
  }) {
    return _then(
      _$AtLaundryItemImpl(
        recordId:
            null == recordId
                ? _value.recordId
                : recordId // ignore: cast_nullable_to_non_nullable
                    as String,
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
        photoUrl:
            freezed == photoUrl
                ? _value.photoUrl
                : photoUrl // ignore: cast_nullable_to_non_nullable
                    as String?,
        cleanerName:
            freezed == cleanerName
                ? _value.cleanerName
                : cleanerName // ignore: cast_nullable_to_non_nullable
                    as String?,
        sentDate:
            null == sentDate
                ? _value.sentDate
                : sentDate // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        daysAtCleaner:
            null == daysAtCleaner
                ? _value.daysAtCleaner
                : daysAtCleaner // ignore: cast_nullable_to_non_nullable
                    as int,
        isOverdue:
            null == isOverdue
                ? _value.isOverdue
                : isOverdue // ignore: cast_nullable_to_non_nullable
                    as bool,
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AtLaundryItemImpl implements _AtLaundryItem {
  const _$AtLaundryItemImpl({
    @JsonKey(name: 'recordId') required this.recordId,
    @JsonKey(name: 'itemId') required this.itemId,
    @JsonKey(name: 'itemName') required this.itemName,
    @JsonKey(name: 'photoUrl') this.photoUrl,
    @JsonKey(name: 'cleanerName') this.cleanerName,
    @JsonKey(name: 'sentDate') required this.sentDate,
    @JsonKey(name: 'daysAtCleaner') required this.daysAtCleaner,
    @JsonKey(name: 'isOverdue') required this.isOverdue,
    this.cost,
    this.currency = 'USD',
  });

  factory _$AtLaundryItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$AtLaundryItemImplFromJson(json);

  @override
  @JsonKey(name: 'recordId')
  final String recordId;
  @override
  @JsonKey(name: 'itemId')
  final String itemId;
  @override
  @JsonKey(name: 'itemName')
  final String itemName;
  @override
  @JsonKey(name: 'photoUrl')
  final String? photoUrl;
  @override
  @JsonKey(name: 'cleanerName')
  final String? cleanerName;
  @override
  @JsonKey(name: 'sentDate')
  final DateTime sentDate;
  @override
  @JsonKey(name: 'daysAtCleaner')
  final int daysAtCleaner;
  @override
  @JsonKey(name: 'isOverdue')
  final bool isOverdue;
  @override
  final double? cost;
  @override
  @JsonKey()
  final String currency;

  @override
  String toString() {
    return 'AtLaundryItem(recordId: $recordId, itemId: $itemId, itemName: $itemName, photoUrl: $photoUrl, cleanerName: $cleanerName, sentDate: $sentDate, daysAtCleaner: $daysAtCleaner, isOverdue: $isOverdue, cost: $cost, currency: $currency)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AtLaundryItemImpl &&
            (identical(other.recordId, recordId) ||
                other.recordId == recordId) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.cleanerName, cleanerName) ||
                other.cleanerName == cleanerName) &&
            (identical(other.sentDate, sentDate) ||
                other.sentDate == sentDate) &&
            (identical(other.daysAtCleaner, daysAtCleaner) ||
                other.daysAtCleaner == daysAtCleaner) &&
            (identical(other.isOverdue, isOverdue) ||
                other.isOverdue == isOverdue) &&
            (identical(other.cost, cost) || other.cost == cost) &&
            (identical(other.currency, currency) ||
                other.currency == currency));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    recordId,
    itemId,
    itemName,
    photoUrl,
    cleanerName,
    sentDate,
    daysAtCleaner,
    isOverdue,
    cost,
    currency,
  );

  /// Create a copy of AtLaundryItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AtLaundryItemImplCopyWith<_$AtLaundryItemImpl> get copyWith =>
      __$$AtLaundryItemImplCopyWithImpl<_$AtLaundryItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AtLaundryItemImplToJson(this);
  }
}

abstract class _AtLaundryItem implements AtLaundryItem {
  const factory _AtLaundryItem({
    @JsonKey(name: 'recordId') required final String recordId,
    @JsonKey(name: 'itemId') required final String itemId,
    @JsonKey(name: 'itemName') required final String itemName,
    @JsonKey(name: 'photoUrl') final String? photoUrl,
    @JsonKey(name: 'cleanerName') final String? cleanerName,
    @JsonKey(name: 'sentDate') required final DateTime sentDate,
    @JsonKey(name: 'daysAtCleaner') required final int daysAtCleaner,
    @JsonKey(name: 'isOverdue') required final bool isOverdue,
    final double? cost,
    final String currency,
  }) = _$AtLaundryItemImpl;

  factory _AtLaundryItem.fromJson(Map<String, dynamic> json) =
      _$AtLaundryItemImpl.fromJson;

  @override
  @JsonKey(name: 'recordId')
  String get recordId;
  @override
  @JsonKey(name: 'itemId')
  String get itemId;
  @override
  @JsonKey(name: 'itemName')
  String get itemName;
  @override
  @JsonKey(name: 'photoUrl')
  String? get photoUrl;
  @override
  @JsonKey(name: 'cleanerName')
  String? get cleanerName;
  @override
  @JsonKey(name: 'sentDate')
  DateTime get sentDate;
  @override
  @JsonKey(name: 'daysAtCleaner')
  int get daysAtCleaner;
  @override
  @JsonKey(name: 'isOverdue')
  bool get isOverdue;
  @override
  double? get cost;
  @override
  String get currency;

  /// Create a copy of AtLaundryItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AtLaundryItemImplCopyWith<_$AtLaundryItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// ─────────────────────────────────────────────────────────────────────────────
// AtLaundryProperty
// ─────────────────────────────────────────────────────────────────────────────

AtLaundryProperty _$AtLaundryPropertyFromJson(Map<String, dynamic> json) {
  return _AtLaundryProperty.fromJson(json);
}

/// @nodoc
mixin _$AtLaundryProperty {
  @JsonKey(name: 'propertyId')
  String get propertyId => throw _privateConstructorUsedError;
  @JsonKey(name: 'propertyName')
  String get propertyName => throw _privateConstructorUsedError;
  List<AtLaundryItem> get items => throw _privateConstructorUsedError;

  /// Serializes this AtLaundryProperty to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AtLaundryProperty
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AtLaundryPropertyCopyWith<AtLaundryProperty> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AtLaundryPropertyCopyWith<$Res> {
  factory $AtLaundryPropertyCopyWith(
    AtLaundryProperty value,
    $Res Function(AtLaundryProperty) then,
  ) = _$AtLaundryPropertyCopyWithImpl<$Res, AtLaundryProperty>;
  @useResult
  $Res call({
    @JsonKey(name: 'propertyId') String propertyId,
    @JsonKey(name: 'propertyName') String propertyName,
    List<AtLaundryItem> items,
  });
}

/// @nodoc
class _$AtLaundryPropertyCopyWithImpl<$Res, $Val extends AtLaundryProperty>
    implements $AtLaundryPropertyCopyWith<$Res> {
  _$AtLaundryPropertyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AtLaundryProperty
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? propertyId = null,
    Object? propertyName = null,
    Object? items = null,
  }) {
    return _then(
      _value.copyWith(
            propertyId:
                null == propertyId
                    ? _value.propertyId
                    : propertyId // ignore: cast_nullable_to_non_nullable
                        as String,
            propertyName:
                null == propertyName
                    ? _value.propertyName
                    : propertyName // ignore: cast_nullable_to_non_nullable
                        as String,
            items:
                null == items
                    ? _value.items
                    : items // ignore: cast_nullable_to_non_nullable
                        as List<AtLaundryItem>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AtLaundryPropertyImplCopyWith<$Res>
    implements $AtLaundryPropertyCopyWith<$Res> {
  factory _$$AtLaundryPropertyImplCopyWith(
    _$AtLaundryPropertyImpl value,
    $Res Function(_$AtLaundryPropertyImpl) then,
  ) = __$$AtLaundryPropertyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'propertyId') String propertyId,
    @JsonKey(name: 'propertyName') String propertyName,
    List<AtLaundryItem> items,
  });
}

/// @nodoc
class __$$AtLaundryPropertyImplCopyWithImpl<$Res>
    extends _$AtLaundryPropertyCopyWithImpl<$Res, _$AtLaundryPropertyImpl>
    implements _$$AtLaundryPropertyImplCopyWith<$Res> {
  __$$AtLaundryPropertyImplCopyWithImpl(
    _$AtLaundryPropertyImpl _value,
    $Res Function(_$AtLaundryPropertyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AtLaundryProperty
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? propertyId = null,
    Object? propertyName = null,
    Object? items = null,
  }) {
    return _then(
      _$AtLaundryPropertyImpl(
        propertyId:
            null == propertyId
                ? _value.propertyId
                : propertyId // ignore: cast_nullable_to_non_nullable
                    as String,
        propertyName:
            null == propertyName
                ? _value.propertyName
                : propertyName // ignore: cast_nullable_to_non_nullable
                    as String,
        items:
            null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                    as List<AtLaundryItem>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AtLaundryPropertyImpl implements _AtLaundryProperty {
  const _$AtLaundryPropertyImpl({
    @JsonKey(name: 'propertyId') required this.propertyId,
    @JsonKey(name: 'propertyName') required this.propertyName,
    required this.items,
  });

  factory _$AtLaundryPropertyImpl.fromJson(Map<String, dynamic> json) =>
      _$$AtLaundryPropertyImplFromJson(json);

  @override
  @JsonKey(name: 'propertyId')
  final String propertyId;
  @override
  @JsonKey(name: 'propertyName')
  final String propertyName;
  @override
  final List<AtLaundryItem> items;

  @override
  String toString() {
    return 'AtLaundryProperty(propertyId: $propertyId, propertyName: $propertyName, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AtLaundryPropertyImpl &&
            (identical(other.propertyId, propertyId) ||
                other.propertyId == propertyId) &&
            (identical(other.propertyName, propertyName) ||
                other.propertyName == propertyName) &&
            const DeepCollectionEquality().equals(other.items, items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    propertyId,
    propertyName,
    const DeepCollectionEquality().hash(items),
  );

  /// Create a copy of AtLaundryProperty
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AtLaundryPropertyImplCopyWith<_$AtLaundryPropertyImpl> get copyWith =>
      __$$AtLaundryPropertyImplCopyWithImpl<_$AtLaundryPropertyImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AtLaundryPropertyImplToJson(this);
  }
}

abstract class _AtLaundryProperty implements AtLaundryProperty {
  const factory _AtLaundryProperty({
    @JsonKey(name: 'propertyId') required final String propertyId,
    @JsonKey(name: 'propertyName') required final String propertyName,
    required final List<AtLaundryItem> items,
  }) = _$AtLaundryPropertyImpl;

  factory _AtLaundryProperty.fromJson(Map<String, dynamic> json) =
      _$AtLaundryPropertyImpl.fromJson;

  @override
  @JsonKey(name: 'propertyId')
  String get propertyId;
  @override
  @JsonKey(name: 'propertyName')
  String get propertyName;
  @override
  List<AtLaundryItem> get items;

  /// Create a copy of AtLaundryProperty
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AtLaundryPropertyImplCopyWith<_$AtLaundryPropertyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// ─────────────────────────────────────────────────────────────────────────────
// AtLaundryData
// ─────────────────────────────────────────────────────────────────────────────

AtLaundryData _$AtLaundryDataFromJson(Map<String, dynamic> json) {
  return _AtLaundryData.fromJson(json);
}

/// @nodoc
mixin _$AtLaundryData {
  @JsonKey(name: 'totalItems')
  int get totalItems => throw _privateConstructorUsedError;
  @JsonKey(name: 'overdueItems')
  int get overdueItems => throw _privateConstructorUsedError;
  @JsonKey(name: 'overdueThresholdDays')
  int get overdueThresholdDays => throw _privateConstructorUsedError;
  @JsonKey(name: 'byProperty')
  List<AtLaundryProperty> get byProperty => throw _privateConstructorUsedError;

  /// Serializes this AtLaundryData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AtLaundryData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AtLaundryDataCopyWith<AtLaundryData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AtLaundryDataCopyWith<$Res> {
  factory $AtLaundryDataCopyWith(
    AtLaundryData value,
    $Res Function(AtLaundryData) then,
  ) = _$AtLaundryDataCopyWithImpl<$Res, AtLaundryData>;
  @useResult
  $Res call({
    @JsonKey(name: 'totalItems') int totalItems,
    @JsonKey(name: 'overdueItems') int overdueItems,
    @JsonKey(name: 'overdueThresholdDays') int overdueThresholdDays,
    @JsonKey(name: 'byProperty') List<AtLaundryProperty> byProperty,
  });
}

/// @nodoc
class _$AtLaundryDataCopyWithImpl<$Res, $Val extends AtLaundryData>
    implements $AtLaundryDataCopyWith<$Res> {
  _$AtLaundryDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AtLaundryData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalItems = null,
    Object? overdueItems = null,
    Object? overdueThresholdDays = null,
    Object? byProperty = null,
  }) {
    return _then(
      _value.copyWith(
            totalItems:
                null == totalItems
                    ? _value.totalItems
                    : totalItems // ignore: cast_nullable_to_non_nullable
                        as int,
            overdueItems:
                null == overdueItems
                    ? _value.overdueItems
                    : overdueItems // ignore: cast_nullable_to_non_nullable
                        as int,
            overdueThresholdDays:
                null == overdueThresholdDays
                    ? _value.overdueThresholdDays
                    : overdueThresholdDays // ignore: cast_nullable_to_non_nullable
                        as int,
            byProperty:
                null == byProperty
                    ? _value.byProperty
                    : byProperty // ignore: cast_nullable_to_non_nullable
                        as List<AtLaundryProperty>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AtLaundryDataImplCopyWith<$Res>
    implements $AtLaundryDataCopyWith<$Res> {
  factory _$$AtLaundryDataImplCopyWith(
    _$AtLaundryDataImpl value,
    $Res Function(_$AtLaundryDataImpl) then,
  ) = __$$AtLaundryDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'totalItems') int totalItems,
    @JsonKey(name: 'overdueItems') int overdueItems,
    @JsonKey(name: 'overdueThresholdDays') int overdueThresholdDays,
    @JsonKey(name: 'byProperty') List<AtLaundryProperty> byProperty,
  });
}

/// @nodoc
class __$$AtLaundryDataImplCopyWithImpl<$Res>
    extends _$AtLaundryDataCopyWithImpl<$Res, _$AtLaundryDataImpl>
    implements _$$AtLaundryDataImplCopyWith<$Res> {
  __$$AtLaundryDataImplCopyWithImpl(
    _$AtLaundryDataImpl _value,
    $Res Function(_$AtLaundryDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AtLaundryData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalItems = null,
    Object? overdueItems = null,
    Object? overdueThresholdDays = null,
    Object? byProperty = null,
  }) {
    return _then(
      _$AtLaundryDataImpl(
        totalItems:
            null == totalItems
                ? _value.totalItems
                : totalItems // ignore: cast_nullable_to_non_nullable
                    as int,
        overdueItems:
            null == overdueItems
                ? _value.overdueItems
                : overdueItems // ignore: cast_nullable_to_non_nullable
                    as int,
        overdueThresholdDays:
            null == overdueThresholdDays
                ? _value.overdueThresholdDays
                : overdueThresholdDays // ignore: cast_nullable_to_non_nullable
                    as int,
        byProperty:
            null == byProperty
                ? _value.byProperty
                : byProperty // ignore: cast_nullable_to_non_nullable
                    as List<AtLaundryProperty>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AtLaundryDataImpl implements _AtLaundryData {
  const _$AtLaundryDataImpl({
    @JsonKey(name: 'totalItems') required this.totalItems,
    @JsonKey(name: 'overdueItems') required this.overdueItems,
    @JsonKey(name: 'overdueThresholdDays') this.overdueThresholdDays = 7,
    @JsonKey(name: 'byProperty') required this.byProperty,
  });

  factory _$AtLaundryDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$AtLaundryDataImplFromJson(json);

  @override
  @JsonKey(name: 'totalItems')
  final int totalItems;
  @override
  @JsonKey(name: 'overdueItems')
  final int overdueItems;
  @override
  @JsonKey(name: 'overdueThresholdDays')
  final int overdueThresholdDays;
  @override
  @JsonKey(name: 'byProperty')
  final List<AtLaundryProperty> byProperty;

  @override
  String toString() {
    return 'AtLaundryData(totalItems: $totalItems, overdueItems: $overdueItems, overdueThresholdDays: $overdueThresholdDays, byProperty: $byProperty)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AtLaundryDataImpl &&
            (identical(other.totalItems, totalItems) ||
                other.totalItems == totalItems) &&
            (identical(other.overdueItems, overdueItems) ||
                other.overdueItems == overdueItems) &&
            (identical(other.overdueThresholdDays, overdueThresholdDays) ||
                other.overdueThresholdDays == overdueThresholdDays) &&
            const DeepCollectionEquality()
                .equals(other.byProperty, byProperty));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    totalItems,
    overdueItems,
    overdueThresholdDays,
    const DeepCollectionEquality().hash(byProperty),
  );

  /// Create a copy of AtLaundryData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AtLaundryDataImplCopyWith<_$AtLaundryDataImpl> get copyWith =>
      __$$AtLaundryDataImplCopyWithImpl<_$AtLaundryDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AtLaundryDataImplToJson(this);
  }
}

abstract class _AtLaundryData implements AtLaundryData {
  const factory _AtLaundryData({
    @JsonKey(name: 'totalItems') required final int totalItems,
    @JsonKey(name: 'overdueItems') required final int overdueItems,
    @JsonKey(name: 'overdueThresholdDays') final int overdueThresholdDays,
    @JsonKey(name: 'byProperty') required final List<AtLaundryProperty> byProperty,
  }) = _$AtLaundryDataImpl;

  factory _AtLaundryData.fromJson(Map<String, dynamic> json) =
      _$AtLaundryDataImpl.fromJson;

  @override
  @JsonKey(name: 'totalItems')
  int get totalItems;
  @override
  @JsonKey(name: 'overdueItems')
  int get overdueItems;
  @override
  @JsonKey(name: 'overdueThresholdDays')
  int get overdueThresholdDays;
  @override
  @JsonKey(name: 'byProperty')
  List<AtLaundryProperty> get byProperty;

  /// Create a copy of AtLaundryData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AtLaundryDataImplCopyWith<_$AtLaundryDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
