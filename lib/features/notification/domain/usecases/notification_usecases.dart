import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class GetNotifications implements UseCase<NotificationPage, NotificationsParams> {
  final NotificationRepository repository;
  GetNotifications(this.repository);

  @override
  Future<Either<Failure, NotificationPage>> call(NotificationsParams p) =>
      repository.getNotifications(limit: p.limit, offset: p.offset);
}

class NotificationsParams extends Equatable {
  final int limit;
  final int offset;
  const NotificationsParams({required this.limit, this.offset = 0});
  @override
  List<Object?> get props => [limit, offset];
}

class MarkNotificationRead implements UseCase<Unit, String> {
  final NotificationRepository repository;
  MarkNotificationRead(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String id) => repository.markRead(id);
}

class MarkAllNotificationsRead implements UseCase<Unit, NoParams> {
  final NotificationRepository repository;
  MarkAllNotificationsRead(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams p) => repository.markAllRead();
}
