class OutfitItemPreviewModel {
  const OutfitItemPreviewModel({
    required this.id,
    required this.name,
    this.photo,
    this.category,
    this.type,
    this.cleaningStatus,
  });

  final String id;
  final String name;
  final String? photo;
  final String? category;
  final String? type;
  final String? cleaningStatus;

  factory OutfitItemPreviewModel.fromJson(Map<String, dynamic> json) {
    return OutfitItemPreviewModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      photo: json['photo'] as String?,
      category: json['category'] as String?,
      type: json['type'] as String?,
      cleaningStatus: json['cleaningStatus'] as String?,
    );
  }
}

class OutfitModel {
  const OutfitModel({
    required this.id,
    required this.name,
    this.description,
    required this.itemIds,
    this.season,
    this.occasion,
    required this.photos,
    required this.items,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final List<String> itemIds;
  final String? season;
  final String? occasion;
  final List<String> photos;
  final List<OutfitItemPreviewModel> items;
  final DateTime? createdAt;

  factory OutfitModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItemIds = (json['itemIds'] as List?) ?? <dynamic>[];
    final List<dynamic> rawPhotos = (json['photos'] as List?) ?? <dynamic>[];
    final List<dynamic> rawItems = (json['items'] as List?) ?? <dynamic>[];

    return OutfitModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description'] as String?,
      itemIds: rawItemIds.map((dynamic value) => value.toString()).toList(),
      season: json['season'] as String?,
      occasion: json['occasion'] as String?,
      photos: rawPhotos.map((dynamic value) => value.toString()).toList(),
      items: rawItems
          .map((dynamic value) => OutfitItemPreviewModel.fromJson(Map<String, dynamic>.from(value as Map)))
          .toList(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

Map<String, dynamic> normalizeOutfitJson(Map<String, dynamic> json) {
  final dynamic id = json['id'] ?? json['_id'];
  if (id != null) {
    json['id'] = id is String ? id : id.toString();
  }
  return json;
}
