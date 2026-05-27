// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'orchestrator_plan_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OrchestratorStepModel _$OrchestratorStepModelFromJson(
  Map<String, dynamic> json,
) {
  return _OrchestratorStepModel.fromJson(json);
}

/// @nodoc
mixin _$OrchestratorStepModel {
  String get stepId => throw _privateConstructorUsedError;
  String get itemId => throw _privateConstructorUsedError;
  String get itemName => throw _privateConstructorUsedError;
  String get itemCategory => throw _privateConstructorUsedError;
  String? get itemPhoto => throw _privateConstructorUsedError;
  String? get roomId => throw _privateConstructorUsedError;
  String? get roomName => throw _privateConstructorUsedError;
  String? get roomPhoto => throw _privateConstructorUsedError;
  String? get sectionId => throw _privateConstructorUsedError;
  String? get sectionPhoto => throw _privateConstructorUsedError;
  String? get sectionCode => throw _privateConstructorUsedError;
  String? get sectionFurnitureName => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _boundingBoxFromJson, toJson: _boundingBoxToJson)
  SectionBoundingBox? get boundingBox => throw _privateConstructorUsedError;
  String get instruction => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get completedByUserId => throw _privateConstructorUsedError;
  String? get completedAt => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  String? get completionPhotoUrl => throw _privateConstructorUsedError;

  /// Serializes this OrchestratorStepModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrchestratorStepModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrchestratorStepModelCopyWith<OrchestratorStepModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrchestratorStepModelCopyWith<$Res> {
  factory $OrchestratorStepModelCopyWith(
    OrchestratorStepModel value,
    $Res Function(OrchestratorStepModel) then,
  ) = _$OrchestratorStepModelCopyWithImpl<$Res, OrchestratorStepModel>;
  @useResult
  $Res call({
    String stepId,
    String itemId,
    String itemName,
    String itemCategory,
    String? itemPhoto,
    String? roomId,
    String? roomName,
    String? roomPhoto,
    String? sectionId,
    String? sectionPhoto,
    String? sectionCode,
    String? sectionFurnitureName,
    @JsonKey(fromJson: _boundingBoxFromJson, toJson: _boundingBoxToJson)
    SectionBoundingBox? boundingBox,
    String instruction,
    String status,
    String? completedByUserId,
    String? completedAt,
    String? note,
    String? completionPhotoUrl,
  });
}

/// @nodoc
class _$OrchestratorStepModelCopyWithImpl<
  $Res,
  $Val extends OrchestratorStepModel
>
    implements $OrchestratorStepModelCopyWith<$Res> {
  _$OrchestratorStepModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrchestratorStepModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stepId = null,
    Object? itemId = null,
    Object? itemName = null,
    Object? itemCategory = null,
    Object? itemPhoto = freezed,
    Object? roomId = freezed,
    Object? roomName = freezed,
    Object? roomPhoto = freezed,
    Object? sectionId = freezed,
    Object? sectionPhoto = freezed,
    Object? sectionCode = freezed,
    Object? sectionFurnitureName = freezed,
    Object? boundingBox = freezed,
    Object? instruction = null,
    Object? status = null,
    Object? completedByUserId = freezed,
    Object? completedAt = freezed,
    Object? note = freezed,
    Object? completionPhotoUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            stepId:
                null == stepId
                    ? _value.stepId
                    : stepId // ignore: cast_nullable_to_non_nullable
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
            itemCategory:
                null == itemCategory
                    ? _value.itemCategory
                    : itemCategory // ignore: cast_nullable_to_non_nullable
                        as String,
            itemPhoto:
                freezed == itemPhoto
                    ? _value.itemPhoto
                    : itemPhoto // ignore: cast_nullable_to_non_nullable
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
            roomPhoto:
                freezed == roomPhoto
                    ? _value.roomPhoto
                    : roomPhoto // ignore: cast_nullable_to_non_nullable
                        as String?,
            sectionId:
                freezed == sectionId
                    ? _value.sectionId
                    : sectionId // ignore: cast_nullable_to_non_nullable
                        as String?,
            sectionPhoto:
                freezed == sectionPhoto
                    ? _value.sectionPhoto
                    : sectionPhoto // ignore: cast_nullable_to_non_nullable
                        as String?,
            sectionCode:
                freezed == sectionCode
                    ? _value.sectionCode
                    : sectionCode // ignore: cast_nullable_to_non_nullable
                        as String?,
            sectionFurnitureName:
                freezed == sectionFurnitureName
                    ? _value.sectionFurnitureName
                    : sectionFurnitureName // ignore: cast_nullable_to_non_nullable
                        as String?,
            boundingBox:
                freezed == boundingBox
                    ? _value.boundingBox
                    : boundingBox // ignore: cast_nullable_to_non_nullable
                        as SectionBoundingBox?,
            instruction:
                null == instruction
                    ? _value.instruction
                    : instruction // ignore: cast_nullable_to_non_nullable
                        as String,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            completedByUserId:
                freezed == completedByUserId
                    ? _value.completedByUserId
                    : completedByUserId // ignore: cast_nullable_to_non_nullable
                        as String?,
            completedAt:
                freezed == completedAt
                    ? _value.completedAt
                    : completedAt // ignore: cast_nullable_to_non_nullable
                        as String?,
            note:
                freezed == note
                    ? _value.note
                    : note // ignore: cast_nullable_to_non_nullable
                        as String?,
            completionPhotoUrl:
                freezed == completionPhotoUrl
                    ? _value.completionPhotoUrl
                    : completionPhotoUrl // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OrchestratorStepModelImplCopyWith<$Res>
    implements $OrchestratorStepModelCopyWith<$Res> {
  factory _$$OrchestratorStepModelImplCopyWith(
    _$OrchestratorStepModelImpl value,
    $Res Function(_$OrchestratorStepModelImpl) then,
  ) = __$$OrchestratorStepModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String stepId,
    String itemId,
    String itemName,
    String itemCategory,
    String? itemPhoto,
    String? roomId,
    String? roomName,
    String? roomPhoto,
    String? sectionId,
    String? sectionPhoto,
    String? sectionCode,
    String? sectionFurnitureName,
    @JsonKey(fromJson: _boundingBoxFromJson, toJson: _boundingBoxToJson)
    SectionBoundingBox? boundingBox,
    String instruction,
    String status,
    String? completedByUserId,
    String? completedAt,
    String? note,
    String? completionPhotoUrl,
  });
}

/// @nodoc
class __$$OrchestratorStepModelImplCopyWithImpl<$Res>
    extends
        _$OrchestratorStepModelCopyWithImpl<$Res, _$OrchestratorStepModelImpl>
    implements _$$OrchestratorStepModelImplCopyWith<$Res> {
  __$$OrchestratorStepModelImplCopyWithImpl(
    _$OrchestratorStepModelImpl _value,
    $Res Function(_$OrchestratorStepModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OrchestratorStepModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stepId = null,
    Object? itemId = null,
    Object? itemName = null,
    Object? itemCategory = null,
    Object? itemPhoto = freezed,
    Object? roomId = freezed,
    Object? roomName = freezed,
    Object? roomPhoto = freezed,
    Object? sectionId = freezed,
    Object? sectionPhoto = freezed,
    Object? sectionCode = freezed,
    Object? sectionFurnitureName = freezed,
    Object? boundingBox = freezed,
    Object? instruction = null,
    Object? status = null,
    Object? completedByUserId = freezed,
    Object? completedAt = freezed,
    Object? note = freezed,
    Object? completionPhotoUrl = freezed,
  }) {
    return _then(
      _$OrchestratorStepModelImpl(
        stepId:
            null == stepId
                ? _value.stepId
                : stepId // ignore: cast_nullable_to_non_nullable
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
        itemCategory:
            null == itemCategory
                ? _value.itemCategory
                : itemCategory // ignore: cast_nullable_to_non_nullable
                    as String,
        itemPhoto:
            freezed == itemPhoto
                ? _value.itemPhoto
                : itemPhoto // ignore: cast_nullable_to_non_nullable
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
        roomPhoto:
            freezed == roomPhoto
                ? _value.roomPhoto
                : roomPhoto // ignore: cast_nullable_to_non_nullable
                    as String?,
        sectionId:
            freezed == sectionId
                ? _value.sectionId
                : sectionId // ignore: cast_nullable_to_non_nullable
                    as String?,
        sectionPhoto:
            freezed == sectionPhoto
                ? _value.sectionPhoto
                : sectionPhoto // ignore: cast_nullable_to_non_nullable
                    as String?,
        sectionCode:
            freezed == sectionCode
                ? _value.sectionCode
                : sectionCode // ignore: cast_nullable_to_non_nullable
                    as String?,
        sectionFurnitureName:
            freezed == sectionFurnitureName
                ? _value.sectionFurnitureName
                : sectionFurnitureName // ignore: cast_nullable_to_non_nullable
                    as String?,
        boundingBox:
            freezed == boundingBox
                ? _value.boundingBox
                : boundingBox // ignore: cast_nullable_to_non_nullable
                    as SectionBoundingBox?,
        instruction:
            null == instruction
                ? _value.instruction
                : instruction // ignore: cast_nullable_to_non_nullable
                    as String,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
        completedByUserId:
            freezed == completedByUserId
                ? _value.completedByUserId
                : completedByUserId // ignore: cast_nullable_to_non_nullable
                    as String?,
        completedAt:
            freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                    as String?,
        note:
            freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                    as String?,
        completionPhotoUrl:
            freezed == completionPhotoUrl
                ? _value.completionPhotoUrl
                : completionPhotoUrl // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OrchestratorStepModelImpl implements _OrchestratorStepModel {
  const _$OrchestratorStepModelImpl({
    required this.stepId,
    required this.itemId,
    required this.itemName,
    required this.itemCategory,
    this.itemPhoto,
    this.roomId,
    this.roomName,
    this.roomPhoto,
    this.sectionId,
    this.sectionPhoto,
    this.sectionCode,
    this.sectionFurnitureName,
    @JsonKey(fromJson: _boundingBoxFromJson, toJson: _boundingBoxToJson)
    this.boundingBox,
    required this.instruction,
    this.status = 'pending',
    this.completedByUserId,
    this.completedAt,
    this.note,
    this.completionPhotoUrl,
  });

  factory _$OrchestratorStepModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrchestratorStepModelImplFromJson(json);

  @override
  final String stepId;
  @override
  final String itemId;
  @override
  final String itemName;
  @override
  final String itemCategory;
  @override
  final String? itemPhoto;
  @override
  final String? roomId;
  @override
  final String? roomName;
  @override
  final String? roomPhoto;
  @override
  final String? sectionId;
  @override
  final String? sectionPhoto;
  @override
  final String? sectionCode;
  @override
  final String? sectionFurnitureName;
  @override
  @JsonKey(fromJson: _boundingBoxFromJson, toJson: _boundingBoxToJson)
  final SectionBoundingBox? boundingBox;
  @override
  final String instruction;
  @override
  @JsonKey()
  final String status;
  @override
  final String? completedByUserId;
  @override
  final String? completedAt;
  @override
  final String? note;
  @override
  final String? completionPhotoUrl;

  @override
  String toString() {
    return 'OrchestratorStepModel(stepId: $stepId, itemId: $itemId, itemName: $itemName, itemCategory: $itemCategory, itemPhoto: $itemPhoto, roomId: $roomId, roomName: $roomName, roomPhoto: $roomPhoto, sectionId: $sectionId, sectionPhoto: $sectionPhoto, sectionCode: $sectionCode, sectionFurnitureName: $sectionFurnitureName, boundingBox: $boundingBox, instruction: $instruction, status: $status, completedByUserId: $completedByUserId, completedAt: $completedAt, note: $note, completionPhotoUrl: $completionPhotoUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrchestratorStepModelImpl &&
            (identical(other.stepId, stepId) || other.stepId == stepId) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.itemCategory, itemCategory) ||
                other.itemCategory == itemCategory) &&
            (identical(other.itemPhoto, itemPhoto) ||
                other.itemPhoto == itemPhoto) &&
            (identical(other.roomId, roomId) || other.roomId == roomId) &&
            (identical(other.roomName, roomName) ||
                other.roomName == roomName) &&
            (identical(other.roomPhoto, roomPhoto) ||
                other.roomPhoto == roomPhoto) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.sectionPhoto, sectionPhoto) ||
                other.sectionPhoto == sectionPhoto) &&
            (identical(other.sectionCode, sectionCode) ||
                other.sectionCode == sectionCode) &&
            (identical(other.sectionFurnitureName, sectionFurnitureName) ||
                other.sectionFurnitureName == sectionFurnitureName) &&
            (identical(other.boundingBox, boundingBox) ||
                other.boundingBox == boundingBox) &&
            (identical(other.instruction, instruction) ||
                other.instruction == instruction) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.completedByUserId, completedByUserId) ||
                other.completedByUserId == completedByUserId) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.completionPhotoUrl, completionPhotoUrl) ||
                other.completionPhotoUrl == completionPhotoUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    stepId,
    itemId,
    itemName,
    itemCategory,
    itemPhoto,
    roomId,
    roomName,
    roomPhoto,
    sectionId,
    sectionPhoto,
    sectionCode,
    sectionFurnitureName,
    boundingBox,
    instruction,
    status,
    completedByUserId,
    completedAt,
    note,
    completionPhotoUrl,
  ]);

  /// Create a copy of OrchestratorStepModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrchestratorStepModelImplCopyWith<_$OrchestratorStepModelImpl>
  get copyWith =>
      __$$OrchestratorStepModelImplCopyWithImpl<_$OrchestratorStepModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OrchestratorStepModelImplToJson(this);
  }
}

abstract class _OrchestratorStepModel implements OrchestratorStepModel {
  const factory _OrchestratorStepModel({
    required final String stepId,
    required final String itemId,
    required final String itemName,
    required final String itemCategory,
    final String? itemPhoto,
    final String? roomId,
    final String? roomName,
    final String? roomPhoto,
    final String? sectionId,
    final String? sectionPhoto,
    final String? sectionCode,
    final String? sectionFurnitureName,
    @JsonKey(fromJson: _boundingBoxFromJson, toJson: _boundingBoxToJson)
    final SectionBoundingBox? boundingBox,
    required final String instruction,
    final String status,
    final String? completedByUserId,
    final String? completedAt,
    final String? note,
    final String? completionPhotoUrl,
  }) = _$OrchestratorStepModelImpl;

  factory _OrchestratorStepModel.fromJson(Map<String, dynamic> json) =
      _$OrchestratorStepModelImpl.fromJson;

  @override
  String get stepId;
  @override
  String get itemId;
  @override
  String get itemName;
  @override
  String get itemCategory;
  @override
  String? get itemPhoto;
  @override
  String? get roomId;
  @override
  String? get roomName;
  @override
  String? get roomPhoto;
  @override
  String? get sectionId;
  @override
  String? get sectionPhoto;
  @override
  String? get sectionCode;
  @override
  String? get sectionFurnitureName;
  @override
  @JsonKey(fromJson: _boundingBoxFromJson, toJson: _boundingBoxToJson)
  SectionBoundingBox? get boundingBox;
  @override
  String get instruction;
  @override
  String get status;
  @override
  String? get completedByUserId;
  @override
  String? get completedAt;
  @override
  String? get note;
  @override
  String? get completionPhotoUrl;

  /// Create a copy of OrchestratorStepModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrchestratorStepModelImplCopyWith<_$OrchestratorStepModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

OrchestratorTaskGroupModel _$OrchestratorTaskGroupModelFromJson(
  Map<String, dynamic> json,
) {
  return _OrchestratorTaskGroupModel.fromJson(json);
}

/// @nodoc
mixin _$OrchestratorTaskGroupModel {
  String get groupId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get assignedUserId => throw _privateConstructorUsedError;
  String? get assignedUserName => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  List<OrchestratorStepModel> get steps => throw _privateConstructorUsedError;
  String? get startedAt => throw _privateConstructorUsedError;
  String? get completedAt => throw _privateConstructorUsedError;

  /// Serializes this OrchestratorTaskGroupModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrchestratorTaskGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrchestratorTaskGroupModelCopyWith<OrchestratorTaskGroupModel>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrchestratorTaskGroupModelCopyWith<$Res> {
  factory $OrchestratorTaskGroupModelCopyWith(
    OrchestratorTaskGroupModel value,
    $Res Function(OrchestratorTaskGroupModel) then,
  ) =
      _$OrchestratorTaskGroupModelCopyWithImpl<
        $Res,
        OrchestratorTaskGroupModel
      >;
  @useResult
  $Res call({
    String groupId,
    String title,
    String? assignedUserId,
    String? assignedUserName,
    String status,
    List<OrchestratorStepModel> steps,
    String? startedAt,
    String? completedAt,
  });
}

/// @nodoc
class _$OrchestratorTaskGroupModelCopyWithImpl<
  $Res,
  $Val extends OrchestratorTaskGroupModel
>
    implements $OrchestratorTaskGroupModelCopyWith<$Res> {
  _$OrchestratorTaskGroupModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrchestratorTaskGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupId = null,
    Object? title = null,
    Object? assignedUserId = freezed,
    Object? assignedUserName = freezed,
    Object? status = null,
    Object? steps = null,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            groupId:
                null == groupId
                    ? _value.groupId
                    : groupId // ignore: cast_nullable_to_non_nullable
                        as String,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            assignedUserId:
                freezed == assignedUserId
                    ? _value.assignedUserId
                    : assignedUserId // ignore: cast_nullable_to_non_nullable
                        as String?,
            assignedUserName:
                freezed == assignedUserName
                    ? _value.assignedUserName
                    : assignedUserName // ignore: cast_nullable_to_non_nullable
                        as String?,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            steps:
                null == steps
                    ? _value.steps
                    : steps // ignore: cast_nullable_to_non_nullable
                        as List<OrchestratorStepModel>,
            startedAt:
                freezed == startedAt
                    ? _value.startedAt
                    : startedAt // ignore: cast_nullable_to_non_nullable
                        as String?,
            completedAt:
                freezed == completedAt
                    ? _value.completedAt
                    : completedAt // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OrchestratorTaskGroupModelImplCopyWith<$Res>
    implements $OrchestratorTaskGroupModelCopyWith<$Res> {
  factory _$$OrchestratorTaskGroupModelImplCopyWith(
    _$OrchestratorTaskGroupModelImpl value,
    $Res Function(_$OrchestratorTaskGroupModelImpl) then,
  ) = __$$OrchestratorTaskGroupModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String groupId,
    String title,
    String? assignedUserId,
    String? assignedUserName,
    String status,
    List<OrchestratorStepModel> steps,
    String? startedAt,
    String? completedAt,
  });
}

/// @nodoc
class __$$OrchestratorTaskGroupModelImplCopyWithImpl<$Res>
    extends
        _$OrchestratorTaskGroupModelCopyWithImpl<
          $Res,
          _$OrchestratorTaskGroupModelImpl
        >
    implements _$$OrchestratorTaskGroupModelImplCopyWith<$Res> {
  __$$OrchestratorTaskGroupModelImplCopyWithImpl(
    _$OrchestratorTaskGroupModelImpl _value,
    $Res Function(_$OrchestratorTaskGroupModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OrchestratorTaskGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupId = null,
    Object? title = null,
    Object? assignedUserId = freezed,
    Object? assignedUserName = freezed,
    Object? status = null,
    Object? steps = null,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(
      _$OrchestratorTaskGroupModelImpl(
        groupId:
            null == groupId
                ? _value.groupId
                : groupId // ignore: cast_nullable_to_non_nullable
                    as String,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        assignedUserId:
            freezed == assignedUserId
                ? _value.assignedUserId
                : assignedUserId // ignore: cast_nullable_to_non_nullable
                    as String?,
        assignedUserName:
            freezed == assignedUserName
                ? _value.assignedUserName
                : assignedUserName // ignore: cast_nullable_to_non_nullable
                    as String?,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
        steps:
            null == steps
                ? _value._steps
                : steps // ignore: cast_nullable_to_non_nullable
                    as List<OrchestratorStepModel>,
        startedAt:
            freezed == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                    as String?,
        completedAt:
            freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OrchestratorTaskGroupModelImpl implements _OrchestratorTaskGroupModel {
  const _$OrchestratorTaskGroupModelImpl({
    required this.groupId,
    required this.title,
    this.assignedUserId,
    this.assignedUserName,
    this.status = 'pending',
    final List<OrchestratorStepModel> steps = const [],
    this.startedAt,
    this.completedAt,
  }) : _steps = steps;

  factory _$OrchestratorTaskGroupModelImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$OrchestratorTaskGroupModelImplFromJson(json);

  @override
  final String groupId;
  @override
  final String title;
  @override
  final String? assignedUserId;
  @override
  final String? assignedUserName;
  @override
  @JsonKey()
  final String status;
  final List<OrchestratorStepModel> _steps;
  @override
  @JsonKey()
  List<OrchestratorStepModel> get steps {
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_steps);
  }

  @override
  final String? startedAt;
  @override
  final String? completedAt;

  @override
  String toString() {
    return 'OrchestratorTaskGroupModel(groupId: $groupId, title: $title, assignedUserId: $assignedUserId, assignedUserName: $assignedUserName, status: $status, steps: $steps, startedAt: $startedAt, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrchestratorTaskGroupModelImpl &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.assignedUserId, assignedUserId) ||
                other.assignedUserId == assignedUserId) &&
            (identical(other.assignedUserName, assignedUserName) ||
                other.assignedUserName == assignedUserName) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._steps, _steps) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    groupId,
    title,
    assignedUserId,
    assignedUserName,
    status,
    const DeepCollectionEquality().hash(_steps),
    startedAt,
    completedAt,
  );

  /// Create a copy of OrchestratorTaskGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrchestratorTaskGroupModelImplCopyWith<_$OrchestratorTaskGroupModelImpl>
  get copyWith => __$$OrchestratorTaskGroupModelImplCopyWithImpl<
    _$OrchestratorTaskGroupModelImpl
  >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrchestratorTaskGroupModelImplToJson(this);
  }
}

abstract class _OrchestratorTaskGroupModel
    implements OrchestratorTaskGroupModel {
  const factory _OrchestratorTaskGroupModel({
    required final String groupId,
    required final String title,
    final String? assignedUserId,
    final String? assignedUserName,
    final String status,
    final List<OrchestratorStepModel> steps,
    final String? startedAt,
    final String? completedAt,
  }) = _$OrchestratorTaskGroupModelImpl;

  factory _OrchestratorTaskGroupModel.fromJson(Map<String, dynamic> json) =
      _$OrchestratorTaskGroupModelImpl.fromJson;

  @override
  String get groupId;
  @override
  String get title;
  @override
  String? get assignedUserId;
  @override
  String? get assignedUserName;
  @override
  String get status;
  @override
  List<OrchestratorStepModel> get steps;
  @override
  String? get startedAt;
  @override
  String? get completedAt;

  /// Create a copy of OrchestratorTaskGroupModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrchestratorTaskGroupModelImplCopyWith<_$OrchestratorTaskGroupModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

OrchestratorPlanModel _$OrchestratorPlanModelFromJson(
  Map<String, dynamic> json,
) {
  return _OrchestratorPlanModel.fromJson(json);
}

/// @nodoc
mixin _$OrchestratorPlanModel {
  // MongoDB documents use _id; map to id
  @JsonKey(name: '_id')
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get originalCommand => throw _privateConstructorUsedError;
  String get commandType => throw _privateConstructorUsedError;
  String? get targetDate => throw _privateConstructorUsedError;
  String? get targetPropertyId => throw _privateConstructorUsedError;
  String? get destinationPropertyId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get aiSummary => throw _privateConstructorUsedError;
  List<OrchestratorTaskGroupModel> get taskGroups =>
      throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  String? get publishedAt => throw _privateConstructorUsedError;
  String? get completedAt => throw _privateConstructorUsedError;
  String? get cancelledAt => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this OrchestratorPlanModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrchestratorPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrchestratorPlanModelCopyWith<OrchestratorPlanModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrchestratorPlanModelCopyWith<$Res> {
  factory $OrchestratorPlanModelCopyWith(
    OrchestratorPlanModel value,
    $Res Function(OrchestratorPlanModel) then,
  ) = _$OrchestratorPlanModelCopyWithImpl<$Res, OrchestratorPlanModel>;
  @useResult
  $Res call({
    @JsonKey(name: '_id') String id,
    String tenantId,
    String title,
    String originalCommand,
    String commandType,
    String? targetDate,
    String? targetPropertyId,
    String? destinationPropertyId,
    String status,
    String aiSummary,
    List<OrchestratorTaskGroupModel> taskGroups,
    String createdBy,
    String? publishedAt,
    String? completedAt,
    String? cancelledAt,
    String createdAt,
    String updatedAt,
  });
}

/// @nodoc
class _$OrchestratorPlanModelCopyWithImpl<
  $Res,
  $Val extends OrchestratorPlanModel
>
    implements $OrchestratorPlanModelCopyWith<$Res> {
  _$OrchestratorPlanModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrchestratorPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? title = null,
    Object? originalCommand = null,
    Object? commandType = null,
    Object? targetDate = freezed,
    Object? targetPropertyId = freezed,
    Object? destinationPropertyId = freezed,
    Object? status = null,
    Object? aiSummary = null,
    Object? taskGroups = null,
    Object? createdBy = null,
    Object? publishedAt = freezed,
    Object? completedAt = freezed,
    Object? cancelledAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
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
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            originalCommand:
                null == originalCommand
                    ? _value.originalCommand
                    : originalCommand // ignore: cast_nullable_to_non_nullable
                        as String,
            commandType:
                null == commandType
                    ? _value.commandType
                    : commandType // ignore: cast_nullable_to_non_nullable
                        as String,
            targetDate:
                freezed == targetDate
                    ? _value.targetDate
                    : targetDate // ignore: cast_nullable_to_non_nullable
                        as String?,
            targetPropertyId:
                freezed == targetPropertyId
                    ? _value.targetPropertyId
                    : targetPropertyId // ignore: cast_nullable_to_non_nullable
                        as String?,
            destinationPropertyId:
                freezed == destinationPropertyId
                    ? _value.destinationPropertyId
                    : destinationPropertyId // ignore: cast_nullable_to_non_nullable
                        as String?,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            aiSummary:
                null == aiSummary
                    ? _value.aiSummary
                    : aiSummary // ignore: cast_nullable_to_non_nullable
                        as String,
            taskGroups:
                null == taskGroups
                    ? _value.taskGroups
                    : taskGroups // ignore: cast_nullable_to_non_nullable
                        as List<OrchestratorTaskGroupModel>,
            createdBy:
                null == createdBy
                    ? _value.createdBy
                    : createdBy // ignore: cast_nullable_to_non_nullable
                        as String,
            publishedAt:
                freezed == publishedAt
                    ? _value.publishedAt
                    : publishedAt // ignore: cast_nullable_to_non_nullable
                        as String?,
            completedAt:
                freezed == completedAt
                    ? _value.completedAt
                    : completedAt // ignore: cast_nullable_to_non_nullable
                        as String?,
            cancelledAt:
                freezed == cancelledAt
                    ? _value.cancelledAt
                    : cancelledAt // ignore: cast_nullable_to_non_nullable
                        as String?,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as String,
            updatedAt:
                null == updatedAt
                    ? _value.updatedAt
                    : updatedAt // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OrchestratorPlanModelImplCopyWith<$Res>
    implements $OrchestratorPlanModelCopyWith<$Res> {
  factory _$$OrchestratorPlanModelImplCopyWith(
    _$OrchestratorPlanModelImpl value,
    $Res Function(_$OrchestratorPlanModelImpl) then,
  ) = __$$OrchestratorPlanModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: '_id') String id,
    String tenantId,
    String title,
    String originalCommand,
    String commandType,
    String? targetDate,
    String? targetPropertyId,
    String? destinationPropertyId,
    String status,
    String aiSummary,
    List<OrchestratorTaskGroupModel> taskGroups,
    String createdBy,
    String? publishedAt,
    String? completedAt,
    String? cancelledAt,
    String createdAt,
    String updatedAt,
  });
}

/// @nodoc
class __$$OrchestratorPlanModelImplCopyWithImpl<$Res>
    extends
        _$OrchestratorPlanModelCopyWithImpl<$Res, _$OrchestratorPlanModelImpl>
    implements _$$OrchestratorPlanModelImplCopyWith<$Res> {
  __$$OrchestratorPlanModelImplCopyWithImpl(
    _$OrchestratorPlanModelImpl _value,
    $Res Function(_$OrchestratorPlanModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OrchestratorPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? title = null,
    Object? originalCommand = null,
    Object? commandType = null,
    Object? targetDate = freezed,
    Object? targetPropertyId = freezed,
    Object? destinationPropertyId = freezed,
    Object? status = null,
    Object? aiSummary = null,
    Object? taskGroups = null,
    Object? createdBy = null,
    Object? publishedAt = freezed,
    Object? completedAt = freezed,
    Object? cancelledAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$OrchestratorPlanModelImpl(
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
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        originalCommand:
            null == originalCommand
                ? _value.originalCommand
                : originalCommand // ignore: cast_nullable_to_non_nullable
                    as String,
        commandType:
            null == commandType
                ? _value.commandType
                : commandType // ignore: cast_nullable_to_non_nullable
                    as String,
        targetDate:
            freezed == targetDate
                ? _value.targetDate
                : targetDate // ignore: cast_nullable_to_non_nullable
                    as String?,
        targetPropertyId:
            freezed == targetPropertyId
                ? _value.targetPropertyId
                : targetPropertyId // ignore: cast_nullable_to_non_nullable
                    as String?,
        destinationPropertyId:
            freezed == destinationPropertyId
                ? _value.destinationPropertyId
                : destinationPropertyId // ignore: cast_nullable_to_non_nullable
                    as String?,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
        aiSummary:
            null == aiSummary
                ? _value.aiSummary
                : aiSummary // ignore: cast_nullable_to_non_nullable
                    as String,
        taskGroups:
            null == taskGroups
                ? _value._taskGroups
                : taskGroups // ignore: cast_nullable_to_non_nullable
                    as List<OrchestratorTaskGroupModel>,
        createdBy:
            null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                    as String,
        publishedAt:
            freezed == publishedAt
                ? _value.publishedAt
                : publishedAt // ignore: cast_nullable_to_non_nullable
                    as String?,
        completedAt:
            freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                    as String?,
        cancelledAt:
            freezed == cancelledAt
                ? _value.cancelledAt
                : cancelledAt // ignore: cast_nullable_to_non_nullable
                    as String?,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as String,
        updatedAt:
            null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OrchestratorPlanModelImpl implements _OrchestratorPlanModel {
  const _$OrchestratorPlanModelImpl({
    @JsonKey(name: '_id') required this.id,
    required this.tenantId,
    required this.title,
    required this.originalCommand,
    this.commandType = 'general',
    this.targetDate,
    this.targetPropertyId,
    this.destinationPropertyId,
    this.status = 'draft',
    this.aiSummary = '',
    final List<OrchestratorTaskGroupModel> taskGroups = const [],
    required this.createdBy,
    this.publishedAt,
    this.completedAt,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  }) : _taskGroups = taskGroups;

  factory _$OrchestratorPlanModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrchestratorPlanModelImplFromJson(json);

  // MongoDB documents use _id; map to id
  @override
  @JsonKey(name: '_id')
  final String id;
  @override
  final String tenantId;
  @override
  final String title;
  @override
  final String originalCommand;
  @override
  @JsonKey()
  final String commandType;
  @override
  final String? targetDate;
  @override
  final String? targetPropertyId;
  @override
  final String? destinationPropertyId;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final String aiSummary;
  final List<OrchestratorTaskGroupModel> _taskGroups;
  @override
  @JsonKey()
  List<OrchestratorTaskGroupModel> get taskGroups {
    if (_taskGroups is EqualUnmodifiableListView) return _taskGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_taskGroups);
  }

  @override
  final String createdBy;
  @override
  final String? publishedAt;
  @override
  final String? completedAt;
  @override
  final String? cancelledAt;
  @override
  final String createdAt;
  @override
  final String updatedAt;

  @override
  String toString() {
    return 'OrchestratorPlanModel(id: $id, tenantId: $tenantId, title: $title, originalCommand: $originalCommand, commandType: $commandType, targetDate: $targetDate, targetPropertyId: $targetPropertyId, destinationPropertyId: $destinationPropertyId, status: $status, aiSummary: $aiSummary, taskGroups: $taskGroups, createdBy: $createdBy, publishedAt: $publishedAt, completedAt: $completedAt, cancelledAt: $cancelledAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrchestratorPlanModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.originalCommand, originalCommand) ||
                other.originalCommand == originalCommand) &&
            (identical(other.commandType, commandType) ||
                other.commandType == commandType) &&
            (identical(other.targetDate, targetDate) ||
                other.targetDate == targetDate) &&
            (identical(other.targetPropertyId, targetPropertyId) ||
                other.targetPropertyId == targetPropertyId) &&
            (identical(other.destinationPropertyId, destinationPropertyId) ||
                other.destinationPropertyId == destinationPropertyId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.aiSummary, aiSummary) ||
                other.aiSummary == aiSummary) &&
            const DeepCollectionEquality().equals(
              other._taskGroups,
              _taskGroups,
            ) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.publishedAt, publishedAt) ||
                other.publishedAt == publishedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.cancelledAt, cancelledAt) ||
                other.cancelledAt == cancelledAt) &&
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
    title,
    originalCommand,
    commandType,
    targetDate,
    targetPropertyId,
    destinationPropertyId,
    status,
    aiSummary,
    const DeepCollectionEquality().hash(_taskGroups),
    createdBy,
    publishedAt,
    completedAt,
    cancelledAt,
    createdAt,
    updatedAt,
  );

  /// Create a copy of OrchestratorPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrchestratorPlanModelImplCopyWith<_$OrchestratorPlanModelImpl>
  get copyWith =>
      __$$OrchestratorPlanModelImplCopyWithImpl<_$OrchestratorPlanModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OrchestratorPlanModelImplToJson(this);
  }
}

abstract class _OrchestratorPlanModel implements OrchestratorPlanModel {
  const factory _OrchestratorPlanModel({
    @JsonKey(name: '_id') required final String id,
    required final String tenantId,
    required final String title,
    required final String originalCommand,
    final String commandType,
    final String? targetDate,
    final String? targetPropertyId,
    final String? destinationPropertyId,
    final String status,
    final String aiSummary,
    final List<OrchestratorTaskGroupModel> taskGroups,
    required final String createdBy,
    final String? publishedAt,
    final String? completedAt,
    final String? cancelledAt,
    required final String createdAt,
    required final String updatedAt,
  }) = _$OrchestratorPlanModelImpl;

  factory _OrchestratorPlanModel.fromJson(Map<String, dynamic> json) =
      _$OrchestratorPlanModelImpl.fromJson;

  // MongoDB documents use _id; map to id
  @override
  @JsonKey(name: '_id')
  String get id;
  @override
  String get tenantId;
  @override
  String get title;
  @override
  String get originalCommand;
  @override
  String get commandType;
  @override
  String? get targetDate;
  @override
  String? get targetPropertyId;
  @override
  String? get destinationPropertyId;
  @override
  String get status;
  @override
  String get aiSummary;
  @override
  List<OrchestratorTaskGroupModel> get taskGroups;
  @override
  String get createdBy;
  @override
  String? get publishedAt;
  @override
  String? get completedAt;
  @override
  String? get cancelledAt;
  @override
  String get createdAt;
  @override
  String get updatedAt;

  /// Create a copy of OrchestratorPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrchestratorPlanModelImplCopyWith<_$OrchestratorPlanModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

ParsedPlanModel _$ParsedPlanModelFromJson(Map<String, dynamic> json) {
  return _ParsedPlanModel.fromJson(json);
}

/// @nodoc
mixin _$ParsedPlanModel {
  String get commandType => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get aiSummary => throw _privateConstructorUsedError;
  String? get targetDate => throw _privateConstructorUsedError;
  String? get targetPropertyId => throw _privateConstructorUsedError;
  String? get destinationPropertyId => throw _privateConstructorUsedError;
  List<OrchestratorTaskGroupModel> get taskGroups =>
      throw _privateConstructorUsedError;

  /// Serializes this ParsedPlanModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ParsedPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ParsedPlanModelCopyWith<ParsedPlanModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ParsedPlanModelCopyWith<$Res> {
  factory $ParsedPlanModelCopyWith(
    ParsedPlanModel value,
    $Res Function(ParsedPlanModel) then,
  ) = _$ParsedPlanModelCopyWithImpl<$Res, ParsedPlanModel>;
  @useResult
  $Res call({
    String commandType,
    String title,
    String aiSummary,
    String? targetDate,
    String? targetPropertyId,
    String? destinationPropertyId,
    List<OrchestratorTaskGroupModel> taskGroups,
  });
}

/// @nodoc
class _$ParsedPlanModelCopyWithImpl<$Res, $Val extends ParsedPlanModel>
    implements $ParsedPlanModelCopyWith<$Res> {
  _$ParsedPlanModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ParsedPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? commandType = null,
    Object? title = null,
    Object? aiSummary = null,
    Object? targetDate = freezed,
    Object? targetPropertyId = freezed,
    Object? destinationPropertyId = freezed,
    Object? taskGroups = null,
  }) {
    return _then(
      _value.copyWith(
            commandType:
                null == commandType
                    ? _value.commandType
                    : commandType // ignore: cast_nullable_to_non_nullable
                        as String,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            aiSummary:
                null == aiSummary
                    ? _value.aiSummary
                    : aiSummary // ignore: cast_nullable_to_non_nullable
                        as String,
            targetDate:
                freezed == targetDate
                    ? _value.targetDate
                    : targetDate // ignore: cast_nullable_to_non_nullable
                        as String?,
            targetPropertyId:
                freezed == targetPropertyId
                    ? _value.targetPropertyId
                    : targetPropertyId // ignore: cast_nullable_to_non_nullable
                        as String?,
            destinationPropertyId:
                freezed == destinationPropertyId
                    ? _value.destinationPropertyId
                    : destinationPropertyId // ignore: cast_nullable_to_non_nullable
                        as String?,
            taskGroups:
                null == taskGroups
                    ? _value.taskGroups
                    : taskGroups // ignore: cast_nullable_to_non_nullable
                        as List<OrchestratorTaskGroupModel>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ParsedPlanModelImplCopyWith<$Res>
    implements $ParsedPlanModelCopyWith<$Res> {
  factory _$$ParsedPlanModelImplCopyWith(
    _$ParsedPlanModelImpl value,
    $Res Function(_$ParsedPlanModelImpl) then,
  ) = __$$ParsedPlanModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String commandType,
    String title,
    String aiSummary,
    String? targetDate,
    String? targetPropertyId,
    String? destinationPropertyId,
    List<OrchestratorTaskGroupModel> taskGroups,
  });
}

/// @nodoc
class __$$ParsedPlanModelImplCopyWithImpl<$Res>
    extends _$ParsedPlanModelCopyWithImpl<$Res, _$ParsedPlanModelImpl>
    implements _$$ParsedPlanModelImplCopyWith<$Res> {
  __$$ParsedPlanModelImplCopyWithImpl(
    _$ParsedPlanModelImpl _value,
    $Res Function(_$ParsedPlanModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ParsedPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? commandType = null,
    Object? title = null,
    Object? aiSummary = null,
    Object? targetDate = freezed,
    Object? targetPropertyId = freezed,
    Object? destinationPropertyId = freezed,
    Object? taskGroups = null,
  }) {
    return _then(
      _$ParsedPlanModelImpl(
        commandType:
            null == commandType
                ? _value.commandType
                : commandType // ignore: cast_nullable_to_non_nullable
                    as String,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        aiSummary:
            null == aiSummary
                ? _value.aiSummary
                : aiSummary // ignore: cast_nullable_to_non_nullable
                    as String,
        targetDate:
            freezed == targetDate
                ? _value.targetDate
                : targetDate // ignore: cast_nullable_to_non_nullable
                    as String?,
        targetPropertyId:
            freezed == targetPropertyId
                ? _value.targetPropertyId
                : targetPropertyId // ignore: cast_nullable_to_non_nullable
                    as String?,
        destinationPropertyId:
            freezed == destinationPropertyId
                ? _value.destinationPropertyId
                : destinationPropertyId // ignore: cast_nullable_to_non_nullable
                    as String?,
        taskGroups:
            null == taskGroups
                ? _value._taskGroups
                : taskGroups // ignore: cast_nullable_to_non_nullable
                    as List<OrchestratorTaskGroupModel>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ParsedPlanModelImpl implements _ParsedPlanModel {
  const _$ParsedPlanModelImpl({
    this.commandType = 'general',
    required this.title,
    required this.aiSummary,
    this.targetDate,
    this.targetPropertyId,
    this.destinationPropertyId,
    final List<OrchestratorTaskGroupModel> taskGroups = const [],
  }) : _taskGroups = taskGroups;

  factory _$ParsedPlanModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ParsedPlanModelImplFromJson(json);

  @override
  @JsonKey()
  final String commandType;
  @override
  final String title;
  @override
  final String aiSummary;
  @override
  final String? targetDate;
  @override
  final String? targetPropertyId;
  @override
  final String? destinationPropertyId;
  final List<OrchestratorTaskGroupModel> _taskGroups;
  @override
  @JsonKey()
  List<OrchestratorTaskGroupModel> get taskGroups {
    if (_taskGroups is EqualUnmodifiableListView) return _taskGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_taskGroups);
  }

  @override
  String toString() {
    return 'ParsedPlanModel(commandType: $commandType, title: $title, aiSummary: $aiSummary, targetDate: $targetDate, targetPropertyId: $targetPropertyId, destinationPropertyId: $destinationPropertyId, taskGroups: $taskGroups)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ParsedPlanModelImpl &&
            (identical(other.commandType, commandType) ||
                other.commandType == commandType) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.aiSummary, aiSummary) ||
                other.aiSummary == aiSummary) &&
            (identical(other.targetDate, targetDate) ||
                other.targetDate == targetDate) &&
            (identical(other.targetPropertyId, targetPropertyId) ||
                other.targetPropertyId == targetPropertyId) &&
            (identical(other.destinationPropertyId, destinationPropertyId) ||
                other.destinationPropertyId == destinationPropertyId) &&
            const DeepCollectionEquality().equals(
              other._taskGroups,
              _taskGroups,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    commandType,
    title,
    aiSummary,
    targetDate,
    targetPropertyId,
    destinationPropertyId,
    const DeepCollectionEquality().hash(_taskGroups),
  );

  /// Create a copy of ParsedPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ParsedPlanModelImplCopyWith<_$ParsedPlanModelImpl> get copyWith =>
      __$$ParsedPlanModelImplCopyWithImpl<_$ParsedPlanModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ParsedPlanModelImplToJson(this);
  }
}

abstract class _ParsedPlanModel implements ParsedPlanModel {
  const factory _ParsedPlanModel({
    final String commandType,
    required final String title,
    required final String aiSummary,
    final String? targetDate,
    final String? targetPropertyId,
    final String? destinationPropertyId,
    final List<OrchestratorTaskGroupModel> taskGroups,
  }) = _$ParsedPlanModelImpl;

  factory _ParsedPlanModel.fromJson(Map<String, dynamic> json) =
      _$ParsedPlanModelImpl.fromJson;

  @override
  String get commandType;
  @override
  String get title;
  @override
  String get aiSummary;
  @override
  String? get targetDate;
  @override
  String? get targetPropertyId;
  @override
  String? get destinationPropertyId;
  @override
  List<OrchestratorTaskGroupModel> get taskGroups;

  /// Create a copy of ParsedPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ParsedPlanModelImplCopyWith<_$ParsedPlanModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GroupProgressModel _$GroupProgressModelFromJson(Map<String, dynamic> json) {
  return _GroupProgressModel.fromJson(json);
}

/// @nodoc
mixin _$GroupProgressModel {
  String get groupId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get assignedUserId => throw _privateConstructorUsedError;
  String get assignedUserName => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  int get totalSteps => throw _privateConstructorUsedError;
  int get completedSteps => throw _privateConstructorUsedError;

  /// Serializes this GroupProgressModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GroupProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroupProgressModelCopyWith<GroupProgressModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupProgressModelCopyWith<$Res> {
  factory $GroupProgressModelCopyWith(
    GroupProgressModel value,
    $Res Function(GroupProgressModel) then,
  ) = _$GroupProgressModelCopyWithImpl<$Res, GroupProgressModel>;
  @useResult
  $Res call({
    String groupId,
    String title,
    String assignedUserId,
    String assignedUserName,
    String status,
    int totalSteps,
    int completedSteps,
  });
}

/// @nodoc
class _$GroupProgressModelCopyWithImpl<$Res, $Val extends GroupProgressModel>
    implements $GroupProgressModelCopyWith<$Res> {
  _$GroupProgressModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroupProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupId = null,
    Object? title = null,
    Object? assignedUserId = null,
    Object? assignedUserName = null,
    Object? status = null,
    Object? totalSteps = null,
    Object? completedSteps = null,
  }) {
    return _then(
      _value.copyWith(
            groupId:
                null == groupId
                    ? _value.groupId
                    : groupId // ignore: cast_nullable_to_non_nullable
                        as String,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            assignedUserId:
                null == assignedUserId
                    ? _value.assignedUserId
                    : assignedUserId // ignore: cast_nullable_to_non_nullable
                        as String,
            assignedUserName:
                null == assignedUserName
                    ? _value.assignedUserName
                    : assignedUserName // ignore: cast_nullable_to_non_nullable
                        as String,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            totalSteps:
                null == totalSteps
                    ? _value.totalSteps
                    : totalSteps // ignore: cast_nullable_to_non_nullable
                        as int,
            completedSteps:
                null == completedSteps
                    ? _value.completedSteps
                    : completedSteps // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GroupProgressModelImplCopyWith<$Res>
    implements $GroupProgressModelCopyWith<$Res> {
  factory _$$GroupProgressModelImplCopyWith(
    _$GroupProgressModelImpl value,
    $Res Function(_$GroupProgressModelImpl) then,
  ) = __$$GroupProgressModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String groupId,
    String title,
    String assignedUserId,
    String assignedUserName,
    String status,
    int totalSteps,
    int completedSteps,
  });
}

/// @nodoc
class __$$GroupProgressModelImplCopyWithImpl<$Res>
    extends _$GroupProgressModelCopyWithImpl<$Res, _$GroupProgressModelImpl>
    implements _$$GroupProgressModelImplCopyWith<$Res> {
  __$$GroupProgressModelImplCopyWithImpl(
    _$GroupProgressModelImpl _value,
    $Res Function(_$GroupProgressModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GroupProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupId = null,
    Object? title = null,
    Object? assignedUserId = null,
    Object? assignedUserName = null,
    Object? status = null,
    Object? totalSteps = null,
    Object? completedSteps = null,
  }) {
    return _then(
      _$GroupProgressModelImpl(
        groupId:
            null == groupId
                ? _value.groupId
                : groupId // ignore: cast_nullable_to_non_nullable
                    as String,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        assignedUserId:
            null == assignedUserId
                ? _value.assignedUserId
                : assignedUserId // ignore: cast_nullable_to_non_nullable
                    as String,
        assignedUserName:
            null == assignedUserName
                ? _value.assignedUserName
                : assignedUserName // ignore: cast_nullable_to_non_nullable
                    as String,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
        totalSteps:
            null == totalSteps
                ? _value.totalSteps
                : totalSteps // ignore: cast_nullable_to_non_nullable
                    as int,
        completedSteps:
            null == completedSteps
                ? _value.completedSteps
                : completedSteps // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupProgressModelImpl implements _GroupProgressModel {
  const _$GroupProgressModelImpl({
    required this.groupId,
    required this.title,
    this.assignedUserId = '',
    this.assignedUserName = '',
    this.status = 'pending',
    this.totalSteps = 0,
    this.completedSteps = 0,
  });

  factory _$GroupProgressModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupProgressModelImplFromJson(json);

  @override
  final String groupId;
  @override
  final String title;
  @override
  @JsonKey()
  final String assignedUserId;
  @override
  @JsonKey()
  final String assignedUserName;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey()
  final int totalSteps;
  @override
  @JsonKey()
  final int completedSteps;

  @override
  String toString() {
    return 'GroupProgressModel(groupId: $groupId, title: $title, assignedUserId: $assignedUserId, assignedUserName: $assignedUserName, status: $status, totalSteps: $totalSteps, completedSteps: $completedSteps)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupProgressModelImpl &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.assignedUserId, assignedUserId) ||
                other.assignedUserId == assignedUserId) &&
            (identical(other.assignedUserName, assignedUserName) ||
                other.assignedUserName == assignedUserName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.totalSteps, totalSteps) ||
                other.totalSteps == totalSteps) &&
            (identical(other.completedSteps, completedSteps) ||
                other.completedSteps == completedSteps));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    groupId,
    title,
    assignedUserId,
    assignedUserName,
    status,
    totalSteps,
    completedSteps,
  );

  /// Create a copy of GroupProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupProgressModelImplCopyWith<_$GroupProgressModelImpl> get copyWith =>
      __$$GroupProgressModelImplCopyWithImpl<_$GroupProgressModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupProgressModelImplToJson(this);
  }
}

abstract class _GroupProgressModel implements GroupProgressModel {
  const factory _GroupProgressModel({
    required final String groupId,
    required final String title,
    final String assignedUserId,
    final String assignedUserName,
    final String status,
    final int totalSteps,
    final int completedSteps,
  }) = _$GroupProgressModelImpl;

  factory _GroupProgressModel.fromJson(Map<String, dynamic> json) =
      _$GroupProgressModelImpl.fromJson;

  @override
  String get groupId;
  @override
  String get title;
  @override
  String get assignedUserId;
  @override
  String get assignedUserName;
  @override
  String get status;
  @override
  int get totalSteps;
  @override
  int get completedSteps;

  /// Create a copy of GroupProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroupProgressModelImplCopyWith<_$GroupProgressModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlanProgressModel _$PlanProgressModelFromJson(Map<String, dynamic> json) {
  return _PlanProgressModel.fromJson(json);
}

/// @nodoc
mixin _$PlanProgressModel {
  String get planId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  int get totalSteps => throw _privateConstructorUsedError;
  int get completedSteps => throw _privateConstructorUsedError;
  double get percentComplete => throw _privateConstructorUsedError;
  List<GroupProgressModel> get byGroup => throw _privateConstructorUsedError;

  /// Serializes this PlanProgressModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlanProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlanProgressModelCopyWith<PlanProgressModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlanProgressModelCopyWith<$Res> {
  factory $PlanProgressModelCopyWith(
    PlanProgressModel value,
    $Res Function(PlanProgressModel) then,
  ) = _$PlanProgressModelCopyWithImpl<$Res, PlanProgressModel>;
  @useResult
  $Res call({
    String planId,
    String status,
    int totalSteps,
    int completedSteps,
    double percentComplete,
    List<GroupProgressModel> byGroup,
  });
}

/// @nodoc
class _$PlanProgressModelCopyWithImpl<$Res, $Val extends PlanProgressModel>
    implements $PlanProgressModelCopyWith<$Res> {
  _$PlanProgressModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlanProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? planId = null,
    Object? status = null,
    Object? totalSteps = null,
    Object? completedSteps = null,
    Object? percentComplete = null,
    Object? byGroup = null,
  }) {
    return _then(
      _value.copyWith(
            planId:
                null == planId
                    ? _value.planId
                    : planId // ignore: cast_nullable_to_non_nullable
                        as String,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            totalSteps:
                null == totalSteps
                    ? _value.totalSteps
                    : totalSteps // ignore: cast_nullable_to_non_nullable
                        as int,
            completedSteps:
                null == completedSteps
                    ? _value.completedSteps
                    : completedSteps // ignore: cast_nullable_to_non_nullable
                        as int,
            percentComplete:
                null == percentComplete
                    ? _value.percentComplete
                    : percentComplete // ignore: cast_nullable_to_non_nullable
                        as double,
            byGroup:
                null == byGroup
                    ? _value.byGroup
                    : byGroup // ignore: cast_nullable_to_non_nullable
                        as List<GroupProgressModel>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlanProgressModelImplCopyWith<$Res>
    implements $PlanProgressModelCopyWith<$Res> {
  factory _$$PlanProgressModelImplCopyWith(
    _$PlanProgressModelImpl value,
    $Res Function(_$PlanProgressModelImpl) then,
  ) = __$$PlanProgressModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String planId,
    String status,
    int totalSteps,
    int completedSteps,
    double percentComplete,
    List<GroupProgressModel> byGroup,
  });
}

/// @nodoc
class __$$PlanProgressModelImplCopyWithImpl<$Res>
    extends _$PlanProgressModelCopyWithImpl<$Res, _$PlanProgressModelImpl>
    implements _$$PlanProgressModelImplCopyWith<$Res> {
  __$$PlanProgressModelImplCopyWithImpl(
    _$PlanProgressModelImpl _value,
    $Res Function(_$PlanProgressModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlanProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? planId = null,
    Object? status = null,
    Object? totalSteps = null,
    Object? completedSteps = null,
    Object? percentComplete = null,
    Object? byGroup = null,
  }) {
    return _then(
      _$PlanProgressModelImpl(
        planId:
            null == planId
                ? _value.planId
                : planId // ignore: cast_nullable_to_non_nullable
                    as String,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
        totalSteps:
            null == totalSteps
                ? _value.totalSteps
                : totalSteps // ignore: cast_nullable_to_non_nullable
                    as int,
        completedSteps:
            null == completedSteps
                ? _value.completedSteps
                : completedSteps // ignore: cast_nullable_to_non_nullable
                    as int,
        percentComplete:
            null == percentComplete
                ? _value.percentComplete
                : percentComplete // ignore: cast_nullable_to_non_nullable
                    as double,
        byGroup:
            null == byGroup
                ? _value._byGroup
                : byGroup // ignore: cast_nullable_to_non_nullable
                    as List<GroupProgressModel>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlanProgressModelImpl implements _PlanProgressModel {
  const _$PlanProgressModelImpl({
    required this.planId,
    required this.status,
    this.totalSteps = 0,
    this.completedSteps = 0,
    this.percentComplete = 0.0,
    final List<GroupProgressModel> byGroup = const [],
  }) : _byGroup = byGroup;

  factory _$PlanProgressModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlanProgressModelImplFromJson(json);

  @override
  final String planId;
  @override
  final String status;
  @override
  @JsonKey()
  final int totalSteps;
  @override
  @JsonKey()
  final int completedSteps;
  @override
  @JsonKey()
  final double percentComplete;
  final List<GroupProgressModel> _byGroup;
  @override
  @JsonKey()
  List<GroupProgressModel> get byGroup {
    if (_byGroup is EqualUnmodifiableListView) return _byGroup;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_byGroup);
  }

  @override
  String toString() {
    return 'PlanProgressModel(planId: $planId, status: $status, totalSteps: $totalSteps, completedSteps: $completedSteps, percentComplete: $percentComplete, byGroup: $byGroup)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlanProgressModelImpl &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.totalSteps, totalSteps) ||
                other.totalSteps == totalSteps) &&
            (identical(other.completedSteps, completedSteps) ||
                other.completedSteps == completedSteps) &&
            (identical(other.percentComplete, percentComplete) ||
                other.percentComplete == percentComplete) &&
            const DeepCollectionEquality().equals(other._byGroup, _byGroup));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    planId,
    status,
    totalSteps,
    completedSteps,
    percentComplete,
    const DeepCollectionEquality().hash(_byGroup),
  );

  /// Create a copy of PlanProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlanProgressModelImplCopyWith<_$PlanProgressModelImpl> get copyWith =>
      __$$PlanProgressModelImplCopyWithImpl<_$PlanProgressModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlanProgressModelImplToJson(this);
  }
}

abstract class _PlanProgressModel implements PlanProgressModel {
  const factory _PlanProgressModel({
    required final String planId,
    required final String status,
    final int totalSteps,
    final int completedSteps,
    final double percentComplete,
    final List<GroupProgressModel> byGroup,
  }) = _$PlanProgressModelImpl;

  factory _PlanProgressModel.fromJson(Map<String, dynamic> json) =
      _$PlanProgressModelImpl.fromJson;

  @override
  String get planId;
  @override
  String get status;
  @override
  int get totalSteps;
  @override
  int get completedSteps;
  @override
  double get percentComplete;
  @override
  List<GroupProgressModel> get byGroup;

  /// Create a copy of PlanProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlanProgressModelImplCopyWith<_$PlanProgressModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
