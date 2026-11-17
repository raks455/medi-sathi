import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/repository_guard.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remote;
  NotificationRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, NotificationPage>> getNotifications(
          {required int limit, required int offset}) =>
      guardApiCall(() => remote.getNotifications(limit: limit, offset: offset));

  @override
  Future<Either<Failure, Unit>> markRead(String id) => guardApiCall(() async {
        await remote.markRead(id);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> markAllRead() => guardApiCall(() async {
        await remote.markAllRead();
        return unit;
      });
}
