import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/device_timezone.dart';
import '../../domain/entities/dose.dart';
import '../models/dose_schedule_model.dart';

abstract class ReminderRemoteDataSource {
  Future<DoseSchedule> getToday();
  Future<DoseSchedule> getSchedule(DateTime startDate, DateTime endDate);

  /// Returns the status and response time the server saved.
  Future<({DoseStatus status, DateTime? respondedAt})> logDose({
    required String medicationId,
    required DateTime scheduledFor,
    required DoseStatus status,
  });
}

class ReminderRemoteDataSourceImpl implements ReminderRemoteDataSource {
  final Dio dio;
  ReminderRemoteDataSourceImpl(this.dio);

  @override
  Future<DoseSchedule> getToday() => _guard(() async {
        final tz = await DeviceTimezone.get();
        final res = await dio.get(
          ApiConstants.todaysRemindersWithStatus,
          // Decides what "today" is; the server has a default if unknown.
          queryParameters: {if (tz != null) 'tz': tz},
        );
        return DoseScheduleModel.fromJson(res.data as Map<String, dynamic>);
      });

  @override
  Future<DoseSchedule> getSchedule(DateTime startDate, DateTime endDate) =>
      _guard(() async {
        final res = await dio.get(
          ApiConstants.getRemindersSchedule,
          queryParameters: {
            'start_date': _date(startDate),
            'end_date': _date(endDate),
          },
        );
        return DoseScheduleModel.fromJson(res.data as Map<String, dynamic>);
      });

  @override
  Future<({DoseStatus status, DateTime? respondedAt})> logDose({
    required String medicationId,
    required DateTime scheduledFor,
    required DoseStatus status,
  }) =>
      _guard(() async {
        final res = await dio.post(ApiConstants.markADose, data: {
          'medication_id': medicationId,
          // Must carry a timezone: UTC ISO-8601 ends with 'Z'.
          'scheduled_for': scheduledFor.toUtc().toIso8601String(),
          'status': status.name,
        });
        final json = res.data as Map<String, dynamic>;
        final respondedAt = json['responded_at'];
        return (
          status: DoseStatus.fromApi(json['status'] as String),
          respondedAt:
              respondedAt is String ? DateTime.tryParse(respondedAt) : null,
        );
      });

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
