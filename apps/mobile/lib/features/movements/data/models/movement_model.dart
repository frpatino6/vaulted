import 'package:freezed_annotation/freezed_annotation.dart';

part 'movement_model.freezed.dart';
part 'movement_model.g.dart';

@freezed
class MovementItemModel with _$MovementItemModel {
  const factory MovementItemModel({
    required String itemId,
    required String itemName,
    @Default('') String itemCategory,
    @Default('') String itemPhoto,
    @Default('') String fromPropertyId,
    @Default('') String fromRoomId,
    @Default('') String fromPropertyName,
    @Default('') String fromRoomName,
    String? scannedAt,
    String? checkedInAt,
    String? checkedInBy,
    @Default('out') String status,
  }) = _MovementItemModel;

  factory MovementItemModel.fromJson(Map<String, dynamic> json) =>
      _$MovementItemModelFromJson(json);
}

@freezed
class MovementModel with _$MovementModel {
  const factory MovementModel({
    required String id,
    required String tenantId,
    required String operationType,
    required String status,
    required String title,
    @Default('') String description,
    @Default('') String destination,
    @Default([]) List<MovementItemModel> items,
    required String createdBy,
    @Default('') String propertyId,
    String? createdAt,
    String? updatedAt,
    String? activatedAt,
    String? completedAt,
    String? dueDate,
    @Default('') String notes,
  }) = _MovementModel;

  factory MovementModel.fromJson(Map<String, dynamic> json) =>
      _$MovementModelFromJson(json);
}

extension MovementModelX on MovementModel {
  bool get isDraft => status == 'draft';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isPartial => status == 'partial';
  bool get isCancelled => status == 'cancelled';
  bool get isFinished => isCompleted || isPartial || isCancelled;

  int get returnedCount =>
      items.where((i) => i.status == 'returned').length;
  int get outCount => items.where((i) => i.status == 'out').length;
  int get missingCount => items.where((i) => i.status == 'missing').length;
}
