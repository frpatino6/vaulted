// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ChatItemResult _$ChatItemResultFromJson(Map<String, dynamic> json) {
  return _ChatItemResult.fromJson(json);
}

/// @nodoc
mixin _$ChatItemResult {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get propertyName => throw _privateConstructorUsedError;
  String? get roomName => throw _privateConstructorUsedError;
  List<String> get photos => throw _privateConstructorUsedError;
  ChatItemValuation? get valuation => throw _privateConstructorUsedError;
  double get score => throw _privateConstructorUsedError;

  /// Serializes this ChatItemResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatItemResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatItemResultCopyWith<ChatItemResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatItemResultCopyWith<$Res> {
  factory $ChatItemResultCopyWith(
    ChatItemResult value,
    $Res Function(ChatItemResult) then,
  ) = _$ChatItemResultCopyWithImpl<$Res, ChatItemResult>;
  @useResult
  $Res call({
    String id,
    String name,
    String category,
    String status,
    String? propertyName,
    String? roomName,
    List<String> photos,
    ChatItemValuation? valuation,
    double score,
  });

  $ChatItemValuationCopyWith<$Res>? get valuation;
}

/// @nodoc
class _$ChatItemResultCopyWithImpl<$Res, $Val extends ChatItemResult>
    implements $ChatItemResultCopyWith<$Res> {
  _$ChatItemResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatItemResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? status = null,
    Object? propertyName = freezed,
    Object? roomName = freezed,
    Object? photos = null,
    Object? valuation = freezed,
    Object? score = null,
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
            category:
                null == category
                    ? _value.category
                    : category // ignore: cast_nullable_to_non_nullable
                        as String,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            propertyName:
                freezed == propertyName
                    ? _value.propertyName
                    : propertyName // ignore: cast_nullable_to_non_nullable
                        as String?,
            roomName:
                freezed == roomName
                    ? _value.roomName
                    : roomName // ignore: cast_nullable_to_non_nullable
                        as String?,
            photos:
                null == photos
                    ? _value.photos
                    : photos // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            valuation:
                freezed == valuation
                    ? _value.valuation
                    : valuation // ignore: cast_nullable_to_non_nullable
                        as ChatItemValuation?,
            score:
                null == score
                    ? _value.score
                    : score // ignore: cast_nullable_to_non_nullable
                        as double,
          )
          as $Val,
    );
  }

  /// Create a copy of ChatItemResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ChatItemValuationCopyWith<$Res>? get valuation {
    if (_value.valuation == null) {
      return null;
    }

    return $ChatItemValuationCopyWith<$Res>(_value.valuation!, (value) {
      return _then(_value.copyWith(valuation: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ChatItemResultImplCopyWith<$Res>
    implements $ChatItemResultCopyWith<$Res> {
  factory _$$ChatItemResultImplCopyWith(
    _$ChatItemResultImpl value,
    $Res Function(_$ChatItemResultImpl) then,
  ) = __$$ChatItemResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String category,
    String status,
    String? propertyName,
    String? roomName,
    List<String> photos,
    ChatItemValuation? valuation,
    double score,
  });

  @override
  $ChatItemValuationCopyWith<$Res>? get valuation;
}

/// @nodoc
class __$$ChatItemResultImplCopyWithImpl<$Res>
    extends _$ChatItemResultCopyWithImpl<$Res, _$ChatItemResultImpl>
    implements _$$ChatItemResultImplCopyWith<$Res> {
  __$$ChatItemResultImplCopyWithImpl(
    _$ChatItemResultImpl _value,
    $Res Function(_$ChatItemResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatItemResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? status = null,
    Object? propertyName = freezed,
    Object? roomName = freezed,
    Object? photos = null,
    Object? valuation = freezed,
    Object? score = null,
  }) {
    return _then(
      _$ChatItemResultImpl(
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
        category:
            null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                    as String,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
        propertyName:
            freezed == propertyName
                ? _value.propertyName
                : propertyName // ignore: cast_nullable_to_non_nullable
                    as String?,
        roomName:
            freezed == roomName
                ? _value.roomName
                : roomName // ignore: cast_nullable_to_non_nullable
                    as String?,
        photos:
            null == photos
                ? _value._photos
                : photos // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        valuation:
            freezed == valuation
                ? _value.valuation
                : valuation // ignore: cast_nullable_to_non_nullable
                    as ChatItemValuation?,
        score:
            null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                    as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatItemResultImpl implements _ChatItemResult {
  const _$ChatItemResultImpl({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    this.propertyName,
    this.roomName,
    final List<String> photos = const [],
    this.valuation,
    this.score = 0.0,
  }) : _photos = photos;

  factory _$ChatItemResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatItemResultImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String category;
  @override
  final String status;
  @override
  final String? propertyName;
  @override
  final String? roomName;
  final List<String> _photos;
  @override
  @JsonKey()
  List<String> get photos {
    if (_photos is EqualUnmodifiableListView) return _photos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_photos);
  }

  @override
  final ChatItemValuation? valuation;
  @override
  @JsonKey()
  final double score;

  @override
  String toString() {
    return 'ChatItemResult(id: $id, name: $name, category: $category, status: $status, propertyName: $propertyName, roomName: $roomName, photos: $photos, valuation: $valuation, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatItemResultImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.propertyName, propertyName) ||
                other.propertyName == propertyName) &&
            (identical(other.roomName, roomName) ||
                other.roomName == roomName) &&
            const DeepCollectionEquality().equals(other._photos, _photos) &&
            (identical(other.valuation, valuation) ||
                other.valuation == valuation) &&
            (identical(other.score, score) || other.score == score));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    category,
    status,
    propertyName,
    roomName,
    const DeepCollectionEquality().hash(_photos),
    valuation,
    score,
  );

  /// Create a copy of ChatItemResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatItemResultImplCopyWith<_$ChatItemResultImpl> get copyWith =>
      __$$ChatItemResultImplCopyWithImpl<_$ChatItemResultImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatItemResultImplToJson(this);
  }
}

abstract class _ChatItemResult implements ChatItemResult {
  const factory _ChatItemResult({
    required final String id,
    required final String name,
    required final String category,
    required final String status,
    final String? propertyName,
    final String? roomName,
    final List<String> photos,
    final ChatItemValuation? valuation,
    final double score,
  }) = _$ChatItemResultImpl;

  factory _ChatItemResult.fromJson(Map<String, dynamic> json) =
      _$ChatItemResultImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get category;
  @override
  String get status;
  @override
  String? get propertyName;
  @override
  String? get roomName;
  @override
  List<String> get photos;
  @override
  ChatItemValuation? get valuation;
  @override
  double get score;

  /// Create a copy of ChatItemResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatItemResultImplCopyWith<_$ChatItemResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChatItemValuation _$ChatItemValuationFromJson(Map<String, dynamic> json) {
  return _ChatItemValuation.fromJson(json);
}

/// @nodoc
mixin _$ChatItemValuation {
  int get currentValue => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;

  /// Serializes this ChatItemValuation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatItemValuation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatItemValuationCopyWith<ChatItemValuation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatItemValuationCopyWith<$Res> {
  factory $ChatItemValuationCopyWith(
    ChatItemValuation value,
    $Res Function(ChatItemValuation) then,
  ) = _$ChatItemValuationCopyWithImpl<$Res, ChatItemValuation>;
  @useResult
  $Res call({int currentValue, String currency});
}

/// @nodoc
class _$ChatItemValuationCopyWithImpl<$Res, $Val extends ChatItemValuation>
    implements $ChatItemValuationCopyWith<$Res> {
  _$ChatItemValuationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatItemValuation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? currentValue = null, Object? currency = null}) {
    return _then(
      _value.copyWith(
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChatItemValuationImplCopyWith<$Res>
    implements $ChatItemValuationCopyWith<$Res> {
  factory _$$ChatItemValuationImplCopyWith(
    _$ChatItemValuationImpl value,
    $Res Function(_$ChatItemValuationImpl) then,
  ) = __$$ChatItemValuationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int currentValue, String currency});
}

/// @nodoc
class __$$ChatItemValuationImplCopyWithImpl<$Res>
    extends _$ChatItemValuationCopyWithImpl<$Res, _$ChatItemValuationImpl>
    implements _$$ChatItemValuationImplCopyWith<$Res> {
  __$$ChatItemValuationImplCopyWithImpl(
    _$ChatItemValuationImpl _value,
    $Res Function(_$ChatItemValuationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatItemValuation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? currentValue = null, Object? currency = null}) {
    return _then(
      _$ChatItemValuationImpl(
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatItemValuationImpl implements _ChatItemValuation {
  const _$ChatItemValuationImpl({
    required this.currentValue,
    this.currency = 'USD',
  });

  factory _$ChatItemValuationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatItemValuationImplFromJson(json);

  @override
  final int currentValue;
  @override
  @JsonKey()
  final String currency;

  @override
  String toString() {
    return 'ChatItemValuation(currentValue: $currentValue, currency: $currency)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatItemValuationImpl &&
            (identical(other.currentValue, currentValue) ||
                other.currentValue == currentValue) &&
            (identical(other.currency, currency) ||
                other.currency == currency));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, currentValue, currency);

  /// Create a copy of ChatItemValuation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatItemValuationImplCopyWith<_$ChatItemValuationImpl> get copyWith =>
      __$$ChatItemValuationImplCopyWithImpl<_$ChatItemValuationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatItemValuationImplToJson(this);
  }
}

abstract class _ChatItemValuation implements ChatItemValuation {
  const factory _ChatItemValuation({
    required final int currentValue,
    final String currency,
  }) = _$ChatItemValuationImpl;

  factory _ChatItemValuation.fromJson(Map<String, dynamic> json) =
      _$ChatItemValuationImpl.fromJson;

  @override
  int get currentValue;
  @override
  String get currency;

  /// Create a copy of ChatItemValuation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatItemValuationImplCopyWith<_$ChatItemValuationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChatMessageModel _$ChatMessageModelFromJson(Map<String, dynamic> json) {
  return _ChatMessageModel.fromJson(json);
}

/// @nodoc
mixin _$ChatMessageModel {
  String get id => throw _privateConstructorUsedError;
  ChatRole get role => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  List<ChatItemResult> get items => throw _privateConstructorUsedError;
  List<String> get sources => throw _privateConstructorUsedError;
  String? get sessionId => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Serializes this ChatMessageModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatMessageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatMessageModelCopyWith<ChatMessageModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatMessageModelCopyWith<$Res> {
  factory $ChatMessageModelCopyWith(
    ChatMessageModel value,
    $Res Function(ChatMessageModel) then,
  ) = _$ChatMessageModelCopyWithImpl<$Res, ChatMessageModel>;
  @useResult
  $Res call({
    String id,
    ChatRole role,
    String content,
    List<ChatItemResult> items,
    List<String> sources,
    String? sessionId,
    DateTime? createdAt,
    bool isLoading,
  });
}

/// @nodoc
class _$ChatMessageModelCopyWithImpl<$Res, $Val extends ChatMessageModel>
    implements $ChatMessageModelCopyWith<$Res> {
  _$ChatMessageModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatMessageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? role = null,
    Object? content = null,
    Object? items = null,
    Object? sources = null,
    Object? sessionId = freezed,
    Object? createdAt = freezed,
    Object? isLoading = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            role:
                null == role
                    ? _value.role
                    : role // ignore: cast_nullable_to_non_nullable
                        as ChatRole,
            content:
                null == content
                    ? _value.content
                    : content // ignore: cast_nullable_to_non_nullable
                        as String,
            items:
                null == items
                    ? _value.items
                    : items // ignore: cast_nullable_to_non_nullable
                        as List<ChatItemResult>,
            sources:
                null == sources
                    ? _value.sources
                    : sources // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            sessionId:
                freezed == sessionId
                    ? _value.sessionId
                    : sessionId // ignore: cast_nullable_to_non_nullable
                        as String?,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            isLoading:
                null == isLoading
                    ? _value.isLoading
                    : isLoading // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChatMessageModelImplCopyWith<$Res>
    implements $ChatMessageModelCopyWith<$Res> {
  factory _$$ChatMessageModelImplCopyWith(
    _$ChatMessageModelImpl value,
    $Res Function(_$ChatMessageModelImpl) then,
  ) = __$$ChatMessageModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    ChatRole role,
    String content,
    List<ChatItemResult> items,
    List<String> sources,
    String? sessionId,
    DateTime? createdAt,
    bool isLoading,
  });
}

/// @nodoc
class __$$ChatMessageModelImplCopyWithImpl<$Res>
    extends _$ChatMessageModelCopyWithImpl<$Res, _$ChatMessageModelImpl>
    implements _$$ChatMessageModelImplCopyWith<$Res> {
  __$$ChatMessageModelImplCopyWithImpl(
    _$ChatMessageModelImpl _value,
    $Res Function(_$ChatMessageModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatMessageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? role = null,
    Object? content = null,
    Object? items = null,
    Object? sources = null,
    Object? sessionId = freezed,
    Object? createdAt = freezed,
    Object? isLoading = null,
  }) {
    return _then(
      _$ChatMessageModelImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        role:
            null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                    as ChatRole,
        content:
            null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                    as String,
        items:
            null == items
                ? _value._items
                : items // ignore: cast_nullable_to_non_nullable
                    as List<ChatItemResult>,
        sources:
            null == sources
                ? _value._sources
                : sources // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        sessionId:
            freezed == sessionId
                ? _value.sessionId
                : sessionId // ignore: cast_nullable_to_non_nullable
                    as String?,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        isLoading:
            null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatMessageModelImpl implements _ChatMessageModel {
  const _$ChatMessageModelImpl({
    required this.id,
    required this.role,
    required this.content,
    final List<ChatItemResult> items = const [],
    final List<String> sources = const [],
    this.sessionId,
    this.createdAt,
    this.isLoading = false,
  }) : _items = items,
       _sources = sources;

  factory _$ChatMessageModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatMessageModelImplFromJson(json);

  @override
  final String id;
  @override
  final ChatRole role;
  @override
  final String content;
  final List<ChatItemResult> _items;
  @override
  @JsonKey()
  List<ChatItemResult> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  final List<String> _sources;
  @override
  @JsonKey()
  List<String> get sources {
    if (_sources is EqualUnmodifiableListView) return _sources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sources);
  }

  @override
  final String? sessionId;
  @override
  final DateTime? createdAt;
  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'ChatMessageModel(id: $id, role: $role, content: $content, items: $items, sources: $sources, sessionId: $sessionId, createdAt: $createdAt, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMessageModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            const DeepCollectionEquality().equals(other._sources, _sources) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    role,
    content,
    const DeepCollectionEquality().hash(_items),
    const DeepCollectionEquality().hash(_sources),
    sessionId,
    createdAt,
    isLoading,
  );

  /// Create a copy of ChatMessageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMessageModelImplCopyWith<_$ChatMessageModelImpl> get copyWith =>
      __$$ChatMessageModelImplCopyWithImpl<_$ChatMessageModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatMessageModelImplToJson(this);
  }
}

abstract class _ChatMessageModel implements ChatMessageModel {
  const factory _ChatMessageModel({
    required final String id,
    required final ChatRole role,
    required final String content,
    final List<ChatItemResult> items,
    final List<String> sources,
    final String? sessionId,
    final DateTime? createdAt,
    final bool isLoading,
  }) = _$ChatMessageModelImpl;

  factory _ChatMessageModel.fromJson(Map<String, dynamic> json) =
      _$ChatMessageModelImpl.fromJson;

  @override
  String get id;
  @override
  ChatRole get role;
  @override
  String get content;
  @override
  List<ChatItemResult> get items;
  @override
  List<String> get sources;
  @override
  String? get sessionId;
  @override
  DateTime? get createdAt;
  @override
  bool get isLoading;

  /// Create a copy of ChatMessageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatMessageModelImplCopyWith<_$ChatMessageModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
