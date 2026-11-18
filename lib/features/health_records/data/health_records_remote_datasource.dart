import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_guard.dart';
import '../domain/health_record.dart';

class HealthRecordsRemoteDataSource {
  final Dio dio;
  HealthRecordsRemoteDataSource(this.dio);

  Future<List<HealthRecord>> list() => dioGuard(() async {
        final res = await dio.get(ApiConstants.healthRecords);
        return (res.data as List)
            .map((j) => fromJson(j as Map<String, dynamic>))
            .toList();
      });

  Future<StorageUsage> usage() => dioGuard(() async {
        final res = await dio.get(ApiConstants.healthRecordsSummary);
        final j = res.data as Map<String, dynamic>;
        return StorageUsage(
          usedBytes: j['total_bytes'] as int,
          quotaBytes: j['quota_bytes'] as int,
          maxFileBytes: j['max_file_bytes'] as int,
        );
      });

  Future<HealthRecord> upload({
    required LocalFile file,
    required RecordFolder folder,
    required RecordCategory category,
    String? title,
    String? notes,
    DateTime? documentDate,
  }) =>
      dioGuard(() async {
        final form = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: file.name),
          'folder': folder.apiValue,
          'category': category.apiValue,
          if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
          if (documentDate != null)
            'document_date': formatApiDate(documentDate),
        });
        final res = await dio.post(
          ApiConstants.healthRecords,
          data: form,
          // Large files on a slow connection.
          options: Options(sendTimeout: const Duration(minutes: 3)),
        );
        return fromJson(res.data as Map<String, dynamic>);
      });

  Future<HealthRecord> update(
    String id, {
    required String title,
    required RecordCategory category,
    String? notes,
    DateTime? documentDate,
  }) =>
      dioGuard(() async {
        final res = await dio.patch(ApiConstants.healthRecord(id), data: {
          'title': title,
          'category': category.apiValue,
          'notes': notes,
          'document_date':
              documentDate == null ? null : formatApiDate(documentDate),
        });
        return fromJson(res.data as Map<String, dynamic>);
      });

  Future<void> delete(String id) =>
      dioGuard(() => dio.delete(ApiConstants.healthRecord(id)));

  Future<Uint8List> download(String id) => dioGuard(() async {
        final res = await dio.get<List<int>>(
          ApiConstants.healthRecordFile(id),
          options: Options(
            responseType: ResponseType.bytes,
            receiveTimeout: const Duration(minutes: 3),
          ),
        );
        return Uint8List.fromList(res.data ?? const []);
      });

  static HealthRecord fromJson(Map<String, dynamic> j) => HealthRecord(
        id: j['id'].toString(),
        folder: RecordFolder.fromApi(j['folder'] as String),
        category: RecordCategory.fromApi(j['category'] as String),
        title: j['title'] as String,
        notes: j['notes'] as String?,
        documentDate: parseDate(j['document_date']),
        fileName: j['file_name'] as String,
        contentType: j['content_type'] as String,
        sizeBytes: j['size_bytes'] as int,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
