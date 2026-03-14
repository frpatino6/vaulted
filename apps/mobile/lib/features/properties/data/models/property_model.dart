import 'package:freezed_annotation/freezed_annotation.dart';

import 'address_model.dart';
import 'floor_model.dart';

part 'property_model.freezed.dart';

@freezed
class PropertyModel with _$PropertyModel {
  const factory PropertyModel({
    required String id,
    required String tenantId,
    required String name,
    required String type,
    required AddressModel address,
    @Default([]) List<FloorModel> floors,
    @Default([]) List<String> photos,
  }) = _PropertyModel;

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json);
    final id = data['id'] ?? data['_id'];
    if (id == null) throw ArgumentError('Property must have id or _id');
    data['id'] = id is String ? id : id.toString();

    final floorsJson = data['floors'];
    final photosJson = data['photos'];

    return PropertyModel(
      id: data['id'] as String,
      tenantId: data['tenantId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? '',
      address: AddressModel.fromJson(
        Map<String, dynamic>.from(data['address'] as Map? ?? {}),
      ),
      floors: floorsJson is List
          ? floorsJson
                .whereType<Map>()
                .map(
                  (floor) =>
                      FloorModel.fromJson(Map<String, dynamic>.from(floor)),
                )
                .toList()
          : const <FloorModel>[],
      photos: photosJson is List
          ? photosJson.whereType<String>().toList()
          : const <String>[],
    );
  }
}
