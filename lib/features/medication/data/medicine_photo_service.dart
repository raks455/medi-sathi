import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/dio_guard.dart';
import '../../../core/network/repository_guard.dart';

/// Stores the user's photo of a medicine on the server, so it shows on the
/// medicine, on its doses and in the reminder notification.
class MedicinePhotoService {
  final Dio dio;
  MedicinePhotoService(this.dio);

  /// Uploads the image file at [path] as the photo of the medicine.
  Future<Either<Failure, Unit>> upload(String medicationId, String path) =>
      guardApiCall(() => dioGuard(() async {
            await dio.put(
              ApiConstants.medicationPhoto(medicationId),
              data: FormData.fromMap({
                'file': await MultipartFile.fromFile(path),
              }),
            );
            return unit;
          }));

  Future<Either<Failure, Unit>> remove(String medicationId) =>
      guardApiCall(() => dioGuard(() async {
            await dio.delete(ApiConstants.medicationPhoto(medicationId));
            return unit;
          }));
}
