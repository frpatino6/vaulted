import 'package:freezed_annotation/freezed_annotation.dart';

import 'address_model.dart';
import 'floor_model.dart';

part 'property_model.freezed.dart';
part 'property_model.g.dart';

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
    return _$$PropertyModelImplFromJson(data);
  }
}
