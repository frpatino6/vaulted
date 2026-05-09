class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.data,
    this.readAt,
  });

  final String id;
  final String tenantId;
  final String userId;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      data: json['data'] as Map<String, dynamic>?,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
    );
  }
}

class NotificationsPage {
  const NotificationsPage({
    required this.items,
    required this.total,
    required this.unreadCount,
  });

  final List<NotificationItem> items;
  final int total;
  final int unreadCount;

  factory NotificationsPage.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>? ?? [])
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return NotificationsPage(
      items: itemsList,
      total: json['total'] as int? ?? 0,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  static NotificationsPage empty() =>
      const NotificationsPage(items: [], total: 0, unreadCount: 0);
}
