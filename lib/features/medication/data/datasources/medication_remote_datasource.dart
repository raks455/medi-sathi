import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/device_timezone.dart';
import '../../domain/entities/medication.dart';
import '../models/medication_model.dart';

abstract class MedicationRemoteDataSource {
  Future<List<Medication>> getMedications();
  Future<MedicationOptions> getOptions();
  Future<Medication> addMedication(MedicationInput input);
  Future<Medication> updateMedication(String id, MedicationInput input);
  Future<void> deleteMedication(String id);

  /// [stopped] true stops the medicine, false starts it again.
  Future<Medication> setStopped(String id, {required bool stopped});
}

class MedicationRemoteDataSourceImpl implements MedicationRemoteDataSource {
  final Dio dio;
  MedicationRemoteDataSourceImpl(this.dio);

  @override
  Future<List<Medication>> getMedications() => _guard(() async {
        final res = await dio.get(ApiConstants.listMedicines);
        return (res.data as List)
            .map((e) => MedicationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<MedicationOptions> getOptions() => _guard(() async {
        final res = await dio.get(ApiConstants.getMedicationTypes);
        return MedicationModel.optionsFromJson(
            res.data as Map<String, dynamic>);
      });

  @override
  Future<Medication> addMedication(MedicationInput input) => _guard(() async {
        final res = await dio.post(
          ApiConstants.addMedicine,
          data: MedicationModel.toJson(input,
              deviceTimezone: await DeviceTimezone.get()),
        );
        return MedicationModel.fromJson(res.data as Map<String, dynamic>);
      });

  @override
  Future<Medication> updateMedication(String id, MedicationInput input) =>
      _guard(() async {
        final res = await dio.patch(
          ApiConstants.medication(id),
          data: MedicationModel.toJson(input,
              deviceTimezone: await DeviceTimezone.get()),
        );
        return MedicationModel.fromJson(res.data as Map<String, dynamic>);
      });

  @override
  Future<void> deleteMedication(String id) =>
      _guard(() => dio.delete(ApiConstants.medication(id)));

  @override
  Future<Medication> setStopped(String id, {required bool stopped}) =>
      _guard(() async {
        final res = await dio.post(stopped
            ? ApiConstants.stopMedication(id)
            : ApiConstants.resumeMedication(id));
        return MedicationModel.fromJson(res.data as Map<String, dynamic>);
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
