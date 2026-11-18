import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/dio_guard.dart';
import '../../../core/network/repository_guard.dart';
import '../domain/wellness.dart';

class WellnessRemoteDataSource {
  final Dio dio;
  WellnessRemoteDataSource(this.dio);

  Future<VitalsSummary> vitalsSummary() => dioGuard(() async {
        final j = (await dio.get(ApiConstants.vitalsSummary)).data
            as Map<String, dynamic>;
        VitalReading? r(String key) => j[key] == null
            ? null
            : vitalFromJson(j[key] as Map<String, dynamic>);
        return VitalsSummary(
          weight: r('weight'),
          height: r('height'),
          bloodPressure: r('blood_pressure'),
          bmi: (j['bmi'] as num?)?.toDouble(),
          bmiCategory: j['bmi_category'] as String?,
          weightChange30d: (j['weight_change_30d'] as num?)?.toDouble(),
        );
      });

  Future<List<VitalReading>> vitals(VitalType type, {int? days}) =>
      dioGuard(() async {
        final res = await dio.get(ApiConstants.vitals, queryParameters: {
          'type': type.apiValue,
          if (days != null) 'days': days,
        });
        return (res.data as List)
            .map((j) => vitalFromJson(j as Map<String, dynamic>))
            .toList();
      });

  Future<VitalReading> addVital(Map<String, dynamic> body) =>
      dioGuard(() async {
        final res = await dio.post(ApiConstants.vitals, data: body);
        return vitalFromJson(res.data as Map<String, dynamic>);
      });

  Future<VitalReading> updateVital(String id, Map<String, dynamic> body) =>
      dioGuard(() async {
        final res = await dio.put(ApiConstants.vital(id), data: body);
        return vitalFromJson(res.data as Map<String, dynamic>);
      });

  Future<void> deleteVital(String id) =>
      dioGuard(() => dio.delete(ApiConstants.vital(id)));

  Future<List<MoodEntry>> moods(int days) => dioGuard(() async {
        final res =
            await dio.get(ApiConstants.moods, queryParameters: {'days': days});
        return ((res.data as Map<String, dynamic>)['items'] as List)
            .map((j) => moodFromJson(j as Map<String, dynamic>))
            .toList();
      });

  Future<MoodEntry> addMood(Map<String, dynamic> body) => dioGuard(() async {
        final res = await dio.post(ApiConstants.moods, data: body);
        return moodFromJson(res.data as Map<String, dynamic>);
      });

  Future<void> deleteMood(String id) =>
      dioGuard(() => dio.delete(ApiConstants.mood(id)));

  static VitalReading vitalFromJson(Map<String, dynamic> j) => VitalReading(
        id: j['id'].toString(),
        type: VitalType.fromApi(j['type'] as String),
        value: (j['value'] as num).toDouble(),
        value2: (j['value2'] as num?)?.toDouble(),
        pulse: j['pulse'] as int?,
        note: j['note'] as String?,
        recordedAt: DateTime.parse(j['recorded_at'] as String),
        category: j['category'] as String?,
      );

  static MoodEntry moodFromJson(Map<String, dynamic> j) => MoodEntry(
        id: j['id'].toString(),
        mood: Mood.fromApi(j['mood'] as String),
        note: j['note'] as String?,
        tags: [for (final t in (j['tags'] as List? ?? const [])) t.toString()],
        recordedAt: DateTime.parse(j['recorded_at'] as String),
      );
}

/// The units the user picked for weight and height, kept on the phone.
class VitalUnitsStore {
  static const _weightKey = 'vitals_weight_unit';
  static const _heightKey = 'vitals_height_unit';
  final SharedPreferences prefs;
  VitalUnitsStore(this.prefs);

  WeightUnit get weight => WeightUnit.fromName(prefs.getString(_weightKey));
  HeightUnit get height => HeightUnit.fromName(prefs.getString(_heightKey));

  Future<void> setWeight(WeightUnit unit) =>
      prefs.setString(_weightKey, unit.name);
  Future<void> setHeight(HeightUnit unit) =>
      prefs.setString(_heightKey, unit.name);
}

class WellnessRepositoryImpl implements WellnessRepository {
  final WellnessRemoteDataSource remote;
  WellnessRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, VitalsSummary>> getVitalsSummary() =>
      guardApiCall(remote.vitalsSummary);

  @override
  Future<Either<Failure, List<VitalReading>>> getVitals(VitalType type,
          {int? days}) =>
      guardApiCall(() => remote.vitals(type, days: days));

  static Map<String, dynamic> _vitalBody(VitalInput v) => {
        'type': v.type.apiValue,
        'value': v.value,
        if (v.value2 != null) 'value2': v.value2,
        if (v.pulse != null) 'pulse': v.pulse,
        if (v.note != null && v.note!.trim().isNotEmpty) 'note': v.note!.trim(),
        if (v.recordedAt != null)
          'recorded_at': v.recordedAt!.toUtc().toIso8601String(),
      };

  @override
  Future<Either<Failure, VitalReading>> addVital(VitalInput input) =>
      guardApiCall(() => remote.addVital(_vitalBody(input)));

  @override
  Future<Either<Failure, VitalReading>> updateVital(
          String id, VitalInput input) =>
      guardApiCall(() => remote.updateVital(id, _vitalBody(input)));

  @override
  Future<Either<Failure, Unit>> deleteVital(String id) =>
      guardApiCall(() async {
        await remote.deleteVital(id);
        return unit;
      });

  @override
  Future<Either<Failure, List<MoodEntry>>> getMoods({int days = 30}) =>
      guardApiCall(() => remote.moods(days));

  @override
  Future<Either<Failure, MoodEntry>> addMood(Mood mood,
          {String? note, List<String> tags = const []}) =>
      guardApiCall(() => remote.addMood({
            'mood': mood.apiValue,
            if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
            'tags': tags,
          }));

  @override
  Future<Either<Failure, Unit>> deleteMood(String id) =>
      guardApiCall(() async {
        await remote.deleteMood(id);
        return unit;
      });
}
