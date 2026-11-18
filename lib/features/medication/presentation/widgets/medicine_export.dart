import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/info_widgets.dart';
import '../../domain/entities/medication.dart';
import '../../domain/medicine_guide.dart';
import '../utils/medication_format.dart';

/// Builds the "My medicines" PDF: every medicine with its dose, schedule,
/// stock, how to take it and its side effects.
///
/// The document is written in English whatever the app's language is. The
/// PDF library cannot join Devanagari letters correctly, and a medicine list
/// with broken words is worse than one a pharmacist or doctor can read.
class MedicineListPdf {
  MedicineListPdf._();

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// The built-in PDF fonts only have Latin letters; anything else (a name
  /// or note typed in Nepali) would stop the whole document from being made.
  static String _latin(String text) {
    final cleaned = text
        .replaceAll(RegExp('[\u2018\u2019]'), "'")
        .replaceAll(RegExp('[\u201C\u201D]'), '"')
        .replaceAll(RegExp('[\u2013\u2014]'), '-')
        .replaceAll('\u00B7', '-')
        // Date formats put special (narrow, non-breaking) spaces before AM/PM.
        .replaceAll(RegExp('[\u00A0\u2009\u202F]'), ' ')
        .replaceAll(RegExp(r'[^\x09\x0A\x20-\x7E\xA0-\xFF]+'), '?');
    return cleaned;
  }

  static String _label(String apiValue) =>
      MedicationFormat.englishLabel(apiValue);

  static String _time(String hhmm) {
    final t = MedicationFormat.parseTime(hhmm);
    if (t == null) return hhmm;
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  static String _schedule(MedicationSchedule? s) {
    if (s == null) return 'As needed';
    final days = s.daysOfWeek == null || s.daysOfWeek!.length == 7
        ? 'every day'
        : s.daysOfWeek!.where((d) => d >= 0 && d < 7).map((d) => _days[d]).join(', ');
    final date = DateFormat('d MMM yyyy', 'en');
    final range = [
      if (s.startDate != null) 'from ${date.format(s.startDate!)}',
      if (s.endDate != null) 'until ${date.format(s.endDate!)}',
    ].join(' ');
    return '${s.reminderTimes.map(_time).join(', ')} - $days'
        '${range.isEmpty ? '' : ' ($range)'}';
  }

  static Future<Uint8List> build(
    List<Medication> medications, {
    String? patientName,
    DateTime? now,
  }) async {
    final made = DateFormat('d MMM yyyy, h:mm a', 'en').format(now ?? DateTime.now());
    final active = medications.where((m) => !m.isStopped).toList();
    final stopped = medications.where((m) => m.isStopped).toList();
    const ink = PdfColor.fromInt(0xFF1E3A56);
    const muted = PdfColor.fromInt(0xFF5E7B8F);
    const brand = PdfColor.fromInt(0xFF3368A0);
    const line = PdfColor.fromInt(0xFFC8DFDB);

    pw.Widget row(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 92,
                child: pw.Text(label,
                    style: const pw.TextStyle(fontSize: 9.5, color: muted)),
              ),
              pw.Expanded(
                child: pw.Text(_latin(value),
                    style: const pw.TextStyle(fontSize: 10.5, color: ink)),
              ),
            ],
          ),
        );

    pw.Widget medicine(Medication m) {
      final guide = MedicineGuide.find(m.name);
      final timing = MedicineGuide.timingAdvice(m.intakeTiming);
      final inventory = m.inventory;
      final notes = m.instructions?.trim() ?? '';
      final how = [
        if (timing != null) timing.en,
        if (guide != null) guide.howToTake.en,
        MedicineGuide.formAdvice(m.medicineType).en,
      ].join(' ');
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: line, width: 1),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(_latin(m.name),
                style: pw.TextStyle(
                    fontSize: 13, fontWeight: pw.FontWeight.bold, color: ink)),
            row('Dose', '${m.dose} - ${_label(m.medicineType)}'
                ' - ${_label(m.intakeTiming)}'),
            row('When', m.isStopped ? 'Stopped' : _schedule(m.schedule)),
            if (inventory != null)
              row('In stock', MedicationFormat.amount(inventory.quantity)),
            if (notes.isNotEmpty) row('My instructions', notes),
            row('How to take', how),
            if (guide != null) row('Used for', guide.usedFor.en),
            row(
              'Side effects',
              guide == null
                  ? 'Ask your pharmacist or read the leaflet in the pack.'
                  : guide.sideEffects.map((e) => e.en).join('; '),
            ),
            if (guide != null) row('Get help if', guide.warning.en),
          ],
        ),
      );
    }

    pw.Widget heading(String text) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8, bottom: 6),
          child: pw.Text(text,
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold, color: muted)),
        );

    final doc = pw.Document(title: 'My medicines', creator: 'MediSathi');
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => context.pageNumber > 1
          ? pw.SizedBox()
          : pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('My medicines',
                    style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: brand)),
                pw.SizedBox(height: 2),
                pw.Text(
                  _latin([
                    if (patientName != null && patientName.trim().isNotEmpty)
                      patientName.trim(),
                    'Made with MediSathi on $made',
                  ].join(' - ')),
                  style: const pw.TextStyle(fontSize: 10, color: muted),
                ),
                pw.Divider(color: line),
              ],
            ),
      footer: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Divider(color: line),
          pw.Row(children: [
            pw.Expanded(
              child: pw.Text(MedicineGuide.disclaimer.en,
                  style: const pw.TextStyle(fontSize: 8, color: muted)),
            ),
            pw.SizedBox(width: 12),
            pw.Text('${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: muted)),
          ]),
        ],
      ),
      build: (context) => [
        if (active.isNotEmpty) heading('TAKING NOW (${active.length})'),
        ...active.map(medicine),
        if (stopped.isNotEmpty) heading('STOPPED (${stopped.length})'),
        ...stopped.map(medicine),
      ],
    ));
    return doc.save();
  }
}

/// Makes the PDF and lets the user pick where on the phone to keep it
/// (Downloads, Drive ...), so it can be read later or shown to a doctor.
Future<void> exportMedicines(
  BuildContext context,
  List<Medication> medications, {
  String? patientName,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  void say(String text, {bool error = false, SnackBarAction? action}) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: error ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: action == null ? 4 : 8),
        action: action,
      ));
  }

  try {
    final bytes = await MedicineListPdf.build(medications,
        patientName: patientName);
    final name = 'MediSathi-medicines-'
        '${DateFormat('yyyy-MM-dd', 'en').format(DateTime.now())}.pdf';

    // A copy the app can open straight away, whatever the user picks next.
    final temp = File('${(await getTemporaryDirectory()).path}/$name');
    await temp.writeAsBytes(bytes, flush: true);

    final saved = await FilePicker.saveFile(
      dialogTitle: 'Save my medicine list'.tr,
      fileName: name,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      bytes: bytes,
    );
    if (saved == null) return; // the user closed the picker
    say(
      'Medicine list saved to your phone'.tr,
      action: SnackBarAction(
        label: 'Open'.tr,
        textColor: Colors.white,
        onPressed: () => OpenFilex.open(temp.path),
      ),
    );
  } catch (_) {
    if (context.mounted) {
      showInfoSnack(context, 'Could not save the medicine list.'.tr,
          error: true);
    } else {
      say('Could not save the medicine list.'.tr, error: true);
    }
  }
}
