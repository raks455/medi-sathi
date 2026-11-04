import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class DioClient {
  late final Dio dio;
  DioClient() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      // Render free tier cold-starts can be slow
      connectTimeout: const Duration(seconds: 40),
      receiveTimeout: const Duration(seconds: 40),
    ));
    // dio.interceptors.add(AuthInterceptor());
  }
}
