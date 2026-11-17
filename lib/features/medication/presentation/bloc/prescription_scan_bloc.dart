import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/scanned_medicine.dart';
import '../../domain/usecases/scan_prescription.dart';

/// Take / pick a photo and look for medicines in it.
class ScanRequested extends Equatable {
  final ScanSource source;
  const ScanRequested(this.source);
  @override
  List<Object?> get props => [source];
}

enum ScanStatus { idle, scanning, done, failure }

class PrescriptionScanState extends Equatable {
  final ScanStatus status;

  /// Medicines found by the last scan (empty when nothing was recognised).
  final List<ScannedMedicine> medicines;
  final String? message;

  const PrescriptionScanState({
    this.status = ScanStatus.idle,
    this.medicines = const [],
    this.message,
  });

  @override
  List<Object?> get props => [status, medicines, message];
}

class PrescriptionScanBloc extends Bloc<ScanRequested, PrescriptionScanState> {
  final ScanPrescription scanPrescription;

  PrescriptionScanBloc({required this.scanPrescription})
      : super(const PrescriptionScanState()) {
    on<ScanRequested>(_onRequested);
  }

  Future<void> _onRequested(
      ScanRequested e, Emitter<PrescriptionScanState> emit) async {
    if (state.status == ScanStatus.scanning) return;
    final before = state;
    emit(const PrescriptionScanState(status: ScanStatus.scanning));
    final result = await scanPrescription(e.source);
    emit(result.fold(
      (f) => PrescriptionScanState(
          status: ScanStatus.failure, message: f.message),
      // Cancelled: go back to whatever was on screen.
      (found) => found == null
          ? before
          : PrescriptionScanState(status: ScanStatus.done, medicines: found),
    ));
  }
}
