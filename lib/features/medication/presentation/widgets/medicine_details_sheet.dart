import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/camera_capture_page.dart';
import '../../../../core/widgets/info_widgets.dart';
import '../../../reminder/presentation/bloc/reminder_bloc.dart';
import '../../data/medicine_photo_service.dart';
import '../../domain/entities/medication.dart';
import '../../domain/medicine_guide.dart';
import '../bloc/medication_bloc.dart';
import '../utils/medication_format.dart';
import 'medicine_avatar.dart';

/// Everything about one medicine: its photo, how to take it and the side
/// effects to look out for. Needs the [MedicationBloc] and [ReminderBloc]
/// above [context].
Future<void> showMedicineDetails(BuildContext context, String medicationId) {
  final medications = context.read<MedicationBloc>();
  final reminders = context.read<ReminderBloc>();
  final router = GoRouter.of(context);
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: medications),
        BlocProvider.value(value: reminders),
      ],
      child: _MedicineDetails(
        medicationId: medicationId,
        onEdit: () => router.go(AppRoutes.editMedication(medicationId)),
      ),
    ),
  );
}

class _MedicineDetails extends StatefulWidget {
  final String medicationId;
  final VoidCallback onEdit;
  const _MedicineDetails({required this.medicationId, required this.onEdit});

  @override
  State<_MedicineDetails> createState() => _MedicineDetailsState();
}

class _MedicineDetailsState extends State<_MedicineDetails> {
  bool _savingPhoto = false;
  String? _photoError;

  /// The photo is on the medicine and on its doses, so both are reloaded.
  void _reload() {
    context.read<MedicationBloc>().add(const MedicationsRequested());
    context.read<ReminderBloc>().add(const TodayRequested());
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final service = sl<MedicinePhotoService>();
    String? path;
    try {
      if (source == ImageSource.camera) {
        path = await takePhoto(context);
      } else {
        // Small enough to upload on a slow connection and to fit a
        // notification, large enough to recognise the medicine.
        path = (await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1000,
          maxHeight: 1000,
          imageQuality: 80,
        ))
            ?.path;
      }
    } catch (_) {
      if (mounted) {
        setState(() => _photoError =
            'Could not open the camera or gallery. Check the app permissions.'
                .tr);
      }
      return;
    }
    if (path == null || !mounted) return;
    setState(() {
      _savingPhoto = true;
      _photoError = null;
    });
    final result = await service.upload(widget.medicationId, path);
    if (!mounted) return;
    setState(() {
      _savingPhoto = false;
      _photoError = result.fold((f) => f.message, (_) => null);
    });
    if (result.isRight()) _reload();
  }

  Future<void> _removePhoto() async {
    setState(() {
      _savingPhoto = true;
      _photoError = null;
    });
    final result =
        await sl<MedicinePhotoService>().remove(widget.medicationId);
    if (!mounted) return;
    setState(() {
      _savingPhoto = false;
      _photoError = result.fold((f) => f.message, (_) => null);
    });
    if (result.isRight()) _reload();
  }

  Future<void> _choosePhotoSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text('Take a photo'.tr),
            onTap: () => Navigator.pop(sheet, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text('Choose from gallery'.tr),
            onTap: () => Navigator.pop(sheet, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (source != null && mounted) await _pickPhoto(source);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MedicationBloc, MedicationState>(
      builder: (context, state) {
        final matches =
            state.medications.where((m) => m.id == widget.medicationId);
        if (matches.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'This medicine is no longer in your list.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, controller) =>
              _content(context, controller, matches.first),
        );
      },
    );
  }

  Widget _content(
      BuildContext context, ScrollController controller, Medication m) {
    final guide = MedicineGuide.find(m.name);
    final timing = MedicineGuide.timingAdvice(m.intakeTiming);
    final hasPhoto = m.photoUrl != null;
    final notes = m.instructions?.trim() ?? '';

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        // ---- what it looks like ----
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              MedicineAvatar(
                medicineType: m.medicineType,
                photoUrl: m.photoUrl,
                size: hasPhoto ? 200 : 96,
              ),
              if (_savingPhoto) const CircularProgressIndicator(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          m.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${m.dose} · ${MedicationFormat.label(m.medicineType).tr}'
          ' · ${MedicationFormat.label(m.intakeTiming).tr}',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          MedicationFormat.scheduleSummary(context, m.schedule),
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _savingPhoto ? null : _choosePhotoSource,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(hasPhoto ? 'Change photo'.tr : 'Add a photo'.tr),
            ),
            if (hasPhoto)
              TextButton(
                onPressed: _savingPhoto ? null : _removePhoto,
                child: Text('Remove photo'.tr),
              ),
          ],
        ),
        if (_photoError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _photoError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          )
        else if (!hasPhoto)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'A photo of the strip or bottle makes the medicine easy to '
                      'recognise. It is also shown in the reminder.'
                  .tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),

        // ---- how to take it ----
        SectionLabel('How to take it'.tr),
        InfoCard(padding: const EdgeInsets.all(14), children: [
          if (notes.isNotEmpty) ...[
            _Point(
              icon: Icons.assignment_ind_outlined,
              title: 'Your instructions'.tr,
              text: notes,
              strong: true,
            ),
            const SizedBox(height: 12),
          ],
          if (timing != null) ...[
            _Point(icon: Icons.restaurant_rounded, text: timing.text),
            const SizedBox(height: 12),
          ],
          if (guide != null) ...[
            _Point(icon: Icons.schedule_rounded, text: guide.howToTake.text),
            const SizedBox(height: 12),
          ],
          _Point(
            icon: MedicationFormat.typeIcon(m.medicineType),
            text: MedicineGuide.formAdvice(m.medicineType).text,
          ),
        ]),

        if (guide != null) ...[
          SectionLabel('What it is for'.tr),
          InfoCard(padding: const EdgeInsets.all(14), children: [
            _Point(
                icon: Icons.healing_outlined, text: guide.usedFor.text),
          ]),
        ],

        // ---- side effects ----
        SectionLabel('Possible side effects'.tr),
        InfoCard(padding: const EdgeInsets.all(14), children: [
          if (guide == null)
            _Point(
              icon: Icons.help_outline_rounded,
              text: MedicineGuide.unknownSideEffects.text,
            )
          else
            for (final (i, effect) in guide.sideEffects.indexed) ...[
              if (i > 0) const SizedBox(height: 8),
              _Point(icon: Icons.circle, small: true, text: effect.text),
            ],
        ]),

        SectionLabel('Get help if'.tr),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error, width: 1.2),
          ),
          child: _Point(
            icon: Icons.warning_amber_rounded,
            color: AppColors.error,
            text: (guide?.warning ?? MedicineGuide.generalWarning).text,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          MedicineGuide.disclaimer.text,
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onEdit();
          },
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50)),
          icon: const Icon(Icons.edit_outlined),
          label: Text('Edit medicine'.tr),
        ),
      ],
    );
  }
}

/// An icon with a line or two of advice beside it.
class _Point extends StatelessWidget {
  final IconData icon;
  final String? title;
  final String text;
  final Color? color;

  /// A bullet dot instead of a full-size icon.
  final bool small;

  /// The user's own words stand out from the general advice.
  final bool strong;

  const _Point({
    required this.icon,
    this.title,
    required this.text,
    this.color,
    this.small = false,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Padding(
            padding: EdgeInsets.only(top: small ? 7 : 1),
            child: Icon(icon,
                size: small ? 7 : 20, color: color ?? AppColors.primary),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(title!,
                    style: TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary)),
              Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
