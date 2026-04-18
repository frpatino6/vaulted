// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outfit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OutfitItemPreviewModelImpl _$$OutfitItemPreviewModelImplFromJson(
  Map<String, dynamic> json,
) => _$OutfitItemPreviewModelImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  photo: json['photo'] as String?,
  category: json['category'] as String?,
  type: json['type'] as String?,
  cleaningStatus: json['cleaningStatus'] as String?,
);

Map<String, dynamic> _$$OutfitItemPreviewModelImplToJson(
  _$OutfitItemPreviewModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'photo': instance.photo,
  'category': instance.category,
  'type': instance.type,
  'cleaningStatus': instance.cleaningStatus,
};

_$OutfitModelImpl _$$OutfitModelImplFromJson(
  Map<String, dynamic> json,
) => _$OutfitModelImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  itemIds:
      (json['itemIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  season: json['season'] as String?,
  occasion: json['occasion'] as String?,
  photos:
      (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  items:
      (json['items'] as List<dynamic>?)
          ?.map(
            (e) => OutfitItemPreviewModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <OutfitItemPreviewModel>[],
  createdAt: json['createdAt'] as String?,
);

Map<String, dynamic> _$$OutfitModelImplToJson(_$OutfitModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'itemIds': instance.itemIds,
      'season': instance.season,
      'occasion': instance.occasion,
      'photos': instance.photos,
      'items': instance.items,
      'createdAt': instance.createdAt,
    };
