import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/error/failures.dart';

enum Gender {
  male('male', 'Male'),
  female('female', 'Female'),
  other('other', 'Other');

  final String apiValue;
  final String label;
  const Gender(this.apiValue, this.label);

  static Gender? fromApi(String? v) {
    for (final g in values) {
      if (g.apiValue == v) return g;
    }
    return null;
  }
}

/// The signed-in user's name and personal health details.
class UserProfile extends Equatable {
  static const bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  /// Offered as quick picks; the user can also type their own.
  static const commonConditions = [
    'Diabetes', 'High blood pressure', 'Heart disease', 'Asthma',
    'Thyroid disorder', 'High cholesterol', 'Kidney disease', 'Arthritis',
    'Migraine', 'Epilepsy', 'Tuberculosis', 'Anaemia',
  ];
  static const commonAllergies = [
    'Penicillin', 'Sulfa drugs', 'Aspirin', 'Ibuprofen', 'Peanuts', 'Seafood',
    'Eggs', 'Milk', 'Dust', 'Pollen', 'Latex',
  ];

  final String email;
  final String fullName;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String? bloodGroup;

  /// Diseases and long-term conditions the user has.
  final List<String> conditions;
  final List<String> allergies;

  const UserProfile({
    this.email = '',
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.conditions = const [],
    this.allergies = const [],
  });

  /// The period and pregnancy trackers are only offered to women.
  bool get isFemale => gender == Gender.female;

  /// Full years since [dateOfBirth].
  int? get age => dateOfBirth == null ? null : ageOn(dateOfBirth!);

  static int ageOn(DateTime born, [DateTime? today]) {
    final now = today ?? DateTime.now();
    final hadBirthday =
        now.month > born.month || (now.month == born.month && now.day >= born.day);
    return now.year - born.year - (hadBirthday ? 0 : 1);
  }

  @override
  List<Object?> get props =>
      [email, fullName, dateOfBirth, gender, bloodGroup, conditions, allergies];
}

abstract class ProfileRepository {
  /// The profile as last loaded on this phone, if any.
  UserProfile? get cached;

  Future<Either<Failure, UserProfile>> getProfile();

  /// Replaces the whole profile and returns it as saved.
  Future<Either<Failure, UserProfile>> saveProfile(UserProfile profile);
}
