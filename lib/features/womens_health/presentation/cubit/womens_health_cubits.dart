import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/womens_health.dart';

class CycleState extends Equatable {
  final bool loading;
  final String? error;
  final CycleOverview overview;

  /// Null until loaded (or when the server does not have it).
  final CycleSettings? settings;

  const CycleState({
    this.loading = true,
    this.error,
    this.overview = const CycleOverview(),
    this.settings,
  });

  @override
  List<Object?> get props => [loading, error, overview, settings];
}

class CycleCubit extends Cubit<CycleState> {
  final WomensHealthRepository repository;
  CycleCubit(this.repository) : super(const CycleState());

  Future<void> load() async {
    final result = await repository.getCycleOverview();
    final settings = await repository.getSettings();
    final s = settings.fold((_) => state.settings, (s) => s);
    result.fold(
      (f) => emit(CycleState(
          loading: false,
          error: f.message,
          overview: state.overview,
          settings: s)),
      (o) => emit(CycleState(loading: false, overview: o, settings: s)),
    );
  }

  Future<String?> updateSettings(CycleSettings settings) async {
    final previous = state.settings;
    emit(CycleState(
        loading: false, overview: state.overview, settings: settings));
    final result = await repository.saveSettings(settings);
    return result.fold((f) {
      emit(CycleState(
          loading: false, overview: state.overview, settings: previous));
      return f.message;
    }, (_) => null);
  }

  /// Returns an error message, or null on success.
  Future<String?> save({
    String? id,
    required DateTime start,
    DateTime? end,
    PeriodFlow? flow,
    String? notes,
  }) async {
    final result = await repository.savePeriod(
        id: id, start: start, end: end, flow: flow, notes: notes);
    return result.fold((f) => f.message, (_) {
      load();
      return null;
    });
  }

  Future<String?> delete(Period period) async {
    final result = await repository.deletePeriod(period.id);
    return result.fold((f) => f.message, (_) {
      load();
      return null;
    });
  }
}

class PregnancyState extends Equatable {
  final bool loading;
  final String? error;
  final Pregnancy? pregnancy;

  const PregnancyState({this.loading = true, this.error, this.pregnancy});

  @override
  List<Object?> get props => [loading, error, pregnancy];
}

class PregnancyCubit extends Cubit<PregnancyState> {
  final WomensHealthRepository repository;
  PregnancyCubit(this.repository) : super(const PregnancyState());

  Future<void> load() async {
    final result = await repository.getPregnancy();
    result.fold(
      (f) => emit(PregnancyState(
          loading: false, error: f.message, pregnancy: state.pregnancy)),
      (p) => emit(PregnancyState(loading: false, pregnancy: p)),
    );
  }

  Future<String?> save(
      {DateTime? lastPeriodDate, DateTime? dueDate, String? notes}) async {
    final result = await repository.savePregnancy(
        lastPeriodDate: lastPeriodDate, dueDate: dueDate, notes: notes);
    return result.fold((f) => f.message, (p) {
      emit(PregnancyState(loading: false, pregnancy: p));
      return null;
    });
  }

  Future<String?> stop() async {
    final result = await repository.deletePregnancy();
    return result.fold((f) => f.message, (_) {
      emit(const PregnancyState(loading: false));
      return null;
    });
  }
}
