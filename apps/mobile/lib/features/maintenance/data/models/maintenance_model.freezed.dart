// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'maintenance_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MaintenanceModel _$MaintenanceModelFromJson(Map<String, dynamic> json) {
  return _MaintenanceModel.fromJson(json);
}

/// @nodoc
mixin _$MaintenanceModel {
  String get id => throw _privateConstructorUsedError;
  String get itemId => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get scheduledDate => throw _privateConstructorUsedError;
  String? get completedDate => throw _privateConstructorUsedError;
  bool get isRecurring => throw _privateConstructorUsedError;
  int? get recurrenceIntervalDays => throw _privateConstructorUsedError;
  String? get nextScheduledDate => throw _privateConstructorUsedError;
  String? get providerName => throw _privateConstructorUsedError;
  String? get providerContact => throw _privateConstructorUsedError;
  double? get cost => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  List<String> get documents => throw _privateConstructorUsedError;
  bool get isAiSuggested => throw _privateConstructorUsedError;
  double? get aiRiskScore => throw _privateConstructorUsedError;
  String? get aiReason => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;
  String? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this MaintenanceModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MaintenanceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MaintenanceModelCopyWith<MaintenanceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MaintenanceModelCopyWith<$Res> {
  factory $MaintenanceModelCopyWith(
    MaintenanceModel value,
    $Res Function(MaintenanceModel) then,
  ) = _$MaintenanceModelCopyWithImpl<$Res, MaintenanceModel>;
  @useResult
  $Res call({
    String id,
    String itemId,
    String tenantId,
    String title,
    String? description,
    String status,
    String scheduledDate,
    String? completedDate,
    bool isRecurring,
    int? recurrenceIntervalDays,
    String? nextScheduledDate,
    String? providerName,
    String? providerContact,
    double? cost,
    String currency,
    String? notes,
    List<String> documents,
    bool isAiSuggested,
    double? aiRiskScore,
    String? aiReason,
    String? createdAt,
    String? updatedAt,
  });
}

/// @nodoc
class _$MaintenanceModelCopyWithImpl<$Res, $Val extends MaintenanceModel>
    implements $MaintenanceModelCopyWith<$Res> {
  _$MaintenanceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MaintenanceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? itemId = null,
    Object? tenantId = null,
    Object? title = null,
    Object? description = freezed,
    Object? status = null,
    Object? scheduledDate = null,
    Object? completedDate = freezed,
    Object? isRecurring = null,
    Object? recurrenceIntervalDays = freezed,
    Object? nextScheduledDate = freezed,
    Object? providerName = freezed,
    Object? providerContact = freezed,
    Object? cost = freezed,
    Object? currency = null,
    Object? notes = freezed,
    Object? documents = null,
    Object? isAiSuggested = null,
    Object? aiRiskScore = freezed,
    Object? aiReason = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            itemId: null == itemId
                ? _value.itemId
                : itemId // ignore: cast_nullable_to_non_nullable
                      as String,
            tenantId: null == tenantId
                ? _value.tenantId
                : tenantId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            scheduledDate: null == scheduledDate
                ? _value.scheduledDate
                : scheduledDate // ignore: cast_nullable_to_non_nullable
                      as String,
            completedDate: freezed == completedDate
                ? _value.completedDate
                : completedDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            isRecurring: null == isRecurring
                ? _value.isRecurring
                : isRecurring // ignore: cast_nullable_to_non_nullable
                      as bool,
            recurrenceIntervalDays: freezed == recurrenceIntervalDays
                ? _value.recurrenceIntervalDays
                : recurrenceIntervalDays // ignore: cast_nullable_to_non_nullable
                      as int?,
            nextScheduledDate: freezed == nextScheduledDate
                ? _value.nextScheduledDate
                : nextScheduledDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            providerName: freezed == providerName
                ? _value.providerName
                : providerName // ignore: cast_nullable_to_non_nullable
                      as String?,
            providerContact: freezed == providerContact
                ? _value.providerContact
                : providerContact // ignore: cast_nullable_to_non_nullable
                      as String?,
            cost: freezed == cost
                ? _value.cost
                : cost // ignore: cast_nullable_to_non_nullable
                      as double?,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            documents: null == documents
                ? _value.documents
                : documents // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            isAiSuggested: null == isAiSuggested
                ? _value.isAiSuggested
                : isAiSuggested // ignore: cast_nullable_to_non_nullable
                      as bool,
            aiRiskScore: freezed == aiRiskScore
                ? _value.aiRiskScore
                : aiRiskScore // ignore: cast_nullable_to_non_nullable
                      as double?,
            aiReason: freezed == aiReason
                ? _value.aiReason
                : aiReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MaintenanceModelImplCopyWith<$Res>
    implements $MaintenanceModelCopyWith<$Res> {
  factory _$$MaintenanceModelImplCopyWith(
    _$MaintenanceModelImpl value,
    $Res Function(_$MaintenanceModelImpl) then,
  ) = __$$MaintenanceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String itemId,
    String tenantId,
    String title,
    String? description,
    String status,
    String scheduledDate,
    String? completedDate,
    bool isRecurring,
    int? recurrenceIntervalDays,
    String? nextScheduledDate,
    String? providerName,
    String? providerContact,
    double? cost,
    String currency,
    String? notes,
    List<String> documents,
    bool isAiSuggested,
    double? aiRiskScore,
    String? aiReason,
    String? createdAt,
    String? updatedAt,
  });
}

/// @nodoc
class __$$MaintenanceModelImplCopyWithImpl<$Res>
    extends _$MaintenanceModelCopyWithImpl<$Res, _$MaintenanceModelImpl>
    implements _$$MaintenanceModelImplCopyWith<$Res> {
  __$$MaintenanceModelImplCopyWithImpl(
    _$MaintenanceModelImpl _value,
    $Res Function(_$MaintenanceModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MaintenanceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? itemId = null,
    Object? tenantId = null,
    Object? title = null,
    Object? description = freezed,
    Object? status = null,
    Object? scheduledDate = null,
    Object? completedDate = freezed,
    Object? isRecurring = null,
    Object? recurrenceIntervalDays = freezed,
    Object? nextScheduledDate = freezed,
    Object? providerName = freezed,
    Object? providerContact = freezed,
    Object? cost = freezed,
    Object? currency = null,
    Object? notes = freezed,
    Object? documents = null,
    Object? isAiSuggested = null,
    Object? aiRiskScore = freezed,
    Object? aiReason = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$MaintenanceModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        itemId: null == itemId
            ? _value.itemId
            : itemId // ignore: cast_nullable_to_non_nullable
                  as String,
        tenantId: null == tenantId
            ? _value.tenantId
            : tenantId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        scheduledDate: null == scheduledDate
            ? _value.scheduledDate
            : scheduledDate // ignore: cast_nullable_to_non_nullable
                  as String,
        completedDate: freezed == completedDate
            ? _value.completedDate
            : completedDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        isRecurring: null == isRecurring
            ? _value.isRecurring
            : isRecurring // ignore: cast_nullable_to_non_nullable
                  as bool,
        recurrenceIntervalDays: freezed == recurrenceIntervalDays
            ? _value.recurrenceIntervalDays
            : recurrenceIntervalDays // ignore: cast_nullable_to_non_nullable
                  as int?,
        nextScheduledDate: freezed == nextScheduledDate
            ? _value.nextScheduledDate
            : nextScheduledDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        providerName: freezed == providerName
            ? _value.providerName
            : providerName // ignore: cast_nullable_to_non_nullable
                  as String?,
        providerContact: freezed == providerContact
            ? _value.providerContact
            : providerContact // ignore: cast_nullable_to_non_nullable
                  as String?,
        cost: freezed == cost
            ? _value.cost
            : cost // ignore: cast_nullable_to_non_nullable
                  as double?,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        documents: null == documents
            ? _value._documents
            : documents // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        isAiSuggested: null == isAiSuggested
            ? _value.isAiSuggested
            : isAiSuggested // ignore: cast_nullable_to_non_nullable
                  as bool,
        aiRiskScore: freezed == aiRiskScore
            ? _value.aiRiskScore
            : aiRiskScore // ignore: cast_nullable_to_non_nullable
                  as double?,
        aiReason: freezed == aiReason
            ? _value.aiReason
            : aiReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MaintenanceModelImpl implements _MaintenanceModel {
  const _$MaintenanceModelImpl({
    required this.id,
    required this.itemId,
    required this.tenantId,
    required this.title,
    this.description,
    this.status = 'pending',
    required this.scheduledDate,
    this.completedDate,
    this.isRecurring = false,
    this.recurrenceIntervalDays,
    this.nextScheduledDate,
    this.providerName,
    this.providerContact,
    this.cost,
    this.currency = 'USD',
    this.notes,
    final List<String> documents = const [],
    this.isAiSuggested = false,
    this.aiRiskScore,
    this.aiReason,
    this.createdAt,
    this.updatedAt,
  }) : _documents = documents;

  factory _$MaintenanceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MaintenanceModelImplFromJson(json);

  @override
  final String id;
  @override
  final String itemId;
  @override
  final String tenantId;
  @override
  final String title;
  @override
  final String? description;
  @override
  @JsonKey()
  final String status;
  @override
  final String scheduledDate;
  @override
  final String? completedDate;
  @override
  @JsonKey()
  final bool isRecurring;
  @override
  final int? recurrenceIntervalDays;
  @override
  final String? nextScheduledDate;
  @override
  final String? providerName;
  @override
  final String? providerContact;
  @override
  final double? cost;
  @override
  @JsonKey()
  final String currency;
  @override
  final String? notes;
  final List<String> _documents;
  @override
  @JsonKey()
  List<String> get documents {
    if (_documents is EqualUnmodifiableListView) return _documents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_documents);
  }

  @override
  @JsonKey()
  final bool isAiSuggested;
  @override
  final double? aiRiskScore;
  @override
  final String? aiReason;
  @override
  final String? createdAt;
  @override
  final String? updatedAt;

  @override
  String toString() {
    return 'MaintenanceModel(id: $id, itemId: $itemId, tenantId: $tenantId, title: $title, description: $description, status: $status, scheduledDate: $scheduledDate, completedDate: $completedDate, isRecurring: $isRecurring, recurrenceIntervalDays: $recurrenceIntervalDays, nextScheduledDate: $nextScheduledDate, providerName: $providerName, providerContact: $providerContact, cost: $cost, currency: $currency, notes: $notes, documents: $documents, isAiSuggested: $isAiSuggested, aiRiskScore: $aiRiskScore, aiReason: $aiReason, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MaintenanceModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.scheduledDate, scheduledDate) ||
                other.scheduledDate == scheduledDate) &&
            (identical(other.completedDate, completedDate) ||
                other.completedDate == completedDate) &&
            (identical(other.isRecurring, isRecurring) ||
                other.isRecurring == isRecurring) &&
            (identical(other.recurrenceIntervalDays, recurrenceIntervalDays) ||
                other.recurrenceIntervalDays == recurrenceIntervalDays) &&
            (identical(other.nextScheduledDate, nextScheduledDate) ||
                other.nextScheduledDate == nextScheduledDate) &&
            (identical(other.providerName, providerName) ||
                other.providerName == providerName) &&
            (identical(other.providerContact, providerContact) ||
                other.providerContact == providerContact) &&
            (identical(other.cost, cost) || other.cost == cost) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            const DeepCollectionEquality()
                .equals(other._documents, _documents) &&
            (identical(other.isAiSuggested, isAiSuggested) ||
                other.isAiSuggested == isAiSuggested) &&
            (identical(other.aiRiskScore, aiRiskScore) ||
                other.aiRiskScore == aiRiskScore) &&
            (identical(other.aiReason, aiReason) ||
                other.aiReason == aiReason) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    itemId,
    tenantId,
    title,
    description,
    status,
    scheduledDate,
    completedDate,
    isRecurring,
    recurrenceIntervalDays,
    nextScheduledDate,
    providerName,
    providerContact,
    cost,
    currency,
    notes,
    const DeepCollectionEquality().hash(_documents),
    isAiSuggested,
    aiRiskScore,
    aiReason,
    createdAt,
    updatedAt,
  ]);

  /// Create a copy of MaintenanceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MaintenanceModelImplCopyWith<_$MaintenanceModelImpl> get copyWith =>
      __$$MaintenanceModelImplCopyWithImpl<_$MaintenanceModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MaintenanceModelImplToJson(this);
  }
}

abstract class _MaintenanceModel implements MaintenanceModel {
  const factory _MaintenanceModel({
    required final String id,
    required final String itemId,
    required final String tenantId,
    required final String title,
    final String? description,
    final String status,
    required final String scheduledDate,
    final String? completedDate,
    final bool isRecurring,
    final int? recurrenceIntervalDays,
    final String? nextScheduledDate,
    final String? providerName,
    final String? providerContact,
    final double? cost,
    final String currency,
    final String? notes,
    final List<String> documents,
    final bool isAiSuggested,
    final double? aiRiskScore,
    final String? aiReason,
    final String? createdAt,
    final String? updatedAt,
  }) = _$MaintenanceModelImpl;

  factory _MaintenanceModel.fromJson(Map<String, dynamic> json) =
      _$MaintenanceModelImpl.fromJson;

  @override
  String get id;
  @override
  String get itemId;
  @override
  String get tenantId;
  @override
  String get title;
  @override
  String? get description;
  @override
  String get status;
  @override
  String get scheduledDate;
  @override
  String? get completedDate;
  @override
  bool get isRecurring;
  @override
  int? get recurrenceIntervalDays;
  @override
  String? get nextScheduledDate;
  @override
  String? get providerName;
  @override
  String? get providerContact;
  @override
  double? get cost;
  @override
  String get currency;
  @override
  String? get notes;
  @override
  List<String> get documents;
  @override
  bool get isAiSuggested;
  @override
  double? get aiRiskScore;
  @override
  String? get aiReason;
  @override
  String? get createdAt;
  @override
  String? get updatedAt;

  /// Create a copy of MaintenanceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MaintenanceModelImplCopyWith<_$MaintenanceModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
