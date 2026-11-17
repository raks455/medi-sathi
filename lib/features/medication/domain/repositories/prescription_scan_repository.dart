import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/scanned_medicine.dart';

abstract class PrescriptionScanRepository {
  /// Lets the user take / pick a photo and returns the medicines found in it
  /// (possibly none). Right(null) means the user cancelled.
  Future<Either<Failure, List<ScannedMedicine>?>> scan(ScanSource source);
}
