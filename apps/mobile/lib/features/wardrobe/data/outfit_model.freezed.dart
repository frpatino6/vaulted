// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'outfit_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OutfitItemPreviewModel _$OutfitItemPreviewModelFromJson(
  Map<String, dynamic> json,
) {
  return _OutfitItemPreviewModel.fromJson(json);
}

/// @nodoc
mixin _$OutfitItemPreviewModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get photo => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  String? get type => throw _privateConstructorUsedError;
  String? get cleaningStatus => throw _privateConstructorUsedError;

  /// Serializes this OutfitItemPreviewModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OutfitItemPreviewModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OutfitItemPreviewModelCopyWith<OutfitItemPreviewModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OutfitItemPreviewModelCopyWith<$Res> {
  factory $OutfitItemPreviewModelCopyWith(
    OutfitItemPreviewModel value,
    $Res Function(OutfitItemPreviewModel) then,
  ) = _$OutfitItemPreviewModelCopyWithImpl<$Res, OutfitItemPreviewModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String? photo,
    String? category,
    String? type,
    String? cleaningStatus,
  });
}

/// @nodoc
class _$OutfitItemPreviewModelCopyWithImpl<
  $Res,
  $Val extends OutfitItemPreviewModel
>
    implements $OutfitItemPreviewModelCopyWith<$Res> {
  _$OutfitItemPreviewModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OutfitItemPreviewModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? photo = freezed,
    Object? category = freezed,
    Object? type = freezed,
    Object? cleaningStatus = freezed,
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
            photo:
                freezed == photo
                    ? _value.photo
                    : photo // ignore: cast_nullable_to_non_nullable
                        as String?,
            category:
                freezed == category
                    ? _value.category
                    : category // ignore: cast_nullable_to_non_nullable
                        as String?,
            type:
                freezed == type
                    ? _value.type
                    : type // ignore: cast_nullable_to_non_nullable
                        as String?,
            cleaningStatus:
                freezed == cleaningStatus
                    ? _value.cleaningStatus
                    : cleaningStatus // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OutfitItemPreviewModelImplCopyWith<$Res>
    implements $OutfitItemPreviewModelCopyWith<$Res> {
  factory _$$OutfitItemPreviewModelImplCopyWith(
    _$OutfitItemPreviewModelImpl value,
    $Res Function(_$OutfitItemPreviewModelImpl) then,
  ) = __$$OutfitItemPreviewModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? photo,
    String? category,
    String? type,
    String? cleaningStatus,
  });
}

/// @nodoc
class __$$OutfitItemPreviewModelImplCopyWithImpl<$Res>
    extends
        _$OutfitItemPreviewModelCopyWithImpl<$Res, _$OutfitItemPreviewModelImpl>
    implements _$$OutfitItemPreviewModelImplCopyWith<$Res> {
  __$$OutfitItemPreviewModelImplCopyWithImpl(
    _$OutfitItemPreviewModelImpl _value,
    $Res Function(_$OutfitItemPreviewModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OutfitItemPreviewModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? photo = freezed,
    Object? category = freezed,
    Object? type = freezed,
    Object? cleaningStatus = freezed,
  }) {
    return _then(
      _$OutfitItemPreviewModelImpl(
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
        photo:
            freezed == photo
                ? _value.photo
                : photo // ignore: cast_nullable_to_non_nullable
                    as String?,
        category:
            freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                    as String?,
        type:
            freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as String?,
        cleaningStatus:
            freezed == cleaningStatus
                ? _value.cleaningStatus
                : cleaningStatus // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OutfitItemPreviewModelImpl implements _OutfitItemPreviewModel {
  const _$OutfitItemPreviewModelImpl({
    required this.id,
    required this.name,
    this.photo,
    this.category,
    this.type,
    this.cleaningStatus,
  });

  factory _$OutfitItemPreviewModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$OutfitItemPreviewModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? photo;
  @override
  final String? category;
  @override
  final String? type;
  @override
  final String? cleaningStatus;

  @override
  String toString() {
    return 'OutfitItemPreviewModel(id: $id, name: $name, photo: $photo, category: $category, type: $type, cleaningStatus: $cleaningStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OutfitItemPreviewModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.photo, photo) || other.photo == photo) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.cleaningStatus, cleaningStatus) ||
                other.cleaningStatus == cleaningStatus));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, photo, category, type, cleaningStatus);

  /// Create a copy of OutfitItemPreviewModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OutfitItemPreviewModelImplCopyWith<_$OutfitItemPreviewModelImpl>
  get copyWith =>
      __$$OutfitItemPreviewModelImplCopyWithImpl<_$OutfitItemPreviewModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OutfitItemPreviewModelImplToJson(this);
  }
}

abstract class _OutfitItemPreviewModel implements OutfitItemPreviewModel {
  const factory _OutfitItemPreviewModel({
    required final String id,
    required final String name,
    final String? photo,
    final String? category,
    final String? type,
    final String? cleaningStatus,
  }) = _$OutfitItemPreviewModelImpl;

  factory _OutfitItemPreviewModel.fromJson(Map<String, dynamic> json) =
      _$OutfitItemPreviewModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get photo;
  @override
  String? get category;
  @override
  String? get type;
  @override
  String? get cleaningStatus;

  /// Create a copy of OutfitItemPreviewModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OutfitItemPreviewModelImplCopyWith<_$OutfitItemPreviewModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

OutfitModel _$OutfitModelFromJson(Map<String, dynamic> json) {
  return _OutfitModel.fromJson(json);
}

/// @nodoc
mixin _$OutfitModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  List<String> get itemIds => throw _privateConstructorUsedError;
  String? get season => throw _privateConstructorUsedError;
  String? get occasion => throw _privateConstructorUsedError;
  List<String> get photos => throw _privateConstructorUsedError;
  List<OutfitItemPreviewModel> get items => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this OutfitModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OutfitModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OutfitModelCopyWith<OutfitModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OutfitModelCopyWith<$Res> {
  factory $OutfitModelCopyWith(
    OutfitModel value,
    $Res Function(OutfitModel) then,
  ) = _$OutfitModelCopyWithImpl<$Res, OutfitModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    List<String> itemIds,
    String? season,
    String? occasion,
    List<String> photos,
    List<OutfitItemPreviewModel> items,
    String? createdAt,
  });
}

/// @nodoc
class _$OutfitModelCopyWithImpl<$Res, $Val extends OutfitModel>
    implements $OutfitModelCopyWith<$Res> {
  _$OutfitModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OutfitModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? itemIds = null,
    Object? season = freezed,
    Object? occasion = freezed,
    Object? photos = null,
    Object? items = null,
    Object? createdAt = freezed,
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
            description:
                freezed == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String?,
            itemIds:
                null == itemIds
                    ? _value.itemIds
                    : itemIds // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            season:
                freezed == season
                    ? _value.season
                    : season // ignore: cast_nullable_to_non_nullable
                        as String?,
            occasion:
                freezed == occasion
                    ? _value.occasion
                    : occasion // ignore: cast_nullable_to_non_nullable
                        as String?,
            photos:
                null == photos
                    ? _value.photos
                    : photos // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            items:
                null == items
                    ? _value.items
                    : items // ignore: cast_nullable_to_non_nullable
                        as List<OutfitItemPreviewModel>,
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
abstract class _$$OutfitModelImplCopyWith<$Res>
    implements $OutfitModelCopyWith<$Res> {
  factory _$$OutfitModelImplCopyWith(
    _$OutfitModelImpl value,
    $Res Function(_$OutfitModelImpl) then,
  ) = __$$OutfitModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    List<String> itemIds,
    String? season,
    String? occasion,
    List<String> photos,
    List<OutfitItemPreviewModel> items,
    String? createdAt,
  });
}

/// @nodoc
class __$$OutfitModelImplCopyWithImpl<$Res>
    extends _$OutfitModelCopyWithImpl<$Res, _$OutfitModelImpl>
    implements _$$OutfitModelImplCopyWith<$Res> {
  __$$OutfitModelImplCopyWithImpl(
    _$OutfitModelImpl _value,
    $Res Function(_$OutfitModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OutfitModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? itemIds = null,
    Object? season = freezed,
    Object? occasion = freezed,
    Object? photos = null,
    Object? items = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$OutfitModelImpl(
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
        description:
            freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String?,
        itemIds:
            null == itemIds
                ? _value._itemIds
                : itemIds // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        season:
            freezed == season
                ? _value.season
                : season // ignore: cast_nullable_to_non_nullable
                    as String?,
        occasion:
            freezed == occasion
                ? _value.occasion
                : occasion // ignore: cast_nullable_to_non_nullable
                    as String?,
        photos:
            null == photos
                ? _value._photos
                : photos // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        items:
            null == items
                ? _value._items
                : items // ignore: cast_nullable_to_non_nullable
                    as List<OutfitItemPreviewModel>,
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
class _$OutfitModelImpl implements _OutfitModel {
  const _$OutfitModelImpl({
    required this.id,
    required this.name,
    this.description,
    final List<String> itemIds = const <String>[],
    this.season,
    this.occasion,
    final List<String> photos = const <String>[],
    final List<OutfitItemPreviewModel> items = const <OutfitItemPreviewModel>[],
    this.createdAt,
  }) : _itemIds = itemIds,
       _photos = photos,
       _items = items;

  factory _$OutfitModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$OutfitModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  final List<String> _itemIds;
  @override
  @JsonKey()
  List<String> get itemIds {
    if (_itemIds is EqualUnmodifiableListView) return _itemIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_itemIds);
  }

  @override
  final String? season;
  @override
  final String? occasion;
  final List<String> _photos;
  @override
  @JsonKey()
  List<String> get photos {
    if (_photos is EqualUnmodifiableListView) return _photos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photos);
  }

  final List<OutfitItemPreviewModel> _items;
  @override
  @JsonKey()
  List<OutfitItemPreviewModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final String? createdAt;

  @override
  String toString() {
    return 'OutfitModel(id: $id, name: $name, description: $description, itemIds: $itemIds, season: $season, occasion: $occasion, photos: $photos, items: $items, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OutfitModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._itemIds, _itemIds) &&
            (identical(other.season, season) || other.season == season) &&
            (identical(other.occasion, occasion) ||
                other.occasion == occasion) &&
            const DeepCollectionEquality().equals(other._photos, _photos) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    const DeepCollectionEquality().hash(_itemIds),
    season,
    occasion,
    const DeepCollectionEquality().hash(_photos),
    const DeepCollectionEquality().hash(_items),
    createdAt,
  );

  /// Create a copy of OutfitModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OutfitModelImplCopyWith<_$OutfitModelImpl> get copyWith =>
      __$$OutfitModelImplCopyWithImpl<_$OutfitModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OutfitModelImplToJson(this);
  }
}

abstract class _OutfitModel implements OutfitModel {
  const factory _OutfitModel({
    required final String id,
    required final String name,
    final String? description,
    final List<String> itemIds,
    final String? season,
    final String? occasion,
    final List<String> photos,
    final List<OutfitItemPreviewModel> items,
    final String? createdAt,
  }) = _$OutfitModelImpl;

  factory _OutfitModel.fromJson(Map<String, dynamic> json) =
      _$OutfitModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  List<String> get itemIds;
  @override
  String? get season;
  @override
  String? get occasion;
  @override
  List<String> get photos;
  @override
  List<OutfitItemPreviewModel> get items;
  @override
  String? get createdAt;

  /// Create a copy of OutfitModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OutfitModelImplCopyWith<_$OutfitModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
