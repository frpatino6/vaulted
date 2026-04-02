class DryCleaningModel {
  const DryCleaningModel({
    required this.id,
    required this.itemId,
    required this.sentDate,
    this.returnedDate,
    this.cleanerName,
    this.cost,
    this.currency = 'USD',
    this.notes,
    this.createdAt,
  });

  final String id;
  final String itemId;
  final DateTime sentDate;
  final DateTime? returnedDate;
  final String? cleanerName;
  final double? cost;
  final String currency;
  final String? notes;
  final DateTime? createdAt;

  factory DryCleaningModel.fromJson(Map<String, dynamic> json) {
    return DryCleaningModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      itemId: (json['itemId'] ?? '').toString(),
      sentDate: DateTime.parse((json['sentDate'] ?? '').toString()),
      returnedDate: json['returnedDate'] == null
          ? null
          : DateTime.tryParse(json['returnedDate'].toString()),
      cleanerName: json['cleanerName'] as String?,
      cost: (json['cost'] as num?)?.toDouble(),
      currency: (json['currency'] as String?) ?? 'USD',
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

Map<String, dynamic> normalizeDryCleaningJson(Map<String, dynamic> json) {
  final dynamic id = json['id'] ?? json['_id'];
  if (id != null) {
    json['id'] = id is String ? id : id.toString();
  }
  return json;
}
