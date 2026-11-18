import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/data/datasources/auth_token_storage.dart';

/// 'yyyy-MM-dd' of a local day: the key a day's water is stored under.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}'
    '-${d.day.toString().padLeft(2, '0')}';

/// Keeps the water and fasting trackers on the phone, separately for each
/// account that signs in on it. Nothing here is sent to the server.
class HabitStore {
  final SharedPreferences prefs;
  final AuthTokenStorage session;
  HabitStore(this.prefs, this.session);

  Future<String> _key(String name) async =>
      '${name}_${(await session.readSession())?.userId ?? 'guest'}';

  Future<Map<String, dynamic>> read(String name) async {
    final raw = prefs.getString(await _key(name));
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> write(String name, Map<String, dynamic> data) async =>
      prefs.setString(await _key(name), jsonEncode(data));
}

// ---- water ------------------------------------------------------------------

class WaterState extends Equatable {
  static const goals = [1500, 2000, 2500, 3000];
  static const glasses = [150, 200, 250, 300];

  final bool loaded;

  /// Millilitres to drink in a day.
  final int goalMl;

  /// Millilitres in the user's usual glass.
  final int glassMl;

  /// Millilitres drunk on each day ('yyyy-MM-dd').
  final Map<String, int> days;

  /// What was added today, newest last, so the last one can be undone.
  final List<int> todayAdds;

  const WaterState({
    this.loaded = false,
    this.goalMl = 2000,
    this.glassMl = 250,
    this.days = const {},
    this.todayAdds = const [],
  });

  int on(DateTime day) => days[dayKey(day)] ?? 0;
  int get todayMl => on(DateTime.now());

  /// 0..1 of today's goal.
  double get progress => goalMl <= 0 ? 0 : (todayMl / goalMl).clamp(0, 1);
  bool get goalReached => todayMl >= goalMl;

  /// Glasses still to drink today (rounded up).
  int get glassesLeft =>
      goalReached ? 0 : ((goalMl - todayMl) / glassMl).ceil();

  @override
  List<Object?> get props => [loaded, goalMl, glassMl, days, todayAdds];
}

class WaterCubit extends Cubit<WaterState> {
  static const _name = 'water';
  static const _keepDays = 60;
  final HabitStore store;
  WaterCubit(this.store) : super(const WaterState());

  Future<void> load() async {
    final json = await store.read(_name);
    if (isClosed) return;
    final today = dayKey(DateTime.now());
    emit(WaterState(
      loaded: true,
      goalMl: json['goal_ml'] as int? ?? 2000,
      glassMl: json['glass_ml'] as int? ?? 250,
      days: {
        for (final e in (json['days'] as Map? ?? const {}).entries)
          e.key as String: e.value as int,
      },
      // The undo list only makes sense for the day it was made on.
      todayAdds: json['adds_day'] == today
          ? [for (final v in json['adds'] as List? ?? const []) v as int]
          : const [],
    ));
  }

  Future<void> _save(WaterState next) async {
    emit(next);
    final keys = next.days.keys.toList()..sort();
    final kept = keys.length > _keepDays
        ? keys.sublist(keys.length - _keepDays)
        : keys;
    await store.write(_name, {
      'goal_ml': next.goalMl,
      'glass_ml': next.glassMl,
      'days': {for (final k in kept) k: next.days[k]},
      'adds_day': dayKey(DateTime.now()),
      'adds': next.todayAdds,
    });
  }

  WaterState _with({
    int? goalMl,
    int? glassMl,
    Map<String, int>? days,
    List<int>? todayAdds,
  }) =>
      WaterState(
        loaded: true,
        goalMl: goalMl ?? state.goalMl,
        glassMl: glassMl ?? state.glassMl,
        days: days ?? state.days,
        todayAdds: todayAdds ?? state.todayAdds,
      );

  /// Adds [ml] to today (one glass when left out).
  Future<void> drink([int? ml]) {
    final amount = ml ?? state.glassMl;
    final today = dayKey(DateTime.now());
    // After midnight the undo list of yesterday no longer applies.
    final adds = state.days.containsKey(today) || state.todayAdds.isEmpty
        ? state.todayAdds
        : const <int>[];
    return _save(_with(
      days: {...state.days, today: (state.days[today] ?? 0) + amount},
      todayAdds: [...adds, amount],
    ));
  }

  /// Takes back the last amount added today.
  Future<void> undo() async {
    if (state.todayAdds.isEmpty) return;
    final today = dayKey(DateTime.now());
    final last = state.todayAdds.last;
    final left = (state.days[today] ?? 0) - last;
    await _save(_with(
      days: {...state.days, today: left < 0 ? 0 : left},
      todayAdds: state.todayAdds.sublist(0, state.todayAdds.length - 1),
    ));
  }

  Future<void> setGoal(int ml) => _save(_with(goalMl: ml));
  Future<void> setGlass(int ml) => _save(_with(glassMl: ml));
}

// ---- fasting ----------------------------------------------------------------

/// A finished fast.
class Fast extends Equatable {
  final DateTime start;
  final DateTime end;

  /// The hours that were aimed for.
  final int goalHours;
  const Fast({required this.start, required this.end, required this.goalHours});

  Duration get length => end.difference(start);
  bool get reachedGoal => length >= Duration(hours: goalHours);

  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'goal': goalHours,
      };

  static Fast fromJson(Map<String, dynamic> j) => Fast(
        start: DateTime.parse(j['start'] as String),
        end: DateTime.parse(j['end'] as String),
        goalHours: j['goal'] as int,
      );

  @override
  List<Object?> get props => [start, end, goalHours];
}

class FastingState extends Equatable {
  /// Hours of fasting in each plan; the rest of the 24 is the eating window.
  static const plans = [12, 14, 16, 18];

  final bool loaded;
  final int goalHours;

  /// When the fast in progress began; null when not fasting.
  final DateTime? startedAt;

  /// Finished fasts, newest first.
  final List<Fast> history;

  const FastingState({
    this.loaded = false,
    this.goalHours = 14,
    this.startedAt,
    this.history = const [],
  });

  bool get isFasting => startedAt != null;
  DateTime? get endsAt => startedAt?.add(Duration(hours: goalHours));

  Duration elapsed(DateTime now) =>
      startedAt == null ? Duration.zero : now.difference(startedAt!);

  /// 0..1 of the goal.
  double progress(DateTime now) =>
      (elapsed(now).inSeconds / (goalHours * 3600)).clamp(0, 1).toDouble();

  bool reachedGoal(DateTime now) =>
      isFasting && elapsed(now) >= Duration(hours: goalHours);

  @override
  List<Object?> get props => [loaded, goalHours, startedAt, history];
}

class FastingCubit extends Cubit<FastingState> {
  static const _name = 'fasting';
  static const _keep = 30;

  /// A fast shorter than this was started by mistake: not kept.
  static const _shortest = Duration(minutes: 30);

  final HabitStore store;
  FastingCubit(this.store) : super(const FastingState());

  Future<void> load() async {
    final json = await store.read(_name);
    if (isClosed) return;
    final started = json['started_at'] as String?;
    emit(FastingState(
      loaded: true,
      goalHours: json['goal'] as int? ?? 14,
      startedAt: started == null ? null : DateTime.tryParse(started),
      history: [
        for (final f in json['history'] as List? ?? const [])
          Fast.fromJson(f as Map<String, dynamic>),
      ],
    ));
  }

  Future<void> _save(FastingState next) async {
    emit(next);
    await store.write(_name, {
      'goal': next.goalHours,
      'started_at': next.startedAt?.toIso8601String(),
      'history': [for (final f in next.history.take(_keep)) f.toJson()],
    });
  }

  FastingState _with({int? goalHours, List<Fast>? history}) => FastingState(
        loaded: true,
        goalHours: goalHours ?? state.goalHours,
        startedAt: state.startedAt,
        history: history ?? state.history,
      );

  Future<void> setGoal(int hours) => _save(_with(goalHours: hours));

  /// Starts a fast now, or at [at] for one that began earlier (never in
  /// the future). Also moves the start of a fast in progress.
  Future<void> start([DateTime? at]) {
    final now = DateTime.now();
    final when = at == null || at.isAfter(now) ? now : at;
    return _save(FastingState(
      loaded: true,
      goalHours: state.goalHours,
      startedAt: when,
      history: state.history,
    ));
  }

  /// Ends the fast in progress and files it in the history.
  Future<void> end() async {
    final started = state.startedAt;
    if (started == null) return;
    final now = DateTime.now();
    final fast = Fast(start: started, end: now, goalHours: state.goalHours);
    await _save(FastingState(
      loaded: true,
      goalHours: state.goalHours,
      history: [
        if (fast.length >= _shortest) fast,
        ...state.history,
      ],
    ));
  }

  Future<void> deleteFast(Fast fast) =>
      _save(_with(history: [...state.history]..remove(fast)));
}
