import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/dio_guard.dart';
import '../../../core/network/repository_guard.dart';
import '../../../core/utils/device_timezone.dart';
import '../domain/womens_health.dart';

class WomensHealthRemoteDataSource {
  final Dio dio;
  WomensHealthRemoteDataSource(this.dio);

  Map<String, dynamic> get _today => {'today': todayParam()};

  /// Today plus the phone's timezone, so period reminders arrive in the
  /// user's morning.
  Future<Map<String, dynamic>> _todayAndZone() async {
    final tz = await DeviceTimezone.get();
    return {..._today, if (tz != null) 'tz': tz};
  }

  Future<CycleOverview> overview() => dioGuard(() async {
        final res = await dio.get(ApiConstants.cycleOverview,
            queryParameters: {...await _todayAndZone(), 'cycles_ahead': 6});
        final j = res.data as Map<String, dynamic>;
        return CycleOverview(
          averageCycleLength: j['average_cycle_length'] as int,
          averagePeriodLength: j['average_period_length'] as int,
          lastPeriodStart: parseDate(j['last_period_start']),
          nextPeriodStart: parseDate(j['next_period_start']),
          daysUntilNextPeriod: j['days_until_next_period'] as int?,
          cycleDay: j['cycle_day'] as int?,
          phase: j['phase'] as String?,
          windows: [
            for (final w in j['windows'] as List)
              CycleWindow(
                periodStart: DateTime.parse(w['period_start'] as String),
                periodEnd: DateTime.parse(w['period_end'] as String),
                ovulationDate: DateTime.parse(w['ovulation_date'] as String),
                fertileStart: DateTime.parse(w['fertile_start'] as String),
                fertileEnd: DateTime.parse(w['fertile_end'] as String),
                predicted: w['predicted'] as bool,
              ),
          ],
          periods: [
            for (final p in j['periods'] as List)
              periodFromJson(p as Map<String, dynamic>),
          ],
        );
      });

  Future<Period> savePeriod(String? id, Map<String, dynamic> body) =>
      dioGuard(() async {
        final res = id == null
            ? await dio.post(ApiConstants.cyclePeriods,
                data: body, queryParameters: await _todayAndZone())
            : await dio.put(ApiConstants.cyclePeriod(id),
                data: body, queryParameters: _today);
        return periodFromJson(res.data as Map<String, dynamic>);
      });

  Future<void> deletePeriod(String id) =>
      dioGuard(() => dio.delete(ApiConstants.cyclePeriod(id)));

  Future<CycleSettings> settings() => dioGuard(() async {
        final res = await dio.get(ApiConstants.cycleSettings);
        return settingsFromJson(res.data as Map<String, dynamic>);
      });

  Future<CycleSettings> saveSettings(CycleSettings s) => dioGuard(() async {
        final tz = await DeviceTimezone.get();
        final res = await dio.put(ApiConstants.cycleSettings, data: {
          'period_reminders': s.periodReminders,
          'remind_days_before': s.remindDaysBefore,
          'fertile_reminders': s.fertileReminders,
          if (tz != null) 'timezone': tz,
        });
        return settingsFromJson(res.data as Map<String, dynamic>);
      });

  static CycleSettings settingsFromJson(Map<String, dynamic> j) => CycleSettings(
        periodReminders: j['period_reminders'] as bool,
        remindDaysBefore: j['remind_days_before'] as int,
        fertileReminders: j['fertile_reminders'] as bool,
      );

  Future<Pregnancy?> pregnancy() => dioGuard(() async {
        final res =
            await dio.get(ApiConstants.pregnancy, queryParameters: _today);
        final p = (res.data as Map<String, dynamic>)['pregnancy'];
        return p == null ? null : pregnancyFromJson(p as Map<String, dynamic>);
      });

  Future<Pregnancy> savePregnancy(Map<String, dynamic> body) =>
      dioGuard(() async {
        final res = await dio.put(ApiConstants.pregnancy,
            data: body, queryParameters: _today);
        return pregnancyFromJson(res.data as Map<String, dynamic>);
      });

  Future<void> deletePregnancy() =>
      dioGuard(() => dio.delete(ApiConstants.pregnancy));

  static Period periodFromJson(Map<String, dynamic> j) => Period(
        id: j['id'].toString(),
        startDate: DateTime.parse(j['start_date'] as String),
        endDate: parseDate(j['end_date']),
        flow: PeriodFlow.fromApi(j['flow'] as String?),
        notes: j['notes'] as String?,
      );

  static Pregnancy pregnancyFromJson(Map<String, dynamic> j) => Pregnancy(
        id: j['id'].toString(),
        lastPeriodDate: DateTime.parse(j['last_period_date'] as String),
        dueDate: DateTime.parse(j['due_date'] as String),
        notes: j['notes'] as String?,
        weeks: j['weeks'] as int,
        days: j['days'] as int,
        trimester: j['trimester'] as int,
        daysRemaining: j['days_remaining'] as int,
        percentComplete: (j['percent_complete'] as num).toDouble(),
        babySize: j['baby_size'] as String?,
        tip: j['tip'] as String,
      );
}

class WomensHealthRepositoryImpl implements WomensHealthRepository {
  final WomensHealthRemoteDataSource remote;
  WomensHealthRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, CycleOverview>> getCycleOverview() =>
      guardApiCall(remote.overview);

  @override
  Future<Either<Failure, Period>> savePeriod({
    String? id,
    required DateTime start,
    DateTime? end,
    PeriodFlow? flow,
    String? notes,
  }) =>
      guardApiCall(() => remote.savePeriod(id, {
            'start_date': formatApiDate(start),
            'end_date': end == null ? null : formatApiDate(end),
            'flow': flow?.apiValue,
            'notes': notes,
          }));

  @override
  Future<Either<Failure, Unit>> deletePeriod(String id) =>
      guardApiCall(() async {
        await remote.deletePeriod(id);
        return unit;
      });

  @override
  Future<Either<Failure, CycleSettings>> getSettings() =>
      guardApiCall(remote.settings);

  @override
  Future<Either<Failure, CycleSettings>> saveSettings(CycleSettings settings) =>
      guardApiCall(() => remote.saveSettings(settings));

  @override
  Future<Either<Failure, Pregnancy?>> getPregnancy() =>
      guardApiCall(remote.pregnancy);

  @override
  Future<Either<Failure, Pregnancy>> savePregnancy(
          {DateTime? lastPeriodDate, DateTime? dueDate, String? notes}) =>
      guardApiCall(() => remote.savePregnancy({
            if (lastPeriodDate != null)
              'last_period_date': formatApiDate(lastPeriodDate),
            if (dueDate != null) 'due_date': formatApiDate(dueDate),
            if (notes != null) 'notes': notes,
          }));

  @override
  Future<Either<Failure, Unit>> deletePregnancy() => guardApiCall(() async {
        await remote.deletePregnancy();
        return unit;
      });
}
