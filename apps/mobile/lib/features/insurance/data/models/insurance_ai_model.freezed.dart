// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'insurance_ai_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CoverageAnalysisModel _$CoverageAnalysisModelFromJson(
  Map<String, dynamic> json,
) {
  return _CoverageAnalysisModel.fromJson(json);
}

/// @nodoc
mixin _$CoverageAnalysisModel {
  String get overallRisk => throw _privateConstructorUsedError;
  String get summary => throw _privateConstructorUsedError;
  List<String> get recommendations => throw _privateConstructorUsedError;
  List<PriorityItemModel> get priorityItems =>
      throw _privateConstructorUsedError;
  String get renewalUrgency => throw _privateConstructorUsedError;

  /// Serializes this CoverageAnalysisModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CoverageAnalysisModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CoverageAnalysisModelCopyWith<CoverageAnalysisModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CoverageAnalysisModelCopyWith<$Res> {
  factory $CoverageAnalysisModelCopyWith(
    CoverageAnalysisModel value,
    $Res Function(CoverageAnalysisModel) then,
  ) = _$CoverageAnalysisModelCopyWithImpl<$Res, CoverageAnalysisModel>;
  @useResult
  $Res call({
    String overallRisk,
    String summary,
    List<String> recommendations,
    List<PriorityItemModel> priorityItems,
    String renewalUrgency,
  });
}

/// @nodoc
class _$CoverageAnalysisModelCopyWithImpl<
  $Res,
  $Val extends CoverageAnalysisModel
>
    implements $CoverageAnalysisModelCopyWith<$Res> {
  _$CoverageAnalysisModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CoverageAnalysisModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? overallRisk = null,
    Object? summary = null,
    Object? recommendations = null,
    Object? priorityItems = null,
    Object? renewalUrgency = null,
  }) {
    return _then(
      _value.copyWith(
            overallRisk:
                null == overallRisk
                    ? _value.overallRisk
                    : overallRisk // ignore: cast_nullable_to_non_nullable
                        as String,
            summary:
                null == summary
                    ? _value.summary
                    : summary // ignore: cast_nullable_to_non_nullable
                        as String,
            recommendations:
                null == recommendations
                    ? _value.recommendations
                    : recommendations // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            priorityItems:
                null == priorityItems
                    ? _value.priorityItems
                    : priorityItems // ignore: cast_nullable_to_non_nullable
                        as List<PriorityItemModel>,
            renewalUrgency:
                null == renewalUrgency
                    ? _value.renewalUrgency
                    : renewalUrgency // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CoverageAnalysisModelImplCopyWith<$Res>
    implements $CoverageAnalysisModelCopyWith<$Res> {
  factory _$$CoverageAnalysisModelImplCopyWith(
    _$CoverageAnalysisModelImpl value,
    $Res Function(_$CoverageAnalysisModelImpl) then,
  ) = __$$CoverageAnalysisModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String overallRisk,
    String summary,
    List<String> recommendations,
    List<PriorityItemModel> priorityItems,
    String renewalUrgency,
  });
}

/// @nodoc
class __$$CoverageAnalysisModelImplCopyWithImpl<$Res>
    extends
        _$CoverageAnalysisModelCopyWithImpl<$Res, _$CoverageAnalysisModelImpl>
    implements _$$CoverageAnalysisModelImplCopyWith<$Res> {
  __$$CoverageAnalysisModelImplCopyWithImpl(
    _$CoverageAnalysisModelImpl _value,
    $Res Function(_$CoverageAnalysisModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CoverageAnalysisModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? overallRisk = null,
    Object? summary = null,
    Object? recommendations = null,
    Object? priorityItems = null,
    Object? renewalUrgency = null,
  }) {
    return _then(
      _$CoverageAnalysisModelImpl(
        overallRisk:
            null == overallRisk
                ? _value.overallRisk
                : overallRisk // ignore: cast_nullable_to_non_nullable
                    as String,
        summary:
            null == summary
                ? _value.summary
                : summary // ignore: cast_nullable_to_non_nullable
                    as String,
        recommendations:
            null == recommendations
                ? _value._recommendations
                : recommendations // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        priorityItems:
            null == priorityItems
                ? _value._priorityItems
                : priorityItems // ignore: cast_nullable_to_non_nullable
                    as List<PriorityItemModel>,
        renewalUrgency:
            null == renewalUrgency
                ? _value.renewalUrgency
                : renewalUrgency // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CoverageAnalysisModelImpl implements _CoverageAnalysisModel {
  const _$CoverageAnalysisModelImpl({
    required this.overallRisk,
    required this.summary,
    final List<String> recommendations = const [],
    final List<PriorityItemModel> priorityItems = const [],
    required this.renewalUrgency,
  }) : _recommendations = recommendations,
       _priorityItems = priorityItems;

  factory _$CoverageAnalysisModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CoverageAnalysisModelImplFromJson(json);

  @override
  final String overallRisk;
  @override
  final String summary;
  final List<String> _recommendations;
  @override
  @JsonKey()
  List<String> get recommendations {
    if (_recommendations is EqualUnmodifiableListView) return _recommendations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recommendations);
  }

  final List<PriorityItemModel> _priorityItems;
  @override
  @JsonKey()
  List<PriorityItemModel> get priorityItems {
    if (_priorityItems is EqualUnmodifiableListView) return _priorityItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_priorityItems);
  }

  @override
  final String renewalUrgency;

  @override
  String toString() {
    return 'CoverageAnalysisModel(overallRisk: $overallRisk, summary: $summary, recommendations: $recommendations, priorityItems: $priorityItems, renewalUrgency: $renewalUrgency)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CoverageAnalysisModelImpl &&
            (identical(other.overallRisk, overallRisk) ||
                other.overallRisk == overallRisk) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            const DeepCollectionEquality().equals(
              other._recommendations,
              _recommendations,
            ) &&
            const DeepCollectionEquality().equals(
              other._priorityItems,
              _priorityItems,
            ) &&
            (identical(other.renewalUrgency, renewalUrgency) ||
                other.renewalUrgency == renewalUrgency));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    overallRisk,
    summary,
    const DeepCollectionEquality().hash(_recommendations),
    const DeepCollectionEquality().hash(_priorityItems),
    renewalUrgency,
  );

  /// Create a copy of CoverageAnalysisModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CoverageAnalysisModelImplCopyWith<_$CoverageAnalysisModelImpl>
  get copyWith =>
      __$$CoverageAnalysisModelImplCopyWithImpl<_$CoverageAnalysisModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CoverageAnalysisModelImplToJson(this);
  }
}

abstract class _CoverageAnalysisModel implements CoverageAnalysisModel {
  const factory _CoverageAnalysisModel({
    required final String overallRisk,
    required final String summary,
    final List<String> recommendations,
    final List<PriorityItemModel> priorityItems,
    required final String renewalUrgency,
  }) = _$CoverageAnalysisModelImpl;

  factory _CoverageAnalysisModel.fromJson(Map<String, dynamic> json) =
      _$CoverageAnalysisModelImpl.fromJson;

  @override
  String get overallRisk;
  @override
  String get summary;
  @override
  List<String> get recommendations;
  @override
  List<PriorityItemModel> get priorityItems;
  @override
  String get renewalUrgency;

  /// Create a copy of CoverageAnalysisModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CoverageAnalysisModelImplCopyWith<_$CoverageAnalysisModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

PriorityItemModel _$PriorityItemModelFromJson(Map<String, dynamic> json) {
  return _PriorityItemModel.fromJson(json);
}

/// @nodoc
mixin _$PriorityItemModel {
  String get itemId => throw _privateConstructorUsedError;
  String get itemName => throw _privateConstructorUsedError;
  String get issue => throw _privateConstructorUsedError;

  /// Serializes this PriorityItemModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PriorityItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PriorityItemModelCopyWith<PriorityItemModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PriorityItemModelCopyWith<$Res> {
  factory $PriorityItemModelCopyWith(
    PriorityItemModel value,
    $Res Function(PriorityItemModel) then,
  ) = _$PriorityItemModelCopyWithImpl<$Res, PriorityItemModel>;
  @useResult
  $Res call({String itemId, String itemName, String issue});
}

/// @nodoc
class _$PriorityItemModelCopyWithImpl<$Res, $Val extends PriorityItemModel>
    implements $PriorityItemModelCopyWith<$Res> {
  _$PriorityItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PriorityItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? itemName = null,
    Object? issue = null,
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
            issue:
                null == issue
                    ? _value.issue
                    : issue // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PriorityItemModelImplCopyWith<$Res>
    implements $PriorityItemModelCopyWith<$Res> {
  factory _$$PriorityItemModelImplCopyWith(
    _$PriorityItemModelImpl value,
    $Res Function(_$PriorityItemModelImpl) then,
  ) = __$$PriorityItemModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String itemId, String itemName, String issue});
}

/// @nodoc
class __$$PriorityItemModelImplCopyWithImpl<$Res>
    extends _$PriorityItemModelCopyWithImpl<$Res, _$PriorityItemModelImpl>
    implements _$$PriorityItemModelImplCopyWith<$Res> {
  __$$PriorityItemModelImplCopyWithImpl(
    _$PriorityItemModelImpl _value,
    $Res Function(_$PriorityItemModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PriorityItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? itemName = null,
    Object? issue = null,
  }) {
    return _then(
      _$PriorityItemModelImpl(
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
        issue:
            null == issue
                ? _value.issue
                : issue // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PriorityItemModelImpl implements _PriorityItemModel {
  const _$PriorityItemModelImpl({
    required this.itemId,
    required this.itemName,
    required this.issue,
  });

  factory _$PriorityItemModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PriorityItemModelImplFromJson(json);

  @override
  final String itemId;
  @override
  final String itemName;
  @override
  final String issue;

  @override
  String toString() {
    return 'PriorityItemModel(itemId: $itemId, itemName: $itemName, issue: $issue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PriorityItemModelImpl &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.issue, issue) || other.issue == issue));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, itemId, itemName, issue);

  /// Create a copy of PriorityItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PriorityItemModelImplCopyWith<_$PriorityItemModelImpl> get copyWith =>
      __$$PriorityItemModelImplCopyWithImpl<_$PriorityItemModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PriorityItemModelImplToJson(this);
  }
}

abstract class _PriorityItemModel implements PriorityItemModel {
  const factory _PriorityItemModel({
    required final String itemId,
    required final String itemName,
    required final String issue,
  }) = _$PriorityItemModelImpl;

  factory _PriorityItemModel.fromJson(Map<String, dynamic> json) =
      _$PriorityItemModelImpl.fromJson;

  @override
  String get itemId;
  @override
  String get itemName;
  @override
  String get issue;

  /// Create a copy of PriorityItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PriorityItemModelImplCopyWith<_$PriorityItemModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ClaimDraftModel _$ClaimDraftModelFromJson(Map<String, dynamic> json) {
  return _ClaimDraftModel.fromJson(json);
}

/// @nodoc
mixin _$ClaimDraftModel {
  String get subject => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  List<String> get keyPoints => throw _privateConstructorUsedError;
  List<String> get nextSteps => throw _privateConstructorUsedError;

  /// Serializes this ClaimDraftModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClaimDraftModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClaimDraftModelCopyWith<ClaimDraftModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClaimDraftModelCopyWith<$Res> {
  factory $ClaimDraftModelCopyWith(
    ClaimDraftModel value,
    $Res Function(ClaimDraftModel) then,
  ) = _$ClaimDraftModelCopyWithImpl<$Res, ClaimDraftModel>;
  @useResult
  $Res call({
    String subject,
    String body,
    List<String> keyPoints,
    List<String> nextSteps,
  });
}

/// @nodoc
class _$ClaimDraftModelCopyWithImpl<$Res, $Val extends ClaimDraftModel>
    implements $ClaimDraftModelCopyWith<$Res> {
  _$ClaimDraftModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClaimDraftModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subject = null,
    Object? body = null,
    Object? keyPoints = null,
    Object? nextSteps = null,
  }) {
    return _then(
      _value.copyWith(
            subject:
                null == subject
                    ? _value.subject
                    : subject // ignore: cast_nullable_to_non_nullable
                        as String,
            body:
                null == body
                    ? _value.body
                    : body // ignore: cast_nullable_to_non_nullable
                        as String,
            keyPoints:
                null == keyPoints
                    ? _value.keyPoints
                    : keyPoints // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            nextSteps:
                null == nextSteps
                    ? _value.nextSteps
                    : nextSteps // ignore: cast_nullable_to_non_nullable
                        as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ClaimDraftModelImplCopyWith<$Res>
    implements $ClaimDraftModelCopyWith<$Res> {
  factory _$$ClaimDraftModelImplCopyWith(
    _$ClaimDraftModelImpl value,
    $Res Function(_$ClaimDraftModelImpl) then,
  ) = __$$ClaimDraftModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String subject,
    String body,
    List<String> keyPoints,
    List<String> nextSteps,
  });
}

/// @nodoc
class __$$ClaimDraftModelImplCopyWithImpl<$Res>
    extends _$ClaimDraftModelCopyWithImpl<$Res, _$ClaimDraftModelImpl>
    implements _$$ClaimDraftModelImplCopyWith<$Res> {
  __$$ClaimDraftModelImplCopyWithImpl(
    _$ClaimDraftModelImpl _value,
    $Res Function(_$ClaimDraftModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ClaimDraftModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subject = null,
    Object? body = null,
    Object? keyPoints = null,
    Object? nextSteps = null,
  }) {
    return _then(
      _$ClaimDraftModelImpl(
        subject:
            null == subject
                ? _value.subject
                : subject // ignore: cast_nullable_to_non_nullable
                    as String,
        body:
            null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                    as String,
        keyPoints:
            null == keyPoints
                ? _value._keyPoints
                : keyPoints // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        nextSteps:
            null == nextSteps
                ? _value._nextSteps
                : nextSteps // ignore: cast_nullable_to_non_nullable
                    as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ClaimDraftModelImpl implements _ClaimDraftModel {
  const _$ClaimDraftModelImpl({
    required this.subject,
    required this.body,
    final List<String> keyPoints = const [],
    final List<String> nextSteps = const [],
  }) : _keyPoints = keyPoints,
       _nextSteps = nextSteps;

  factory _$ClaimDraftModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClaimDraftModelImplFromJson(json);

  @override
  final String subject;
  @override
  final String body;
  final List<String> _keyPoints;
  @override
  @JsonKey()
  List<String> get keyPoints {
    if (_keyPoints is EqualUnmodifiableListView) return _keyPoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_keyPoints);
  }

  final List<String> _nextSteps;
  @override
  @JsonKey()
  List<String> get nextSteps {
    if (_nextSteps is EqualUnmodifiableListView) return _nextSteps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nextSteps);
  }

  @override
  String toString() {
    return 'ClaimDraftModel(subject: $subject, body: $body, keyPoints: $keyPoints, nextSteps: $nextSteps)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClaimDraftModelImpl &&
            (identical(other.subject, subject) || other.subject == subject) &&
            (identical(other.body, body) || other.body == body) &&
            const DeepCollectionEquality().equals(
              other._keyPoints,
              _keyPoints,
            ) &&
            const DeepCollectionEquality().equals(
              other._nextSteps,
              _nextSteps,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    subject,
    body,
    const DeepCollectionEquality().hash(_keyPoints),
    const DeepCollectionEquality().hash(_nextSteps),
  );

  /// Create a copy of ClaimDraftModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClaimDraftModelImplCopyWith<_$ClaimDraftModelImpl> get copyWith =>
      __$$ClaimDraftModelImplCopyWithImpl<_$ClaimDraftModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ClaimDraftModelImplToJson(this);
  }
}

abstract class _ClaimDraftModel implements ClaimDraftModel {
  const factory _ClaimDraftModel({
    required final String subject,
    required final String body,
    final List<String> keyPoints,
    final List<String> nextSteps,
  }) = _$ClaimDraftModelImpl;

  factory _ClaimDraftModel.fromJson(Map<String, dynamic> json) =
      _$ClaimDraftModelImpl.fromJson;

  @override
  String get subject;
  @override
  String get body;
  @override
  List<String> get keyPoints;
  @override
  List<String> get nextSteps;

  /// Create a copy of ClaimDraftModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClaimDraftModelImplCopyWith<_$ClaimDraftModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
