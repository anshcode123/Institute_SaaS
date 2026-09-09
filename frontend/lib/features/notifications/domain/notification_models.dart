class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? entityType;
  final String? entityId;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.entityType,
    this.entityId,
    this.readAt,
  });

  bool get isUnread => readAt == null;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        entityType: json['entityType'] as String?,
        entityId: json['entityId'] as String?,
        readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class NotificationsPage {
  final List<AppNotification> items;
  final int total;
  final int unreadCount;

  const NotificationsPage({required this.items, required this.total, required this.unreadCount});

  factory NotificationsPage.fromJson(Map<String, dynamic> json) => NotificationsPage(
        items: (json['items'] as List).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList(),
        total: json['total'] as int,
        unreadCount: json['unreadCount'] as int,
      );
}
