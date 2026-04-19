// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ItemValuationModel _$ItemValuationModelFromJson(Map<String, dynamic> json) {
  return _ItemValuationModel.fromJson(json);
}

/// @nodoc
mixin _$ItemValuationModel {
  int get purchasePrice => throw _privateConstructorUsedError;
  int get currentValue => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  DateTime? get purchaseDate => throw _privateConstructorUsedError;

  /// Serializes this ItemValuationModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ItemValuationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItemValuationModelCopyWith<ItemValuationModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemValuationModelCopyWith<$Res> {
  factory $ItemValuationModelCopyWith(
    ItemValuationModel value,
    $Res Function(ItemValuationModel) then,
  ) = _$ItemValuationModelCopyWithImpl<$Res, ItemValuationModel>;
  @useResult
  $Res call({
    int purchasePrice,
    int currentValue,
    String currency,
    DateTime? purchaseDate,
  });
}

/// @nodoc
class _$ItemValuationModelCopyWithImpl<$Res, $Val extends ItemValuationModel>
    implements $ItemValuationModelCopyWith<$Res> {
  _$ItemValuationModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItemValuationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? purchasePrice = null,
    Object? currentValue = null,
    Object? currency = null,
    Object? purchaseDate = freezed,
  }) {
    return _then(
      _value.copyWith(
            purchasePrice:
                null == purchasePrice
                    ? _value.purchasePrice
                    : purchasePrice // ignore: cast_nullable_to_non_nullable
                        as int,
            currentValue:
                null == currentValue
                    ? _value.currentValue
                    : currentValue // ignore: cast_nullable_to_non_nullable
                        as int,
            currency:
                null == currency
                    ? _value.currency
                    : currency // ignore: cast_nullable_to_non_nullable
                        as String,
            purchaseDate:
                freezed == purchaseDate
                    ? _value.purchaseDate
                    : purchaseDate // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ItemValuationModelImplCopyWith<$Res>
    implements $ItemValuationModelCopyWith<$Res> {
  factory _$$ItemValuationModelImplCopyWith(
    _$ItemValuationModelImpl value,
    $Res Function(_$ItemValuationModelImpl) then,
  ) = __$$ItemValuationModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int purchasePrice,
    int currentValue,
    String currency,
    DateTime? purchaseDate,
  });
}

/// @nodoc
class __$$ItemValuationModelImplCopyWithImpl<$Res>
    extends _$ItemValuationModelCopyWithImpl<$Res, _$ItemValuationModelImpl>
    implements _$$ItemValuationModelImplCopyWith<$Res> {
  __$$ItemValuationModelImplCopyWithImpl(
    _$ItemValuationModelImpl _value,
    $Res Function(_$ItemValuationModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ItemValuationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? purchasePrice = null,
    Object? currentValue = null,
    Object? currency = null,
    Object? purchaseDate = freezed,
  }) {
    return _then(
      _$ItemValuationModelImpl(
        purchasePrice:
            null == purchasePrice
                ? _value.purchasePrice
                : purchasePrice // ignore: cast_nullable_to_non_nullable
                    as int,
        currentValue:
            null == currentValue
                ? _value.currentValue
                : currentValue // ignore: cast_nullable_to_non_nullable
                    as int,
        currency:
            null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                    as String,
        purchaseDate:
            freezed == purchaseDate
                ? _value.purchaseDate
                : purchaseDate // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ItemValuationModelImpl implements _ItemValuationModel {
  const _$ItemValuationModelImpl({
    this.purchasePrice = 0,
    this.currentValue = 0,
    this.currency = 'USD',
    this.purchaseDate,
  });

  factory _$ItemValuationModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItemValuationModelImplFromJson(json);

  @override
  @JsonKey()
  final int purchasePrice;
  @override
  @JsonKey()
  final int currentValue;
  @override
  @JsonKey()
  final String currency;
  @override
  final DateTime? purchaseDate;

  @override
  String toString() {
    return 'ItemValuationModel(purchasePrice: $purchasePrice, currentValue: $currentValue, currency: $currency, purchaseDate: $purchaseDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemValuationModelImpl &&
            (identical(other.purchasePrice, purchasePrice) ||
                other.purchasePrice == purchasePrice) &&
            (identical(other.currentValue, currentValue) ||
                other.currentValue == currentValue) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.purchaseDate, purchaseDate) ||
                other.purchaseDate == purchaseDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    purchasePrice,
    currentValue,
    currency,
    purchaseDate,
  );

  /// Create a copy of ItemValuationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemValuationModelImplCopyWith<_$ItemValuationModelImpl> get copyWith =>
      __$$ItemValuationModelImplCopyWithImpl<_$ItemValuationModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ItemValuationModelImplToJson(this);
  }
}

abstract class _ItemValuationModel implements ItemValuationModel {
  const factory _ItemValuationModel({
    final int purchasePrice,
    final int currentValue,
    final String currency,
    final DateTime? purchaseDate,
  }) = _$ItemValuationModelImpl;

  factory _ItemValuationModel.fromJson(Map<String, dynamic> json) =
      _$ItemValuationModelImpl.fromJson;

  @override
  int get purchasePrice;
  @override
  int get currentValue;
  @override
  String get currency;
  @override
  DateTime? get purchaseDate;

  /// Create a copy of ItemValuationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItemValuationModelImplCopyWith<_$ItemValuationModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ItemModel _$ItemModelFromJson(Map<String, dynamic> json) {
  return _ItemModel.fromJson(json);
}

/// @nodoc
mixin _$ItemModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get propertyId => throw _privateConstructorUsedError;
  String? get propertyName => throw _privateConstructorUsedError;
  String? get roomId => throw _privateConstructorUsedError;
  String? get roomName => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String get subcategory => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  List<String> get photos => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  String? get serialNumber => throw _privateConstructorUsedError;
  String? get locationDetail => throw _privateConstructorUsedError;
  String? get sectionId => throw _privateConstructorUsedError;
  ItemValuationModel? get valuation =>
      throw _privateConstructorUsedError; // ignore: invalid_annotation_target
  @JsonKey(includeIfNull: false)
  Map<String, dynamic>? get attributes => throw _privateConstructorUsedError;
  List<String> get documents => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;
  String? get qrCode => throw _privateConstructorUsedError;

  /// Serializes this ItemModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItemModelCopyWith<ItemModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemModelCopyWith<$Res> {
  factory $ItemModelCopyWith(ItemModel value, $Res Function(ItemModel) then) =
      _$ItemModelCopyWithImpl<$Res, ItemModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String? propertyId,
    String? propertyName,
    String? roomId,
    String? roomName,
    String category,
    String subcategory,
    String status,
    List<String> photos,
    List<String> tags,
    String? serialNumber,
    String? locationDetail,
    String? sectionId,
    ItemValuationModel? valuation,
    @JsonKey(includeIfNull: false) Map<String, dynamic>? attributes,
    List<String> documents,
    String? createdAt,
    String? qrCode,
  });

  $ItemValuationModelCopyWith<$Res>? get valuation;
}

/// @nodoc
class _$ItemModelCopyWithImpl<$Res, $Val extends ItemModel>
    implements $ItemModelCopyWith<$Res> {
  _$ItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? propertyId = freezed,
    Object? propertyName = freezed,
    Object? roomId = freezed,
    Object? roomName = freezed,
    Object? category = null,
    Object? subcategory = null,
    Object? status = null,
    Object? photos = null,
    Object? tags = null,
    Object? serialNumber = freezed,
    Object? locationDetail = freezed,
    Object? sectionId = freezed,
    Object? valuation = freezed,
    Object? attributes = freezed,
    Object? documents = null,
    Object? createdAt = freezed,
    Object? qrCode = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            propertyId:
                freezed == propertyId
                    ? _value.propertyId
                    : propertyId // ignore: cast_nullable_to_non_nullable
                        as String?,
            propertyName:
                freezed == propertyName
                    ? _value.propertyName
                    : propertyName // ignore: cast_nullable_to_non_nullable
                        as String?,
            roomId:
                freezed == roomId
                    ? _value.roomId
                    : roomId // ignore: cast_nullable_to_non_nullable
                        as String?,
            roomName:
                freezed == roomName
                    ? _value.roomName
                    : roomName // ignore: cast_nullable_to_non_nullable
                        as String?,
            category:
                null == category
                    ? _value.category
                    : category // ignore: cast_nullable_to_non_nullable
                        as String,
            subcategory:
                null == subcategory
                    ? _value.subcategory
                    : subcategory // ignore: cast_nullable_to_non_nullable
                        as String,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            photos:
                null == photos
                    ? _value.photos
                    : photos // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            tags:
                null == tags
                    ? _value.tags
                    : tags // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            serialNumber:
                freezed == serialNumber
                    ? _value.serialNumber
                    : serialNumber // ignore: cast_nullable_to_non_nullable
                        as String?,
            locationDetail:
                freezed == locationDetail
                    ? _value.locationDetail
                    : locationDetail // ignore: cast_nullable_to_non_nullable
                        as String?,
            sectionId:
                freezed == sectionId
                    ? _value.sectionId
                    : sectionId // ignore: cast_nullable_to_non_nullable
                        as String?,
            valuation:
                freezed == valuation
                    ? _value.valuation
                    : valuation // ignore: cast_nullable_to_non_nullable
                        as ItemValuationModel?,
            attributes:
                freezed == attributes
                    ? _value.attributes
                    : attributes // ignore: cast_nullable_to_non_nullable
                        as Map<String, dynamic>?,
            documents:
                null == documents
                    ? _value.documents
                    : documents // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as String?,
            qrCode:
                freezed == qrCode
                    ? _value.qrCode
                    : qrCode // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of ItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ItemValuationModelCopyWith<$Res>? get valuation {
    if (_value.valuation == null) {
      return null;
    }

    return $ItemValuationModelCopyWith<$Res>(_value.valuation!, (value) {
      return _then(_value.copyWith(valuation: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ItemModelImplCopyWith<$Res>
    implements $ItemModelCopyWith<$Res> {
  factory _$$ItemModelImplCopyWith(
    _$ItemModelImpl value,
    $Res Function(_$ItemModelImpl) then,
  ) = __$$ItemModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? propertyId,
    String? propertyName,
    String? roomId,
    String? roomName,
    String category,
    String subcategory,
    String status,
    List<String> photos,
    List<String> tags,
    String? serialNumber,
    String? locationDetail,
    String? sectionId,
    ItemValuationModel? valuation,
    @JsonKey(includeIfNull: false) Map<String, dynamic>? attributes,
    List<String> documents,
    String? createdAt,
    String? qrCode,
  });

  @override
  $ItemValuationModelCopyWith<$Res>? get valuation;
}

/// @nodoc
class __$$ItemModelImplCopyWithImpl<$Res>
    extends _$ItemModelCopyWithImpl<$Res, _$ItemModelImpl>
    implements _$$ItemModelImplCopyWith<$Res> {
  __$$ItemModelImplCopyWithImpl(
    _$ItemModelImpl _value,
    $Res Function(_$ItemModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? propertyId = freezed,
    Object? propertyName = freezed,
    Object? roomId = freezed,
    Object? roomName = freezed,
    Object? category = null,
    Object? subcategory = null,
    Object? status = null,
    Object? photos = null,
    Object? tags = null,
    Object? serialNumber = freezed,
    Object? locationDetail = freezed,
    Object? sectionId = freezed,
    Object? valuation = freezed,
    Object? attributes = freezed,
    Object? documents = null,
    Object? createdAt = freezed,
    Object? qrCode = freezed,
  }) {
    return _then(
      _$ItemModelImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        propertyId:
            freezed == propertyId
                ? _value.propertyId
                : propertyId // ignore: cast_nullable_to_non_nullable
                    as String?,
        propertyName:
            freezed == propertyName
                ? _value.propertyName
                : propertyName // ignore: cast_nullable_to_non_nullable
                    as String?,
        roomId:
            freezed == roomId
                ? _value.roomId
                : roomId // ignore: cast_nullable_to_non_nullable
                    as String?,
        roomName:
            freezed == roomName
                ? _value.roomName
                : roomName // ignore: cast_nullable_to_non_nullable
                    as String?,
        category:
            null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                    as String,
        subcategory:
            null == subcategory
                ? _value.subcategory
                : subcategory // ignore: cast_nullable_to_non_nullable
                    as String,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
        photos:
            null == photos
                ? _value._photos
                : photos // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        tags:
            null == tags
                ? _value._tags
                : tags // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        serialNumber:
            freezed == serialNumber
                ? _value.serialNumber
                : serialNumber // ignore: cast_nullable_to_non_nullable
                    as String?,
        locationDetail:
            freezed == locationDetail
                ? _value.locationDetail
                : locationDetail // ignore: cast_nullable_to_non_nullable
                    as String?,
        sectionId:
            freezed == sectionId
                ? _value.sectionId
                : sectionId // ignore: cast_nullable_to_non_nullable
                    as String?,
        valuation:
            freezed == valuation
                ? _value.valuation
                : valuation // ignore: cast_nullable_to_non_nullable
                    as ItemValuationModel?,
        attributes:
            freezed == attributes
                ? _value._attributes
                : attributes // ignore: cast_nullable_to_non_nullable
                    as Map<String, dynamic>?,
        documents:
            null == documents
                ? _value._documents
                : documents // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as String?,
        qrCode:
            freezed == qrCode
                ? _value.qrCode
                : qrCode // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ItemModelImpl implements _ItemModel {
  const _$ItemModelImpl({
    required this.id,
    required this.name,
    this.propertyId,
    this.propertyName,
    this.roomId,
    this.roomName,
    required this.category,
    this.subcategory = '',
    this.status = 'active',
    final List<String> photos = const [],
    final List<String> tags = const [],
    this.serialNumber,
    this.locationDetail,
    this.sectionId,
    this.valuation,
    @JsonKey(includeIfNull: false) final Map<String, dynamic>? attributes,
    final List<String> documents = const [],
    this.createdAt,
    this.qrCode,
  }) : _photos = photos,
       _tags = tags,
       _attributes = attributes,
       _documents = documents;

  factory _$ItemModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItemModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? propertyId;
  @override
  final String? propertyName;
  @override
  final String? roomId;
  @override
  final String? roomName;
  @override
  final String category;
  @override
  @JsonKey()
  final String subcategory;
  @override
  @JsonKey()
  final String status;
  final List<String> _photos;
  @override
  @JsonKey()
  List<String> get photos {
    if (_photos is EqualUnmodifiableListView) return _photos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photos);
  }

  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  final String? serialNumber;
  @override
  final String? locationDetail;
  @override
  final String? sectionId;
  @override
  final ItemValuationModel? valuation;
  // ignore: invalid_annotation_target
  final Map<String, dynamic>? _attributes;
  // ignore: invalid_annotation_target
  @override
  @JsonKey(includeIfNull: false)
  Map<String, dynamic>? get attributes {
    final value = _attributes;
    if (value == null) return null;
    if (_attributes is EqualUnmodifiableMapView) return _attributes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<String> _documents;
  @override
  @JsonKey()
  List<String> get documents {
    if (_documents is EqualUnmodifiableListView) return _documents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_documents);
  }

  @override
  final String? createdAt;
  @override
  final String? qrCode;

  @override
  String toString() {
    return 'ItemModel(id: $id, name: $name, propertyId: $propertyId, propertyName: $propertyName, roomId: $roomId, roomName: $roomName, category: $category, subcategory: $subcategory, status: $status, photos: $photos, tags: $tags, serialNumber: $serialNumber, locationDetail: $locationDetail, sectionId: $sectionId, valuation: $valuation, attributes: $attributes, documents: $documents, createdAt: $createdAt, qrCode: $qrCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.propertyId, propertyId) ||
                other.propertyId == propertyId) &&
            (identical(other.propertyName, propertyName) ||
                other.propertyName == propertyName) &&
            (identical(other.roomId, roomId) || other.roomId == roomId) &&
            (identical(other.roomName, roomName) ||
                other.roomName == roomName) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.subcategory, subcategory) ||
                other.subcategory == subcategory) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._photos, _photos) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.serialNumber, serialNumber) ||
                other.serialNumber == serialNumber) &&
            (identical(other.locationDetail, locationDetail) ||
                other.locationDetail == locationDetail) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.valuation, valuation) ||
                other.valuation == valuation) &&
            const DeepCollectionEquality().equals(
              other._attributes,
              _attributes,
            ) &&
            const DeepCollectionEquality().equals(
              other._documents,
              _documents,
            ) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.qrCode, qrCode) || other.qrCode == qrCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    name,
    propertyId,
    propertyName,
    roomId,
    roomName,
    category,
    subcategory,
    status,
    const DeepCollectionEquality().hash(_photos),
    const DeepCollectionEquality().hash(_tags),
    serialNumber,
    locationDetail,
    sectionId,
    valuation,
    const DeepCollectionEquality().hash(_attributes),
    const DeepCollectionEquality().hash(_documents),
    createdAt,
    qrCode,
  ]);

  /// Create a copy of ItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemModelImplCopyWith<_$ItemModelImpl> get copyWith =>
      __$$ItemModelImplCopyWithImpl<_$ItemModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItemModelImplToJson(this);
  }
}

abstract class _ItemModel implements ItemModel {
  const factory _ItemModel({
    required final String id,
    required final String name,
    final String? propertyId,
    final String? propertyName,
    final String? roomId,
    final String? roomName,
    required final String category,
    final String subcategory,
    final String status,
    final List<String> photos,
    final List<String> tags,
    final String? serialNumber,
    final String? locationDetail,
    final String? sectionId,
    final ItemValuationModel? valuation,
    @JsonKey(includeIfNull: false) final Map<String, dynamic>? attributes,
    final List<String> documents,
    final String? createdAt,
    final String? qrCode,
  }) = _$ItemModelImpl;

  factory _ItemModel.fromJson(Map<String, dynamic> json) =
      _$ItemModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get propertyId;
  @override
  String? get propertyName;
  @override
  String? get roomId;
  @override
  String? get roomName;
  @override
  String get category;
  @override
  String get subcategory;
  @override
  String get status;
  @override
  List<String> get photos;
  @override
  List<String> get tags;
  @override
  String? get serialNumber;
  @override
  String? get locationDetail;
  @override
  String? get sectionId;
  @override
  ItemValuationModel? get valuation; // ignore: invalid_annotation_target
  @override
  @JsonKey(includeIfNull: false)
  Map<String, dynamic>? get attributes;
  @override
  List<String> get documents;
  @override
  String? get createdAt;
  @override
  String? get qrCode;

  /// Create a copy of ItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItemModelImplCopyWith<_$ItemModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
