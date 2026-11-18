import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/dio_guard.dart';
import '../../../core/network/repository_guard.dart';
import '../../auth/data/datasources/auth_token_storage.dart';
import '../domain/user_profile.dart';

Map<String, dynamic> profileToJson(UserProfile p) => {
      'email': p.email,
      'full_name': p.fullName,
      'date_of_birth':
          p.dateOfBirth == null ? null : formatApiDate(p.dateOfBirth!),
      'gender': p.gender?.apiValue,
      'blood_group': p.bloodGroup,
      'conditions': p.conditions,
      'allergies': p.allergies,
    };

UserProfile profileFromJson(Map<String, dynamic> j) => UserProfile(
      email: (j['email'] ?? '') as String,
      fullName: (j['full_name'] ?? '') as String,
      dateOfBirth: parseDate(j['date_of_birth']),
      gender: Gender.fromApi(j['gender'] as String?),
      bloodGroup: j['blood_group'] as String?,
      conditions: [for (final c in (j['conditions'] as List? ?? [])) '$c'],
      allergies: [for (final a in (j['allergies'] as List? ?? [])) '$a'],
    );

class ProfileRemoteDataSource {
  final Dio dio;
  ProfileRemoteDataSource(this.dio);

  Future<UserProfile> get() => dioGuard(() async {
        final res = await dio.get(ApiConstants.profile);
        return profileFromJson(res.data as Map<String, dynamic>);
      });

  Future<UserProfile> save(UserProfile profile) => dioGuard(() async {
        final body = profileToJson(profile)..remove('email');
        final res = await dio.put(ApiConstants.profile, data: body);
        return profileFromJson(res.data as Map<String, dynamic>);
      });
}

class ProfileRepositoryImpl implements ProfileRepository {
  /// Removed with the session on sign out (see [AuthTokenStorage.clear]).
  static const cacheKey = 'profile_cache';

  final ProfileRemoteDataSource remote;
  final SharedPreferences prefs;
  final AuthTokenStorage tokenStorage;

  ProfileRepositoryImpl({
    required this.remote,
    required this.prefs,
    required this.tokenStorage,
  });

  @override
  UserProfile? get cached {
    final raw = prefs.getString(cacheKey);
    if (raw == null) return null;
    try {
      return profileFromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<UserProfile> _remember(UserProfile profile) async {
    await prefs.setString(cacheKey, jsonEncode(profileToJson(profile)));
    // The saved session carries the name shown around the app.
    await tokenStorage.updateFullName(profile.fullName);
    return profile;
  }

  @override
  Future<Either<Failure, UserProfile>> getProfile() =>
      guardApiCall(() async => _remember(await remote.get()));

  @override
  Future<Either<Failure, UserProfile>> saveProfile(UserProfile profile) =>
      guardApiCall(() async => _remember(await remote.save(profile)));
}
