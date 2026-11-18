import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/l10n/l10n.dart';

import '../../domain/entities/scanned_medicine.dart';
import '../../domain/repositories/prescription_scan_repository.dart';
import '../../domain/services/prescription_text_parser.dart';
import '../datasources/prescription_scanner.dart';

class PrescriptionScanRepositoryImpl implements PrescriptionScanRepository {
  final PrescriptionScanner scanner;
  final PrescriptionTextParser parser;

  PrescriptionScanRepositoryImpl({
    required this.scanner,
    this.parser = const PrescriptionTextParser(),
  });

  @override
  Future<Either<Failure, PrescriptionScan?>> scan(
      ScanSource source) async {
    try {
      final path = await scanner.pickImage(source);
      if (path == null) return const Right(null);
      final medicines = parser.parse(await scanner.readLines(path));
      return Right(PrescriptionScan(medicines: medicines, imagePath: path));
    } on PlatformException catch (e) {
      debugPrint('Scan failed: ${e.code} ${e.message}');
      final denied = e.code.contains('denied');
      return Left(ValidationFailure(denied
          ? 'Allow camera and photo access in Settings to scan.'.tr
          : 'Could not read the picture. Please try again.'.tr));
    } catch (e) {
      debugPrint('Scan failed: $e');
      // e.g. MissingPluginException on web / desktop.
      return Left(ValidationFailure(
          'Scanning is not available on this device.'.tr));
    }
  }
}
