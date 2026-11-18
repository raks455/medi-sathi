import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/info_widgets.dart';
import '../../domain/health_record.dart';

enum _Source { camera, gallery, file }

/// Asks where the file comes from and lets the user pick it.
/// Returns null if they cancel.
Future<LocalFile?> pickRecordFile(BuildContext context) async {
  final source = await showModalBottomSheet<_Source>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: InfoCard(children: [
          InfoTile(
            icon: Icons.photo_camera_outlined,
            title: 'Take a photo',
            onTap: () => Navigator.pop(sheet, _Source.camera),
          ),
          const InfoDivider(),
          InfoTile(
            icon: Icons.photo_library_outlined,
            title: 'Choose from gallery',
            onTap: () => Navigator.pop(sheet, _Source.gallery),
          ),
          const InfoDivider(),
          InfoTile(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Choose a PDF or file',
            subtitle: 'PDF, JPG, PNG, WEBP or HEIC',
            onTap: () => Navigator.pop(sheet, _Source.file),
          ),
        ]),
      ),
    ),
  );
  if (source == null) return null;

  try {
    if (source == _Source.file) {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'heic'],
      );
      final file = result?.files.single;
      if (file == null || file.path == null) return null;
      return LocalFile(path: file.path!, name: file.name);
    }
    final image = await ImagePicker().pickImage(
      source: source == _Source.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 85,
    );
    if (image == null) return null;
    return LocalFile(path: image.path, name: image.name);
  } catch (_) {
    if (context.mounted) {
      showInfoSnack(context,
          'Could not open the picker. Check camera and storage permissions.',
          error: true);
    }
    return null;
  }
}

class RecordDetails {
  final String title;
  final RecordCategory category;
  final DateTime? documentDate;
  final String? notes;

  const RecordDetails({
    required this.title,
    required this.category,
    this.documentDate,
    this.notes,
  });
}

/// Title, type, date and notes for a new or existing record.
Future<RecordDetails?> showRecordDetailsSheet(
  BuildContext context, {
  required RecordFolder folder,
  HealthRecord? existing,
  String? suggestedTitle,
  String actionLabel = 'Save',
}) {
  return showModalBottomSheet<RecordDetails>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RecordDetailsForm(
      folder: folder,
      existing: existing,
      suggestedTitle: suggestedTitle,
      actionLabel: actionLabel,
    ),
  );
}

class _RecordDetailsForm extends StatefulWidget {
  final RecordFolder folder;
  final HealthRecord? existing;
  final String? suggestedTitle;
  final String actionLabel;

  const _RecordDetailsForm({
    required this.folder,
    this.existing,
    this.suggestedTitle,
    required this.actionLabel,
  });

  @override
  State<_RecordDetailsForm> createState() => _RecordDetailsFormState();
}

class _RecordDetailsFormState extends State<_RecordDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(
      text: widget.existing?.title ?? widget.suggestedTitle ?? '');
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  late RecordCategory _category = widget.existing?.category ??
      (widget.folder == RecordFolder.prescriptions
          ? RecordCategory.prescription
          : RecordCategory.labReport);
  late DateTime? _date = widget.existing?.documentDate;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      RecordDetails(
        title: _title.text.trim(),
        category: _category,
        documentDate: _date,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPrescription = widget.folder == RecordFolder.prescriptions;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null
                    ? (isPrescription ? 'Save prescription' : 'Save document')
                    : 'Edit details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                maxLength: 150,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: isPrescription
                      ? 'e.g. Dr. Sharma - fever'
                      : 'e.g. Blood test (CBC)',
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter a title' : null,
              ),
              if (!isPrescription) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in RecordCategory.documentTypes)
                      ChoiceChip(
                        label: Text(c.label),
                        selected: _category == c,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _category = c),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: _pickDate,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                icon: const Icon(Icons.event_outlined),
                label: Text(_date == null
                    ? 'Date on the document (optional)'
                    : DateFormat.yMMMd().format(_date!)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _submit,
                child: Text(widget.actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
