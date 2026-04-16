class AiRoomSuggestion {
  const AiRoomSuggestion({
    required this.roomId,
    required this.name,
    required this.reasoning,
  });

  final String roomId;
  final String name;
  final String reasoning;

  factory AiRoomSuggestion.fromJson(Map<String, dynamic> json) =>
      AiRoomSuggestion(
        roomId: json['roomId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        reasoning: json['reasoning'] as String? ?? '',
      );
}

class AiInvoiceData {
  const AiInvoiceData({
    this.purchasePrice,
    this.purchaseDate,
    this.serialNumber,
    this.store,
    this.warrantyMonths,
  });

  final int? purchasePrice;
  final String? purchaseDate;
  final String? serialNumber;
  final String? store;
  final int? warrantyMonths;

  factory AiInvoiceData.fromJson(Map<String, dynamic> json) => AiInvoiceData(
        purchasePrice: (json['purchasePrice'] as num?)?.toInt(),
        purchaseDate: json['purchaseDate'] as String?,
        serialNumber: json['serialNumber'] as String?,
        store: json['store'] as String?,
        warrantyMonths: (json['warrantyMonths'] as num?)?.toInt(),
      );
}

class AiScanResult {
  const AiScanResult({
    required this.name,
    required this.category,
    this.subcategory = '',
    this.brand,
    this.estimatedValue,
    this.attributes = const {},
    this.confidence = 0.0,
    this.tags = const [],
    this.suggestedRoom,
    this.invoiceData,
    this.capturedPhotoUrls = const [],
  });

  final String name;
  final String category;
  final String subcategory;
  final String? brand;
  final int? estimatedValue;
  final Map<String, dynamic> attributes;
  final double confidence;
  final List<String> tags;
  final AiRoomSuggestion? suggestedRoom;
  final AiInvoiceData? invoiceData;
  final List<String> capturedPhotoUrls;

  factory AiScanResult.fromJson(Map<String, dynamic> json) {
    final roomJson = json['suggestedRoom'] as Map<String, dynamic>?;
    final invoiceJson = json['invoiceData'] as Map<String, dynamic>?;
    final rawTags = json['tags'] as List<dynamic>?;

    return AiScanResult(
      name: json['name'] as String? ?? 'Unknown item',
      category: json['category'] as String? ?? 'other',
      subcategory: json['subcategory'] as String? ?? '',
      brand: json['brand'] as String?,
      estimatedValue: (json['estimatedValue'] as num?)?.toInt(),
      attributes: (json['attributes'] as Map<String, dynamic>?) ?? {},
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      tags: rawTags?.map((t) => t.toString()).toList() ?? [],
      suggestedRoom:
          roomJson != null ? AiRoomSuggestion.fromJson(roomJson) : null,
      invoiceData:
          invoiceJson != null ? AiInvoiceData.fromJson(invoiceJson) : null,
    );
  }

  AiScanResult copyWith({
    String? name,
    String? category,
    String? subcategory,
    String? brand,
    int? estimatedValue,
    Map<String, dynamic>? attributes,
    double? confidence,
    List<String>? tags,
    AiRoomSuggestion? suggestedRoom,
    AiInvoiceData? invoiceData,
    List<String>? capturedPhotoUrls,
  }) =>
      AiScanResult(
        name: name ?? this.name,
        category: category ?? this.category,
        subcategory: subcategory ?? this.subcategory,
        brand: brand ?? this.brand,
        estimatedValue: estimatedValue ?? this.estimatedValue,
        attributes: attributes ?? this.attributes,
        confidence: confidence ?? this.confidence,
        tags: tags ?? this.tags,
        suggestedRoom: suggestedRoom ?? this.suggestedRoom,
        invoiceData: invoiceData ?? this.invoiceData,
        capturedPhotoUrls: capturedPhotoUrls ?? this.capturedPhotoUrls,
      );
}
