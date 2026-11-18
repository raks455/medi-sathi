import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/health_record.dart';
import '../../domain/health_records_repository.dart';

enum RecordsStatus { loading, loaded, failure }

class HealthRecordsState extends Equatable {
  final RecordsStatus status;
  final List<HealthRecord> records;
  final StorageUsage? usage;
  final String? message;

  /// True while a file is being uploaded.
  final bool uploading;

  const HealthRecordsState({
    this.status = RecordsStatus.loading,
    this.records = const [],
    this.usage,
    this.message,
    this.uploading = false,
  });

  List<HealthRecord> inFolder(RecordFolder folder) =>
      records.where((r) => r.folder == folder).toList();

  HealthRecordsState copyWith({
    RecordsStatus? status,
    List<HealthRecord>? records,
    StorageUsage? usage,
    String? message,
    bool? uploading,
  }) =>
      HealthRecordsState(
        status: status ?? this.status,
        records: records ?? this.records,
        usage: usage ?? this.usage,
        message: message,
        uploading: uploading ?? this.uploading,
      );

  @override
  List<Object?> get props => [status, records, usage, message, uploading];
}

class HealthRecordsCubit extends Cubit<HealthRecordsState> {
  final HealthRecordsRepository repository;
  HealthRecordsCubit(this.repository) : super(const HealthRecordsState());

  static int _byDate(HealthRecord a, HealthRecord b) {
    final c = b.displayDate.compareTo(a.displayDate);
    return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
  }

  Future<void> load() async {
    if (state.records.isEmpty) {
      emit(state.copyWith(status: RecordsStatus.loading));
    }
    final records = await repository.getRecords();
    final usage = await repository.getUsage();
    records.fold(
      (f) => emit(state.copyWith(status: RecordsStatus.failure, message: f.message)),
      (list) => emit(state.copyWith(
        status: RecordsStatus.loaded,
        records: [...list]..sort(_byDate),
        usage: usage.fold((_) => state.usage, (u) => u),
      )),
    );
  }

  Future<void> _refreshUsage() async {
    final usage = await repository.getUsage();
    usage.fold((_) {}, (u) => emit(state.copyWith(usage: u)));
  }

  /// Returns an error message, or null on success.
  Future<String?> upload({
    required LocalFile file,
    required RecordFolder folder,
    required RecordCategory category,
    String? title,
    String? notes,
    DateTime? documentDate,
  }) async {
    emit(state.copyWith(uploading: true));
    final result = await repository.upload(
      file: file,
      folder: folder,
      category: category,
      title: title,
      notes: notes,
      documentDate: documentDate,
    );
    return result.fold(
      (f) {
        emit(state.copyWith(uploading: false));
        return f.message;
      },
      (record) {
        emit(state.copyWith(
          uploading: false,
          status: RecordsStatus.loaded,
          records: [record, ...state.records]..sort(_byDate),
        ));
        _refreshUsage();
        return null;
      },
    );
  }

  Future<String?> updateDetails(
    HealthRecord record, {
    required String title,
    required RecordCategory category,
    String? notes,
    DateTime? documentDate,
  }) async {
    final result = await repository.update(record.id,
        title: title,
        category: category,
        notes: notes,
        documentDate: documentDate);
    return result.fold((f) => f.message, (updated) {
      emit(state.copyWith(
        records: [
          for (final r in state.records) r.id == updated.id ? updated : r
        ]..sort(_byDate),
      ));
      return null;
    });
  }

  Future<String?> delete(HealthRecord record) async {
    final result = await repository.delete(record.id);
    return result.fold((f) => f.message, (_) {
      emit(state.copyWith(
          records: state.records.where((r) => r.id != record.id).toList()));
      _refreshUsage();
      return null;
    });
  }
}
