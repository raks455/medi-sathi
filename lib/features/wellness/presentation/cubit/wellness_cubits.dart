import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/wellness_repository_impl.dart' show VitalUnitsStore;
import '../../domain/wellness.dart';

// ---- vitals -----------------------------------------------------------------

class VitalsState extends Equatable {
  /// True only until the first load finishes; later refreshes keep the
  /// readings on screen.
  final bool loading;
  final String? error;
  final VitalsSummary summary;
  final VitalType selected;

  /// Readings of each type loaded so far, newest first.
  final Map<VitalType, List<VitalReading>> readings;

  final WeightUnit weightUnit;
  final HeightUnit heightUnit;

  const VitalsState({
    this.loading = true,
    this.error,
    this.summary = const VitalsSummary(),
    this.selected = VitalType.weight,
    this.readings = const {},
    this.weightUnit = WeightUnit.kg,
    this.heightUnit = HeightUnit.cm,
  });

  List<VitalReading> get current => readings[selected] ?? const [];

  String format(VitalReading reading) =>
      reading.format(weightUnit, heightUnit);

  /// [error] is replaced, not kept: leave it out to clear it.
  VitalsState copyWith({
    bool? loading,
    String? error,
    VitalsSummary? summary,
    VitalType? selected,
    Map<VitalType, List<VitalReading>>? readings,
    WeightUnit? weightUnit,
    HeightUnit? heightUnit,
  }) =>
      VitalsState(
        loading: loading ?? this.loading,
        error: error,
        summary: summary ?? this.summary,
        selected: selected ?? this.selected,
        readings: readings ?? this.readings,
        weightUnit: weightUnit ?? this.weightUnit,
        heightUnit: heightUnit ?? this.heightUnit,
      );

  @override
  List<Object?> get props => [
        loading,
        error,
        summary,
        selected,
        readings,
        weightUnit,
        heightUnit,
      ];
}

/// The readings saved by [VitalsCubit.addAll] and why it stopped, if it did.
typedef VitalsSaveResult = ({Set<VitalType> saved, String? error});

class VitalsCubit extends Cubit<VitalsState> {
  final WellnessRepository repository;
  final VitalUnitsStore units;

  VitalsCubit(this.repository, this.units)
      : super(VitalsState(
          weightUnit: units.weight,
          heightUnit: units.height,
        ));

  /// Counts loads so that only the newest one may change the state: an older
  /// answer arriving late would bring back readings that were since edited.
  int _loadId = 0;

  /// [silent] refreshes behind the screen: no spinner, and a failure keeps
  /// what is shown.
  Future<void> load({bool silent = false}) async {
    final id = ++_loadId;
    if (!silent) emit(state.copyWith(loading: state.readings.isEmpty));

    final summaryCall = repository.getVitalsSummary();
    final lists = await Future.wait(
        VitalType.values.map((t) => repository.getVitals(t, days: 365)));
    final summary = await summaryCall;
    if (isClosed || id != _loadId) return;

    final readings = {...state.readings};
    String? error;
    for (final (i, result) in lists.indexed) {
      result.fold((f) => error = f.message,
          (list) => readings[VitalType.values[i]] = list);
    }
    final newSummary = summary.fold((f) {
      error = f.message;
      return state.summary;
    }, (s) => s);
    emit(state.copyWith(
      loading: false,
      error: silent ? state.error : error,
      summary: newSummary,
      readings: readings,
    ));
  }

  void select(VitalType type) =>
      emit(state.copyWith(selected: type, error: state.error));

  void setWeightUnit(WeightUnit unit) {
    units.setWeight(unit);
    emit(state.copyWith(weightUnit: unit, error: state.error));
  }

  void setHeightUnit(HeightUnit unit) {
    units.setHeight(unit);
    emit(state.copyWith(heightUnit: unit, error: state.error));
  }

  /// Saves the readings one after another and shows each as soon as it is
  /// saved. Stops at the first failure; the ones in `saved` are stored.
  Future<VitalsSaveResult> addAll(List<VitalInput> inputs) async {
    final saved = <VitalType>{};
    String? error;
    for (final input in inputs) {
      final result = await repository.addVital(input);
      if (isClosed) return (saved: saved, error: null);
      final reading = result.fold<VitalReading?>((f) {
        error = f.message;
        return null;
      }, (r) => r);
      if (reading == null) break;
      saved.add(input.type);
      _change(input.type, (list) => list..add(reading));
    }
    if (saved.isNotEmpty) {
      // Show what was just added, unless the open tab is one of them.
      if (!saved.contains(state.selected)) {
        emit(state.copyWith(selected: saved.first));
      }
      load(silent: true);
    }
    return (saved: saved, error: error);
  }

  /// Returns an error message, or null on success.
  Future<String?> update(VitalReading reading, VitalInput input) async {
    final result = await repository.updateVital(reading.id, input);
    if (isClosed) return null;
    return result.fold((f) => f.message, (updated) {
      _change(reading.type, (list) {
        final i = list.indexWhere((r) => r.id == reading.id);
        i < 0 ? list.add(updated) : list[i] = updated;
        return list;
      });
      load(silent: true);
      return null;
    });
  }

  Future<String?> delete(VitalReading reading) async {
    final result = await repository.deleteVital(reading.id);
    if (isClosed) return null;
    return result.fold((f) => f.message, (_) {
      _change(reading.type,
          (list) => list..removeWhere((r) => r.id == reading.id));
      load(silent: true);
      return null;
    });
  }

  /// Applies a change to the readings of [type] right away, keeping them
  /// newest first and the summary cards in step.
  void _change(
    VitalType type,
    List<VitalReading> Function(List<VitalReading>) change,
  ) {
    // Any load still in flight was asked before this change.
    _loadId++;
    final list = change([...state.readings[type] ?? const <VitalReading>[]])
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    emit(state.copyWith(
      loading: false,
      readings: {...state.readings, type: list},
      summary:
          state.summary.withLatest(type, list.isEmpty ? null : list.first),
    ));
  }
}

// ---- mood -------------------------------------------------------------------

class MoodState extends Equatable {
  final bool loading;
  final bool saving;
  final String? error;

  /// The last 7 days, newest first.
  final List<MoodEntry> entries;

  const MoodState({
    this.loading = true,
    this.saving = false,
    this.error,
    this.entries = const [],
  });

  MoodEntry? get today {
    final latest = entries.isEmpty ? null : entries.first;
    return latest != null && latest.isToday ? latest : null;
  }

  MoodState copyWith({
    bool? loading,
    bool? saving,
    String? error,
    List<MoodEntry>? entries,
  }) =>
      MoodState(
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        error: error,
        entries: entries ?? this.entries,
      );

  @override
  List<Object?> get props => [loading, saving, error, entries];
}

class MoodCubit extends Cubit<MoodState> {
  final WellnessRepository repository;
  MoodCubit(this.repository) : super(const MoodState());

  Future<void> load() async {
    final result = await repository.getMoods(days: 7);
    if (isClosed) return;
    result.fold(
      (f) => emit(state.copyWith(loading: false, error: f.message)),
      (list) => emit(state.copyWith(loading: false, entries: list)),
    );
  }

  Future<String?> checkIn(Mood mood,
      {String? note, List<String> tags = const []}) async {
    emit(state.copyWith(saving: true));
    final result = await repository.addMood(mood, note: note, tags: tags);
    if (isClosed) return null;
    return result.fold(
      (f) {
        emit(state.copyWith(saving: false));
        return f.message;
      },
      (entry) {
        emit(state.copyWith(saving: false, entries: [entry, ...state.entries]));
        return null;
      },
    );
  }
}
