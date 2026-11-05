import 'package:dio/dio.dart';

import '../../features/auth/data/datasources/auth_token_storage.dart';
import '../constants/api_constants.dart';

/// Adds the Bearer token to requests and, on a 401, refreshes the token once
/// and retries the original request.
class AuthInterceptor extends Interceptor {
  final AuthTokenStorage tokenStorage;
  final Dio dio;

  AuthInterceptor({required this.tokenStorage, required this.dio});

  // A bare Dio (no interceptors) so a refresh can never loop.
  late final Dio _refreshDio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  ));

  static const _noBearer = [
    ApiConstants.login,
    ApiConstants.register,
    ApiConstants.googleLogin,
    ApiConstants.refresh,
  ];
  static const _noRefresh = [..._noBearer, ApiConstants.logout];

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_noBearer.contains(options.path)) {
      final token = await tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final req = err.requestOptions;
    final shouldTryRefresh = err.response?.statusCode == 401 &&
        !_noRefresh.contains(req.path) &&
        req.extra['retried'] != true;

    if (!shouldTryRefresh) {
      handler.next(err);
      return;
    }

    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      handler.next(err);
      return;
    }

    try {
      final res = await _refreshDio.post(
        ApiConstants.refresh,
        data: {'refresh_token': refreshToken},
      );
      final data = res.data as Map<String, dynamic>;
      final newAccess = data['access_token'] as String;
      final newRefresh = data['refresh_token'] as String;
      await tokenStorage.updateTokens(access: newAccess, refresh: newRefresh);

      req.extra['retried'] = true;
      req.headers['Authorization'] = 'Bearer $newAccess';
      handler.resolve(await dio.fetch(req));
    } catch (_) {
      // Refresh failed: the session is over.
      await tokenStorage.clear();
      handler.next(err);
    }
  }
}
