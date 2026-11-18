import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../core/error/failures.dart';
import '../../../core/l10n/l10n.dart';

// ---- vitals -----------------------------------------------------------------

enum VitalType {
  weight('weight', 'Weight'),
  bloodPressure('blood_pressure', 'Blood pressure'),
  height('height', 'Height');

  final String apiValue;
  final String label;
  const VitalType(this.apiValue, this.label);

  static VitalType fromApi(String v) =>
      values.firstWhere((t) => t.apiValue == v, orElse: () => weight);
}

/// '70' for 70.0, '70.5' for 70.5.
String formatNumber(double value, {int digits = 1}) {
  final s = value.toStringAsFixed(digits);
  return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
}

/// How weight is shown and typed. The server always stores kilograms.
enum WeightUnit {
  kg('kg', 1),
  lb('lb', 2.2046226218);

  final String label;
  final double perKg;
  const WeightUnit(this.label, this.perKg);

  double fromKg(double kilograms) => kilograms * perKg;
  double toKg(double value) => value / perKg;
  String format(double kilograms) =>
      '${formatNumber(fromKg(kilograms))} $label';

  static WeightUnit fromName(String? name) =>
      values.firstWhere((u) => u.name == name, orElse: () => kg);
}

/// How height is shown and typed. The server always stores centimetres.
enum HeightUnit {
  cm('cm'),
  m('m'),
  ftIn('ft / in');

  final String label;
  const HeightUnit(this.label);

  static const _cmPerInch = 2.54;

  /// Whole feet and the remaining inches (one decimal).
  static (int, double) feetInches(double centimetres) {
    final total =
        double.parse((centimetres / _cmPerInch).toStringAsFixed(1));
    final feet = total ~/ 12;
    return (feet, double.parse((total - feet * 12).toStringAsFixed(1)));
  }

  static double cmFromFeetInches(int feet, double inches) =>
      (feet * 12 + inches) * _cmPerInch;

  String format(double centimetres) {
    switch (this) {
      case HeightUnit.cm:
        return '${formatNumber(centimetres)} cm';
      case HeightUnit.m:
        return '${formatNumber(centimetres / 100, digits: 2)} m';
      case HeightUnit.ftIn:
        final (feet, inches) = feetInches(centimetres);
        return '$feet ft ${formatNumber(inches)} in';
    }
  }

  static HeightUnit fromName(String? name) =>
      values.firstWhere((u) => u.name == name, orElse: () => cm);
}

class VitalReading extends Equatable {
  final String id;
  final VitalType type;

  /// kg, cm, or systolic mmHg.
  final double value;

  /// Diastolic mmHg (blood pressure only).
  final double? value2;
  final int? pulse;
  final String? note;
  final DateTime recordedAt;

  /// Blood pressure category from the server, e.g. 'high_stage_1'.
  final String? category;

  const VitalReading({
    required this.id,
    required this.type,
    required this.value,
    this.value2,
    this.pulse,
    this.note,
    required this.recordedAt,
    this.category,
  });

  /// The reading with its unit, e.g. '154 lb', '5 ft 7 in', '120/80 mmHg'.
  String format(WeightUnit weightUnit, HeightUnit heightUnit) =>
      switch (type) {
        VitalType.weight => weightUnit.format(value),
        VitalType.height => heightUnit.format(value),
        VitalType.bloodPressure =>
          '${value.round()}/${value2?.round() ?? '-'} mmHg',
      };

  @override
  List<Object?> get props =>
      [id, type, value, value2, pulse, note, recordedAt, category];
}

/// What the user typed for a new or corrected reading, in kg / cm / mmHg.
class VitalInput {
  final VitalType type;
  final double value;
  final double? value2;
  final int? pulse;
  final String? note;
  final DateTime? recordedAt;

  const VitalInput({
    required this.type,
    required this.value,
    this.value2,
    this.pulse,
    this.note,
    this.recordedAt,
  });
}

class VitalsSummary extends Equatable {
  final VitalReading? weight;
  final VitalReading? height;
  final VitalReading? bloodPressure;
  final double? bmi;
  final String? bmiCategory;

  /// kg gained (+) or lost (-) compared with about 30 days ago.
  final double? weightChange30d;

  const VitalsSummary({
    this.weight,
    this.height,
    this.bloodPressure,
    this.bmi,
    this.bmiCategory,
    this.weightChange30d,
  });

  /// This summary with [latest] as the newest reading of [type] and the BMI
  /// worked out again, so the screen is right before the server answers.
  VitalsSummary withLatest(VitalType type, VitalReading? latest) {
    final w = type == VitalType.weight ? latest : weight;
    final h = type == VitalType.height ? latest : height;
    final bp = type == VitalType.bloodPressure ? latest : bloodPressure;
    double? newBmi;
    String? category;
    if (w != null && h != null && h.value > 0) {
      final meters = h.value / 100;
      newBmi =
          double.parse((w.value / (meters * meters)).toStringAsFixed(1));
      category = newBmi < 18.5
          ? 'underweight'
          : newBmi < 25
              ? 'normal'
              : newBmi < 30
                  ? 'overweight'
                  : 'obese';
    }
    return VitalsSummary(
      weight: w,
      height: h,
      bloodPressure: bp,
      bmi: newBmi,
      bmiCategory: category,
      weightChange30d: w == null ? null : weightChange30d,
    );
  }

  @override
  List<Object?> get props =>
      [weight, height, bloodPressure, bmi, bmiCategory, weightChange30d];
}

/// Human labels and colors for the server's category codes.
class HealthLabels {
  HealthLabels._();

  static String category(String? code) => switch (code) {
        'underweight' => 'Underweight'.tr,
        'normal' => 'Healthy'.tr,
        'overweight' => 'Overweight'.tr,
        'obese' => 'Obese'.tr,
        'low' => 'Low'.tr,
        'elevated' => 'Elevated'.tr,
        'high_stage_1' => 'High (stage 1)'.tr,
        'high_stage_2' => 'High (stage 2)'.tr,
        'crisis' => 'Very high – seek care'.tr,
        _ => '',
      };

  /// 0 = good, 1 = watch, 2 = concern.
  static int severity(String? code) => switch (code) {
        'normal' => 0,
        'underweight' || 'overweight' || 'elevated' || 'low' => 1,
        null => 0,
        _ => 2,
      };
}

// ---- mood -------------------------------------------------------------------

enum Mood {
  great('great', 'Great', '😄', Color(0xFF4E9A7B)),
  good('good', 'Good', '🙂', Color(0xFF66A3BF)),
  okay('okay', 'Okay', '😐', Color(0xFFC9A22B)),
  low('low', 'Low', '😔', Color(0xFFC98A2B)),
  bad('bad', 'Bad', '😣', Color(0xFFC0504D));

  final String apiValue;
  final String label;
  final String emoji;
  final Color color;
  const Mood(this.apiValue, this.label, this.emoji, this.color);

  /// [label] in the current language. 'Low' also names a blood pressure
  /// category, which is a different word in Nepali, so the mood has its own
  /// entry there.
  String get localizedLabel =>
      this == low && L10n.isNepali ? 'Low mood'.tr : label.tr;

  static Mood fromApi(String v) =>
      values.firstWhere((m) => m.apiValue == v, orElse: () => okay);

  /// Quick tags offered after picking a mood.
  static const suggestedTags = [
    'calm', 'energetic', 'tired', 'stressed', 'anxious', 'headache', 'pain',
    'nausea', 'dizzy', 'slept well', 'slept badly',
  ];

  /// Period-related symptoms, offered too when the user tracks a cycle.
  static const cycleTags = [
    'cramps', 'bloating', 'tender breasts', 'acne', 'cravings', 'mood swings',
    'back pain', 'spotting',
  ];
}

class MoodEntry extends Equatable {
  final String id;
  final Mood mood;
  final String? note;
  final List<String> tags;
  final DateTime recordedAt;

  const MoodEntry({
    required this.id,
    required this.mood,
    this.note,
    this.tags = const [],
    required this.recordedAt,
  });

  bool get isToday {
    final local = recordedAt.toLocal();
    final now = DateTime.now();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  @override
  List<Object?> get props => [id, mood, note, tags, recordedAt];
}

// ---- repository -------------------------------------------------------------

abstract class WellnessRepository {
  Future<Either<Failure, VitalsSummary>> getVitalsSummary();
  Future<Either<Failure, List<VitalReading>>> getVitals(VitalType type,
      {int? days});
  Future<Either<Failure, VitalReading>> addVital(VitalInput input);
  Future<Either<Failure, VitalReading>> updateVital(
      String id, VitalInput input);
  Future<Either<Failure, Unit>> deleteVital(String id);

  /// Newest first.
  Future<Either<Failure, List<MoodEntry>>> getMoods({int days = 30});
  Future<Either<Failure, MoodEntry>> addMood(Mood mood,
      {String? note, List<String> tags = const []});
  Future<Either<Failure, Unit>> deleteMood(String id);
}
