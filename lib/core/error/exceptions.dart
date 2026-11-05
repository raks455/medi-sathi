class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

class CacheException implements Exception {}

/// The user closed the Google account picker. Not an error to show.
class AuthCancelledException implements Exception {}
