import 'package:freezed_annotation/freezed_annotation.dart';

part 'at_laundry_model.freezed.dart';
part 'at_laundry_model.g.dart';

@freezed
class AtLaundryItem with _$AtLaundryItem {
  const factory AtLaundryItem({
    @JsonKey(name: 'recordId') required String recordId,
    @JsonKey(name: 'itemId') required String itemId,
    @JsonKey(name: 'itemName') required String itemName,
    @JsonKey(name: 'photoUrl') String? photoUrl,
    @JsonKey(name: 'cleanerName') String? cleanerName,
    @JsonKey(name: 'sentDate') required DateTime sentDate,
    @JsonKey(name: 'daysAtCleaner') required int daysAtCleaner,
    @JsonKey(name: 'isOverdue') required bool isOverdue,
    double? cost,
    @Default('USD') String currency,
  }) = _AtLaundryItem;

  factory AtLaundryItem.fromJson(Map<String, dynamic> json) =>
      _$AtLaundryItemFromJson(json);
}

@freezed
class AtLaundryProperty with _$AtLaundryProperty {
  const factory AtLaundryProperty({
    @JsonKey(name: 'propertyId') required String propertyId,
    @JsonKey(name: 'propertyName') required String propertyName,
    required List<AtLaundryItem> items,
  }) = _AtLaundryProperty;

  factory AtLaundryProperty.fromJson(Map<String, dynamic> json) =>
      _$AtLaundryPropertyFromJson(json);
}

@freezed
class AtLaundryData with _$AtLaundryData {
  const factory AtLaundryData({
    @JsonKey(name: 'totalItems') required int totalItems,
    @JsonKey(name: 'overdueItems') required int overdueItems,
    @Default(7) @JsonKey(name: 'overdueThresholdDays') int overdueThresholdDays,
    @JsonKey(name: 'byProperty') required List<AtLaundryProperty> byProperty,
  }) = _AtLaundryData;

  factory AtLaundryData.fromJson(Map<String, dynamic> json) =>
      _$AtLaundryDataFromJson(json);
}
