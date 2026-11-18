import 'package:dio/dio.dart';

import 'api_error.dart';

/// Runs a Dio call and turns a DioException into a friendly app exception.
Future<T> dioGuard<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    throw mapDioException(e);
  }
}

DateTime? parseDate(dynamic value) =>
    value == null ? null : DateTime.parse(value as String);

/// 'YYYY-MM-DD' for date-only API fields.
String formatApiDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}'
    '-${d.day.toString().padLeft(2, '0')}';

/// Today's local date, sent to the API so predictions follow the phone's
/// calendar rather than the server's.
String todayParam() => formatApiDate(DateTime.now());
