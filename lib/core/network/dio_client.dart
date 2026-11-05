import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/data/datasources/auth_token_storage.dart';
import '../constants/api_constants.dart';
import 'auth_interceptor.dart';

class DioClient {
  late final Dio dio;

  DioClient(AuthTokenStorage tokenStorage) {
    dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      // Render's free tier can take ~30-50s to wake up from sleep.
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(AuthInterceptor(tokenStorage: tokenStorage, dio: dio));

    if (kDebugMode) {
      // Logs method + URL + status only (bodies off so passwords never print).
      dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        error: true,
      ));
    }
  }
}
