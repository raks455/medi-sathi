import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/scanned_medicine.dart';
import '../repositories/prescription_scan_repository.dart';

/// Right(null) means the user cancelled picking a photo.
class ScanPrescription implements UseCase<List<ScannedMedicine>?, ScanSource> {
  final PrescriptionScanRepository repository;
  ScanPrescription(this.repository);

  @override
  Future<Either<Failure, List<ScannedMedicine>?>> call(ScanSource source) =>
      repository.scan(source);
}
