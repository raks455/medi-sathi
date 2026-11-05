import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session_model.dart';

abstract class AuthTokenStorage {
  Future<void> saveSession(AuthSessionModel session);
  Future<AuthSessionModel?> readSession();
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> updateTokens({required String access, required String refresh});
  Future<void> clear();
}

/// TODO: move to flutter_secure_storage before release (tokens are sensitive).
class AuthTokenStorageImpl implements AuthTokenStorage {
  static const _key = 'auth_session';
  final SharedPreferences prefs;
  AuthTokenStorageImpl(this.prefs);

  @override
  Future<void> saveSession(AuthSessionModel session) async {
    await prefs.setString(_key, jsonEncode(session.toJson()));
  }

  @override
  Future<AuthSessionModel?> readSession() async {
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return AuthSessionModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> readAccessToken() async => (await readSession())?.accessToken;

  @override
  Future<String?> readRefreshToken() async =>
      (await readSession())?.refreshToken;

  @override
  Future<void> updateTokens(
      {required String access, required String refresh}) async {
    final session = await readSession();
    if (session == null) return;
    await saveSession(session.copyWith(accessToken: access, refreshToken: refresh));
  }

  @override
  Future<void> clear() async {
    await prefs.remove(_key);
  }
}
