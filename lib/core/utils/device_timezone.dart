import 'package:flutter_timezone/flutter_timezone.dart';

/// The device's IANA timezone (e.g. 'Asia/Kathmandu').
class DeviceTimezone {
  DeviceTimezone._();

  /// Null when it cannot be read or is not an IANA name (e.g. on Windows);
  /// callers then leave it out so the server uses its default.
  static Future<String?> get() async {
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      return name.contains('/') ? name : null;
    } catch (_) {
      return null;
    }
  }
}
