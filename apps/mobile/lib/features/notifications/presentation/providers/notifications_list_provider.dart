import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/notification_item.dart';
import 'notifications_provider.dart';

class NotificationsListNotifier
    extends AsyncNotifier<NotificationsPage> {
  @override
  Future<NotificationsPage> build() async {
    final json = await ref
        .read(notificationsDataSourceProvider)
        .getNotifications();
    return NotificationsPage.fromJson(json);
  }

  Future<void> markRead(String id) async {
    await ref.read(notificationsDataSourceProvider).markRead(id);
    state = state.whenData((page) => NotificationsPage(
          items: page.items
              .map((n) => n.id == id ? _markItemRead(n) : n)
              .toList(),
          total: page.total,
          unreadCount: page.unreadCount > 0 ? page.unreadCount - 1 : 0,
        ));
  }

  Future<void> markAllRead() async {
    await ref.read(notificationsDataSourceProvider).markAllRead();
    state = state.whenData((page) => NotificationsPage(
          items: page.items.map(_markItemRead).toList(),
          total: page.total,
          unreadCount: 0,
        ));
  }

  NotificationItem _markItemRead(NotificationItem n) {
    if (n.isRead) return n;
    return NotificationItem(
      id: n.id,
      tenantId: n.tenantId,
      userId: n.userId,
      type: n.type,
      title: n.title,
      body: n.body,
      createdAt: n.createdAt,
      data: n.data,
      readAt: DateTime.now(),
    );
  }
}

final notificationsListProvider =
    AsyncNotifierProvider<NotificationsListNotifier, NotificationsPage>(
  NotificationsListNotifier.new,
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsListProvider).whenData((p) => p.unreadCount).valueOrNull ?? 0;
});
