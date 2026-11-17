import 'package:equatable/equatable.dart';

/// One entry in the in-app notification list.
class AppNotification extends Equatable {
  /// API values for [type].
  static const typeDoseReminder = 'medication_reminder';
  static const typeRefillReminder = 'refill_reminder';

  final String id;
  final String type;
  final String title;
  final String body;

  /// Extra details from the server, e.g. `medication_id`.
  final Map<String, String> data;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    required this.createdAt,
    required this.isRead,
  });

  AppNotification asRead() => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        data: data,
        createdAt: createdAt,
        isRead: true,
      );

  @override
  List<Object?> get props => [id, type, title, body, data, createdAt, isRead];
}

/// One page of the notification list.
class NotificationPage extends Equatable {
  final List<AppNotification> items;

  /// All unread notifications, not just the ones on this page.
  final int unreadCount;

  /// True if older notifications exist after this page.
  final bool hasMore;

  const NotificationPage({
    required this.items,
    required this.unreadCount,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [items, unreadCount, hasMore];
}
