import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_notification.dart';

/// The in-app notification list.
abstract class NotificationRepository {
  Future<Either<Failure, NotificationPage>> getNotifications(
      {required int limit, required int offset});
  Future<Either<Failure, Unit>> markRead(String id);
  Future<Either<Failure, Unit>> markAllRead();
}
