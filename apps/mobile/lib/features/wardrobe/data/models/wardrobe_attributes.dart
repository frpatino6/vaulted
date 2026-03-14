class WardrobeAttributes {
  const WardrobeAttributes({
    this.size,
    this.color,
    this.brand,
    this.season,
    this.cleaningStatus,
    this.material,
    this.type,
  });

  final String? size;
  final String? color;
  final String? brand;
  final String? season;
  final String? cleaningStatus;
  final String? material;
  final String? type;

  factory WardrobeAttributes.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const WardrobeAttributes();
    return WardrobeAttributes(
      size: map['size'] as String?,
      color: map['color'] as String?,
      brand: map['brand'] as String?,
      season: map['season'] as String?,
      cleaningStatus: map['cleaningStatus'] as String?,
      material: map['material'] as String?,
      type: map['type'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    if (size != null) 'size': size,
    if (color != null) 'color': color,
    if (brand != null) 'brand': brand,
    if (season != null) 'season': season,
    if (cleaningStatus != null) 'cleaningStatus': cleaningStatus,
    if (material != null) 'material': material,
    if (type != null) 'type': type,
  };

  static const List<String> types = [
    'clothing',
    'footwear',
    'accessories',
    'jewelry_watches',
  ];

  static const List<String> seasons = [
    'spring_summer',
    'fall_winter',
    'all_season',
  ];

  static const List<String> cleaningStatuses = [
    'clean',
    'needs_cleaning',
    'at_dry_cleaner',
  ];
}
