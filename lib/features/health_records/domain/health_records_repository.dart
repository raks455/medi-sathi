import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import 'health_record.dart';

abstract class HealthRecordsRepository {
  /// Every record in both folders, newest document date first.
  Future<Either<Failure, List<HealthRecord>>> getRecords();

  Future<Either<Failure, StorageUsage>> getUsage();

  Future<Either<Failure, HealthRecord>> upload({
    required LocalFile file,
    required RecordFolder folder,
    required RecordCategory category,
    String? title,
    String? notes,
    DateTime? documentDate,
  });

  Future<Either<Failure, HealthRecord>> update(
    String id, {
    required String title,
    required RecordCategory category,
    String? notes,
    DateTime? documentDate,
  });

  Future<Either<Failure, Unit>> delete(String id);

  /// Downloads the file (once) and returns its path on the phone.
  Future<Either<Failure, String>> fileOnDevice(HealthRecord record);
}
