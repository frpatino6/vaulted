// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MovementItemModelImpl _$$MovementItemModelImplFromJson(
  Map<String, dynamic> json,
) => _$MovementItemModelImpl(
  itemId: json['itemId'] as String,
  itemName: json['itemName'] as String,
  itemCategory: json['itemCategory'] as String? ?? '',
  itemPhoto: json['itemPhoto'] as String? ?? '',
  fromPropertyId: json['fromPropertyId'] as String? ?? '',
  fromRoomId: json['fromRoomId'] as String? ?? '',
  fromPropertyName: json['fromPropertyName'] as String? ?? '',
  fromRoomName: json['fromRoomName'] as String? ?? '',
  scannedAt: json['scannedAt'] as String?,
  checkedInAt: json['checkedInAt'] as String?,
  checkedInBy: json['checkedInBy'] as String?,
  status: json['status'] as String? ?? 'out',
);

Map<String, dynamic> _$$MovementItemModelImplToJson(
  _$MovementItemModelImpl instance,
) => <String, dynamic>{
  'itemId': instance.itemId,
  'itemName': instance.itemName,
  'itemCategory': instance.itemCategory,
  'itemPhoto': instance.itemPhoto,
  'fromPropertyId': instance.fromPropertyId,
  'fromRoomId': instance.fromRoomId,
  'fromPropertyName': instance.fromPropertyName,
  'fromRoomName': instance.fromRoomName,
  'scannedAt': instance.scannedAt,
  'checkedInAt': instance.checkedInAt,
  'checkedInBy': instance.checkedInBy,
  'status': instance.status,
};

_$MovementModelImpl _$$MovementModelImplFromJson(Map<String, dynamic> json) =>
    _$MovementModelImpl(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      operationType: json['operationType'] as String,
      status: json['status'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      destinationPropertyId: json['destinationPropertyId'] as String? ?? '',
      destinationRoomId: json['destinationRoomId'] as String? ?? '',
      destinationPropertyName: json['destinationPropertyName'] as String? ?? '',
      destinationRoomName: json['destinationRoomName'] as String? ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => MovementItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      createdBy: json['createdBy'] as String,
      propertyId: json['propertyId'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      activatedAt: json['activatedAt'] as String?,
      completedAt: json['completedAt'] as String?,
      dueDate: json['dueDate'] as String?,
      notes: json['notes'] as String? ?? '',
    );

Map<String, dynamic> _$$MovementModelImplToJson(_$MovementModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'operationType': instance.operationType,
      'status': instance.status,
      'title': instance.title,
      'description': instance.description,
      'destination': instance.destination,
      'destinationPropertyId': instance.destinationPropertyId,
      'destinationRoomId': instance.destinationRoomId,
      'destinationPropertyName': instance.destinationPropertyName,
      'destinationRoomName': instance.destinationRoomName,
      'items': instance.items,
      'createdBy': instance.createdBy,
      'propertyId': instance.propertyId,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'activatedAt': instance.activatedAt,
      'completedAt': instance.completedAt,
      'dueDate': instance.dueDate,
      'notes': instance.notes,
    };
