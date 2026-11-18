import 'package:dio/dio.dart';

import '../error/exceptions.dart';

/// Converts a DioException into a friendly app exception.
/// Handles FastAPI errors: {"detail": "text"} and {"detail": [{"loc":[..],"msg":".."}]}
Exception mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return NetworkException(
          'The server is taking too long to respond. It may be waking up, please try again in a moment.');
    case DioExceptionType.connectionError:
      return NetworkException(
          'Cannot reach the server. Please check your internet connection.');
    default:
      break;
  }

  final code = e.response?.statusCode;
  return ServerException(
    _extractMessage(e.response?.data) ?? _fallback(code),
    statusCode: code,
  );
}

String? _extractMessage(dynamic data) {
  if (data is! Map || data['detail'] == null) return null;
  final detail = data['detail'];

  // FastAPI's answer for a path the server does not have: the app is newer
  // than the deployed backend.
  if (detail == 'Not Found' || detail == 'Method Not Allowed') {
    return 'This feature is not available on the server yet. '
        'Please try again later.';
  }
  if (detail is String) return detail;

  if (detail is List && detail.isNotEmpty && detail.first is Map) {
    final first = detail.first as Map;
    final msg = first['msg']?.toString();
    if (msg == null) return null;
    final clean = msg.replaceFirst('Value error, ', '');
    final loc = first['loc'];
    if (loc is List && loc.isNotEmpty && loc.last is String) {
      final field = loc.last as String;
      if (field != 'body') return '$field: $clean';
    }
    return clean;
  }
  return null;
}

String _fallback(int? code) {
  switch (code) {
    case 401:
      return 'Incorrect email or password.';
    case 409:
      return 'An account with this email already exists.';
    case 422:
      return 'Please check the details you entered.';
    default:
      if (code != null && code >= 500) {
        return 'Server error. Please try again later.';
      }
      return 'Something went wrong. Please try again.';
  }
}
