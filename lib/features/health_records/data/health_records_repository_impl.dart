import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/error/failures.dart';
import '../../../core/network/repository_guard.dart';
import '../domain/health_record.dart';
import '../domain/health_records_repository.dart';
import 'health_records_remote_datasource.dart';

class HealthRecordsRepositoryImpl implements HealthRecordsRepository {
  final HealthRecordsRemoteDataSource remote;

  /// Where downloaded files are cached (the temp folder by default, which
  /// the system may clear).
  final Future<Directory> Function() cacheDir;

  HealthRecordsRepositoryImpl(this.remote,
      {Future<Directory> Function()? cacheDir})
      : cacheDir = cacheDir ?? getTemporaryDirectory;

  @override
  Future<Either<Failure, List<HealthRecord>>> getRecords() =>
      guardApiCall(remote.list);

  @override
  Future<Either<Failure, StorageUsage>> getUsage() =>
      guardApiCall(remote.usage);

  @override
  Future<Either<Failure, HealthRecord>> upload({
    required LocalFile file,
    required RecordFolder folder,
    required RecordCategory category,
    String? title,
    String? notes,
    DateTime? documentDate,
  }) =>
      guardApiCall(() => remote.upload(
            file: file,
            folder: folder,
            category: category,
            title: title,
            notes: notes,
            documentDate: documentDate,
          ));

  @override
  Future<Either<Failure, HealthRecord>> update(
    String id, {
    required String title,
    required RecordCategory category,
    String? notes,
    DateTime? documentDate,
  }) =>
      guardApiCall(() => remote.update(id,
          title: title,
          category: category,
          notes: notes,
          documentDate: documentDate));

  @override
  Future<Either<Failure, Unit>> delete(String id) async {
    final result = await guardApiCall(() => remote.delete(id));
    if (result.isRight()) {
      try {
        final dir = await _recordDir(id);
        if (await dir.exists()) await dir.delete(recursive: true);
      } catch (_) {}
    }
    return result.map((_) => unit);
  }

  @override
  Future<Either<Failure, String>> fileOnDevice(HealthRecord record) async {
    try {
      final cached = await _cachedFile(record.id);
      if (cached != null) return Right(cached.path);
    } catch (_) {}
    return guardApiCall(() async {
      final bytes = await remote.download(record.id);
      final dir = await _recordDir(record.id);
      await dir.create(recursive: true);
      final safeName =
          record.fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File('${dir.path}${Platform.pathSeparator}$safeName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    });
  }

  Future<Directory> _recordDir(String id) async {
    final base = await cacheDir();
    final sep = Platform.pathSeparator;
    return Directory('${base.path}${sep}health_records$sep$id');
  }

  Future<File?> _cachedFile(String id) async {
    final dir = await _recordDir(id);
    if (!await dir.exists()) return null;
    final files = await dir.list().where((e) => e is File).toList();
    return files.isEmpty ? null : files.first as File;
  }
}
