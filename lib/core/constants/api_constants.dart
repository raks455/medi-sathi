class ApiConstants {
  ApiConstants._();

  static const baseUrl = 'https://medisathi-c41p.onrender.com';
  static const _api = '/api/v1';

  // Auth
  static const register = '$_api/auth/register';
  static const login = '$_api/auth/login';
  static const refresh = '$_api/auth/refresh';
  static const logout = '$_api/auth/logout';

  /// Exchanges a Firebase ID token for MediSathi tokens.
  /// NOT in the current Swagger: the backend must add this endpoint
  /// (POST {"id_token": "..."} -> TokenResponse). Change the path if yours differs.
  static const googleLogin = '$_api/auth/google';

  // Dashboard (needs Bearer token)
  static const dashboard = '$_api/dashboard';

  // Misc
  static const health = '/health';
}
