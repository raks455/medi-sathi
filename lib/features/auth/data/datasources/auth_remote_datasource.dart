import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_error.dart';
import '../models/auth_session_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthSessionModel> register({
    required String email,
    required String password,
    required String fullName,
  });
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  });
  Future<AuthSessionModel> loginWithGoogle(String firebaseIdToken);
  Future<void> logout(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<AuthSessionModel> register({
    required String email,
    required String password,
    required String fullName,
  }) =>
      _authenticate(ApiConstants.register, {
        'email': email,
        'password': password,
        'full_name': fullName,
      });

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) =>
      _authenticate(ApiConstants.login, {
        'email': email,
        'password': password,
      });

  @override
  Future<AuthSessionModel> loginWithGoogle(String firebaseIdToken) =>
      _authenticate(ApiConstants.googleLogin, {'id_token': firebaseIdToken});

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await dio.post(ApiConstants.logout, data: {'refresh_token': refreshToken});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<AuthSessionModel> _authenticate(
      String path, Map<String, dynamic> body) async {
    try {
     
      log("body $body");
      final res = await dio.post(path, data: body);
      return AuthSessionModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('AUTH ERROR $path -> ${e.response?.statusCode} ${e.response?.data}');
      throw mapDioException(e);
    }
  }
}
