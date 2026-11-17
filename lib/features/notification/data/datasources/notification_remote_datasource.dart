import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_error.dart';
import '../../domain/entities/app_notification.dart';

abstract class NotificationRemoteDataSource {
  /// [platform] is 'android', 'ios' or 'web'.
  Future<void> registerDevice({required String token, String? platform});
  Future<void> unregisterDevice(String token);

  /// Sends a test push; returns how many devices it was sent to.
  Future<int> sendTestPush();

  /// The in-app list, newest first.
  Future<NotificationPage> getNotifications(
      {required int limit, required int offset});
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final Dio dio;
  NotificationRemoteDataSourceImpl(this.dio);

  @override
  Future<void> registerDevice({required String token, String? platform}) =>
      _guard(() => dio.post(
            ApiConstants.registerDeviceForNotifications,
            data: {'token': token, if (platform != null) 'platform': platform},
          ));

  @override
  Future<void> unregisterDevice(String token) => _guard(() => dio.delete(
        ApiConstants.unregisterDeviceForNotifications,
        queryParameters: {'token': token},
      ));

  @override
  Future<int> sendTestPush() => _guard(() async {
        final res = await dio.post(ApiConstants.testNotification);
        return (res.data as Map<String, dynamic>)['sent_to'] as int? ?? 0;
      });

  @override
  Future<NotificationPage> getNotifications(
          {required int limit, required int offset}) =>
      _guard(() async {
        final res = await dio.get(
          ApiConstants.notifications,
          queryParameters: {'limit': limit, 'offset': offset},
        );
        final json = res.data as Map<String, dynamic>;
        return NotificationPage(
          items: (json['items'] as List)
              .map((n) => _fromJson(n as Map<String, dynamic>))
              .toList(),
          unreadCount: json['unread_count'] as int? ?? 0,
          hasMore: json['has_more'] as bool? ?? false,
        );
      });

  @override
  Future<void> markRead(String id) =>
      _guard(() => dio.post(ApiConstants.markNotificationRead(id)));

  @override
  Future<void> markAllRead() =>
      _guard(() => dio.post(ApiConstants.markAllNotificationsRead));

  static AppNotification _fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String? ?? '',
      data: (json['data'] as Map? ?? const {})
          .map((k, v) => MapEntry(k.toString(), v.toString())),
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
