/// Dashboard stats model from GET /dashboard.
class DashboardModel {
  const DashboardModel({
    required this.totalProperties,
    required this.totalItems,
    required this.itemsByStatus,
    required this.itemsByCategory,
    required this.totalValuation,
    required this.currency,
  });

  final int totalProperties;
  final int totalItems;
  final Map<String, int> itemsByStatus;
  final Map<String, int> itemsByCategory;
  final double totalValuation;
  final String currency;

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final status = json['itemsByStatus'] as Map<String, dynamic>? ?? {};
    final category = json['itemsByCategory'] as Map<String, dynamic>? ?? {};
    return DashboardModel(
      totalProperties: (json['totalProperties'] as num?)?.toInt() ?? 0,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      itemsByStatus: status.map(
        (k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0),
      ),
      itemsByCategory: category.map(
        (k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0),
      ),
      totalValuation:
          (json['totalValuation'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
    );
  }
}
