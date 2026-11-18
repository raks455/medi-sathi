import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/info_widgets.dart';
import '../../../health_records/domain/health_record.dart';
import '../../../health_records/domain/health_records_repository.dart';
import '../../../health_records/presentation/widgets/record_sheets.dart';
import '../../domain/entities/scanned_medicine.dart';
import '../bloc/prescription_scan_bloc.dart';
import '../utils/medication_format.dart';
import 'medication_form_page.dart';

/// Scan a prescription or medicine label, then review each medicine found
/// in the normal add-medicine form before it is saved.
class ScanMedicinePage extends StatefulWidget {
  /// Used to keep the scanned photo in Health Records > Prescriptions.
  final HealthRecordsRepository? records;
  const ScanMedicinePage({super.key, this.records});

  @override
  State<ScanMedicinePage> createState() => _ScanMedicinePageState();
}

class _ScanMedicinePageState extends State<ScanMedicinePage> {
  /// Scanned medicines the user has already saved.
  final _added = <ScannedMedicine>{};

  /// Photo paths already saved to Health Records.
  final _savedPhotos = <String>{};
  bool _savingPhoto = false;

  void _scan(ScanSource source) {
    setState(_added.clear);
    context.read<PrescriptionScanBloc>().add(ScanRequested(source));
  }

  Future<void> _review(ScannedMedicine medicine) async {
    // Pushed on this page's navigator, so the form still finds the
    // MedicationBloc provided above it.
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => MedicationFormPage(prefill: medicine),
    ));
    if (saved == true && mounted) setState(() => _added.add(medicine));
  }

  Future<void> _savePhoto(String path) async {
    final repo = widget.records;
    if (repo == null) return;
    final details = await showRecordDetailsSheet(
      context,
      folder: RecordFolder.prescriptions,
      suggestedTitle: 'Prescription {date}'
          .trArgs({'date': DateFormat.yMMMd().format(DateTime.now())}),
    );
    if (details == null || !mounted) return;
    setState(() => _savingPhoto = true);
    final name = path.split(RegExp(r'[\\/]')).last;
    final result = await repo.upload(
      file: LocalFile(path: path, name: name),
      folder: RecordFolder.prescriptions,
      category: RecordCategory.prescription,
      title: details.title,
      notes: details.notes,
      documentDate: details.documentDate,
    );
    if (!mounted) return;
    setState(() => _savingPhoto = false);
    result.fold(
      (f) => showInfoSnack(context, f.message, error: true),
      (_) => setState(() => _savedPhotos.add(path)),
    );
  }

  /// Offer to keep the scanned prescription photo in Health Records.
  Widget _savePhotoCard(String? path) {
    if (path == null || widget.records == null) return const SizedBox.shrink();
    final saved = _savedPhotos.contains(path);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: InfoCard(children: [
        InfoTile(
          icon: saved ? Icons.check_circle_rounded : Icons.folder_shared_outlined,
          color: saved ? AppColors.success : null,
          title: saved
              ? 'Saved to Health Records'.tr
              : 'Save to Health Records'.tr,
          subtitle: saved
              ? 'Find it under Profile > Health Records'.tr
              : 'Keep this prescription photo in your Prescriptions folder'.tr,
          trailing: _savingPhoto
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5))
              : null,
          onTap: _savingPhoto
              ? null
              : saved
                  ? () => context.push(AppRoutes.healthRecords)
                  : () => _savePhoto(path),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan medicine'.tr,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: BlocBuilder<PrescriptionScanBloc, PrescriptionScanState>(
          builder: (context, state) {
            switch (state.status) {
              case ScanStatus.scanning:
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Reading the picture...'.tr,
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              case ScanStatus.done:
                if (state.medicines.isNotEmpty) return _buildResults(state);
                return _buildStart(
                  notice: 'No medicines were found in that picture. '
                          'Try a sharper, well-lit photo, or add it manually.'
                      .tr,
                  photoPath: state.imagePath,
                );
              case ScanStatus.failure:
                return _buildStart(notice: state.message, isError: true);
              case ScanStatus.idle:
                return _buildStart();
            }
          },
        ),
      ),
    );
  }

  Widget _buildStart(
      {String? notice, bool isError = false, String? photoPath}) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        Center(
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: AppColors.tertiaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.document_scanner_outlined,
                size: 48, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Scan a prescription or label'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Take a clear photo of printed text. MediSathi reads the medicine '
                  'names and doses on your phone, and you check each one before it '
                  'is saved.'
              .tr,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        if (notice != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isError ? AppColors.error : AppColors.tertiary,
                width: 1.2,
              ),
            ),
            child: Text(
              notice,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isError ? AppColors.error : AppColors.textPrimary,
              ),
            ),
          ),
          _savePhotoCard(photoPath),
        ],
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: () => _scan(ScanSource.camera),
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text('Take a photo'.tr),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _scan(ScanSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: Text('Choose from gallery'.tr),
        ),
        const SizedBox(height: 20),
        Text(
          'Works best with printed text. Handwriting is often misread.'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildResults(PrescriptionScanState state) {
    final medicines = state.medicines;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          medicines.length == 1
              ? 'Found 1 medicine'.tr
              : 'Found {n} medicines'.trArgs({'n': medicines.length}),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Scans can be wrong. Open each one, compare it with your '
                  'prescription, then save it.'
              .tr,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        _savePhotoCard(state.imagePath),
        const SizedBox(height: 16),
        for (final m in medicines)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ScannedCard(
              medicine: m,
              added: _added.contains(m),
              onReview: () => _review(m),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _scan(ScanSource.camera),
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text('Scan another'.tr),
        ),
        TextButton(
          onPressed: () => _scan(ScanSource.gallery),
          child: Text('Choose from gallery'.tr),
        ),
      ],
    );
  }
}

class _ScannedCard extends StatelessWidget {
  final ScannedMedicine medicine;
  final bool added;
  final VoidCallback onReview;

  const _ScannedCard({
    required this.medicine,
    required this.added,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final m = medicine;
    final details = [
      if (m.dose != null) m.dose!,
      if (m.medicineType != null) MedicationFormat.label(m.medicineType!),
      if (m.intakeTiming != null) MedicationFormat.label(m.intakeTiming!),
      if (m.asNeeded)
        'As needed'.tr
      else if (m.reminderTimes.isNotEmpty)
        m.reminderTimes
            .map((t) => MedicationFormat.displayTime(context, t))
            .join(', '),
      if (m.durationDays != null)
        '{n} days'.trArgs({'n': m.durationDays}),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tertiary, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  MedicationFormat.typeIcon(m.medicineType ?? ''),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(details.join(' · '),
                          style:
                              TextStyle(color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // The text it was read from, so mistakes are easy to spot.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.scaffold,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              m.sourceText,
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: added
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 18, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text('Added'.tr,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.success)),
                      ],
                    ),
                  )
                : TextButton(
                    onPressed: onReview,
                    child: Text('Review & add'.tr),
                  ),
          ),
        ],
      ),
    );
  }
}
