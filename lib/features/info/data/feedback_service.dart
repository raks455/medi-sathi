import 'dart:io' show Platform;

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/dio_guard.dart';
import '../../../core/network/repository_guard.dart';

/// Sends in-app feedback to the MediSathi team.
class FeedbackService {
  final Dio dio;
  FeedbackService(this.dio);

  /// [topic] is suggestion, problem, compliment or other. [rating] is 1-5.
  Future<Either<Failure, Unit>> send({
    required String topic,
    required String message,
    int? rating,
  }) async {
    final (version, platform) = await deviceInfo();
    return guardApiCall(() => dioGuard(() async {
          await dio.post(ApiConstants.feedback, data: {
            'topic': topic,
            'message': message,
            if (rating != null) 'rating': rating,
            if (version.isNotEmpty) 'app_version': version,
            if (platform.isNotEmpty) 'platform': platform,
          });
          return unit;
        }));
  }

  /// (app version, operating system), empty when unknown.
  static Future<(String, String)> deviceInfo() async {
    var version = '';
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version}+${info.buildNumber}';
    } catch (_) {}
    var os = '';
    try {
      os = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
      if (os.length > 80) os = os.substring(0, 80);
    } catch (_) {}
    return (version, os);
  }
}
