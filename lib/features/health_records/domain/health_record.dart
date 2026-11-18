import 'package:equatable/equatable.dart';

/// The two drives under Health Records. [apiValue] is the backend's name.
enum RecordFolder {
  prescriptions('prescriptions'),
  healthRecords('health_records');

  final String apiValue;
  const RecordFolder(this.apiValue);

  static RecordFolder fromApi(String v) =>
      values.firstWhere((f) => f.apiValue == v, orElse: () => healthRecords);
}

/// Document kinds. Prescriptions use only [prescription].
enum RecordCategory {
  prescription('prescription', 'Prescription'),
  labReport('lab_report', 'Lab report'),
  imaging('imaging', 'X-ray / scan'),
  dischargeSummary('discharge_summary', 'Discharge summary'),
  vaccination('vaccination', 'Vaccination'),
  insurance('insurance', 'Insurance'),
  other('other', 'Other');

  final String apiValue;
  final String label;
  const RecordCategory(this.apiValue, this.label);

  static RecordCategory fromApi(String v) =>
      values.firstWhere((c) => c.apiValue == v, orElse: () => other);

  /// Choices for the Health records folder.
  static const documentTypes = [
    labReport,
    imaging,
    dischargeSummary,
    vaccination,
    insurance,
    other,
  ];
}

class HealthRecord extends Equatable {
  final String id;
  final RecordFolder folder;
  final RecordCategory category;
  final String title;
  final String? notes;
  final DateTime? documentDate;
  final String fileName;
  final String contentType;
  final int sizeBytes;
  final DateTime createdAt;

  const HealthRecord({
    required this.id,
    required this.folder,
    required this.category,
    required this.title,
    this.notes,
    this.documentDate,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    required this.createdAt,
  });

  bool get isPdf => contentType == 'application/pdf';
  bool get isImage => contentType.startsWith('image/');

  /// The date shown and sorted by: the date on the document, else upload.
  DateTime get displayDate => documentDate ?? createdAt.toLocal();

  @override
  List<Object?> get props => [
        id, folder, category, title, notes, documentDate, fileName,
        contentType, sizeBytes, createdAt,
      ];
}

class StorageUsage extends Equatable {
  final int usedBytes;
  final int quotaBytes;
  final int maxFileBytes;

  const StorageUsage({
    required this.usedBytes,
    required this.quotaBytes,
    required this.maxFileBytes,
  });

  double get fraction => quotaBytes == 0 ? 0 : usedBytes / quotaBytes;

  @override
  List<Object?> get props => [usedBytes, quotaBytes, maxFileBytes];
}

/// A file chosen on the phone, ready to upload.
class LocalFile {
  final String path;
  final String name;
  const LocalFile({required this.path, required this.name});
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
