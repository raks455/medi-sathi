import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/repository_guard.dart';
import '../datasources/notification_remote_datasource.dart';

/// Push reminders: registers this phone with the backend and shows the
/// reminder pushes the server sends through Firebase Cloud Messaging.
abstract class PushNotificationService {
  /// Fires when a reminder push arrives in the foreground or is tapped,
  /// so screens can refresh the dose list.
  Stream<void> get onReminder;

  /// Asks for notification permission and sends this phone's FCM token to the
  /// backend. Call when a signed-in user reaches the app; safe to repeat.
  /// Never throws: reminders are a best-effort extra.
  Future<void> registerDevice();

  /// Removes this phone from the backend. Call BEFORE the session is cleared.
  /// Never throws.
  Future<void> unregisterDevice();

  /// Asks the server for a test push; returns how many devices it reached.
  Future<Either<Failure, int>> sendTestPush();
}

///
/// The backend sends with FCM registration tokens, so this uses getToken /
/// deleteToken / onTokenRefresh. firebase_messaging 17 marks them deprecated
/// in favour of register(), but that yields Installation IDs, which the
/// backend's token-based send does not accept.
// ignore_for_file: deprecated_member_use
class PushNotificationServiceImpl implements PushNotificationService {
  /// Must match the backend's REMINDER_ANDROID_CHANNEL_ID.
  static const _channel = AndroidNotificationChannel(
    'medication_reminders',
    'Medication reminders',
    description: 'Reminders to take your medicines on time',
    importance: Importance.high,
  );

  /// For doses whose alert style is "alarm". Must match the backend's
  /// ALARM_ANDROID_CHANNEL_ID. It plays the phone's alarm sound on the alarm
  /// volume (so it is heard when notifications are quiet) and vibrates longer.
  /// Android fixes a channel's sound when it is first created; after that
  /// only the user can change it, in the system settings.
  static final _alarmChannel = AndroidNotificationChannel(
    'medication_alarms',
    'Medication alarms',
    description: 'Loud alarm-style reminders for medicines you chose',
    importance: Importance.max,
    sound: const UriAndroidNotificationSound(
        'content://settings/system/alarm_alert'),
    audioAttributesUsage: AudioAttributesUsage.alarm,
    vibrationPattern: _alarmVibration,
  );
  static final _alarmVibration =
      Int64List.fromList([0, 900, 500, 900, 500, 900, 500, 900]);

  static const _tokenKey = 'fcm_device_token';

  final FirebaseMessaging messaging;
  final FlutterLocalNotificationsPlugin localNotifications;
  final NotificationRemoteDataSource remote;
  final SharedPreferences prefs;

  PushNotificationServiceImpl({
    required this.messaging,
    required this.localNotifications,
    required this.remote,
    required this.prefs,
  });

  final _reminders = StreamController<void>.broadcast();
  Future<void>? _setup;

  /// True between registerDevice and unregisterDevice (a user is signed in).
  bool _active = false;

  @override
  Stream<void> get onReminder => _reminders.stream;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  @override
  Future<void> registerDevice() async {
    if (!_supported) return;
    try {
      await (_setup ??= _setUp());
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      _active = true;
      final token = await messaging.getToken();
      if (token != null) await _sendToken(token);
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  @override
  Future<void> unregisterDevice() async {
    _active = false;
    final token = prefs.getString(_tokenKey);
    if (token == null) return;
    try {
      await remote
          .unregisterDevice(token)
          // Sign-out waits for this, so do not hang on a sleeping server.
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Push unregistration failed: $e');
    }
    try {
      // Invalidates the token on Firebase's side too, so even if the call
      // above failed the next user of this phone gets no stray reminders.
      await messaging.deleteToken();
    } catch (_) {}
    await prefs.remove(_tokenKey);
  }

  @override
  Future<Either<Failure, int>> sendTestPush() =>
      guardApiCall(remote.sendTestPush);

  /// One-time wiring of channels and listeners.
  Future<void> _setUp() async {
    await localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested through FirebaseMessaging instead.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (_) => _reminders.add(null),
    );
    // Background pushes are shown by Android itself in this channel, so it
    // has to exist before the first one arrives.
    await localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    await localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_alarmChannel);
    // iOS can show a push while the app is open; Android needs _showLocal.
    await messaging.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _reminders.add(null));
    messaging.onTokenRefresh.listen((token) {
      if (_active) _sendToken(token).catchError((_) {});
    });
  }

  Future<void> _sendToken(String token) async {
    await remote.registerDevice(token: token, platform: _platform);
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    _reminders.add(null);
    final notification = message.notification;
    if (notification == null ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    // Same tag (and id 0) as the system uses for a background push, so one
    // dose (or one refill reminder) never shows two notifications.
    final data = message.data;
    final tag = data['dose_key'] as String? ??
        (data['type'] == 'refill_reminder'
            ? 'refill:${data['medication_id']}'
            : null);
    final alarm = data['alert_style'] == 'alarm';
    try {
      await localNotifications.show(
        tag != null ? 0 : message.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: alarm
              ? AndroidNotificationDetails(
                  _alarmChannel.id,
                  _alarmChannel.name,
                  channelDescription: _alarmChannel.description,
                  importance: Importance.max,
                  priority: Priority.max,
                  category: AndroidNotificationCategory.alarm,
                  sound: _alarmChannel.sound,
                  audioAttributesUsage: AudioAttributesUsage.alarm,
                  vibrationPattern: _alarmVibration,
                  tag: tag,
                )
              : AndroidNotificationDetails(
                  _channel.id,
                  _channel.name,
                  channelDescription: _channel.description,
                  importance: Importance.high,
                  priority: Priority.high,
                  tag: tag,
                ),
        ),
      );
    } catch (e) {
      debugPrint('Could not show reminder notification: $e');
    }
  }
}
