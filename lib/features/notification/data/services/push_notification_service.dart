import 'dart:async';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:dartz/dartz.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/repository_guard.dart';
import '../datasources/notification_remote_datasource.dart';

/// Push reminders: registers this phone with the backend and shows the
/// reminder pushes the server sends through Firebase Cloud Messaging.
/// A dose reminder that arrived while the app is open.
class ReminderAlert {
  final String title;
  final String body;

  /// The user's photo of the medicine, if there is one.
  final String? imageUrl;
  const ReminderAlert({required this.title, required this.body, this.imageUrl});
}

abstract class PushNotificationService {
  /// Dose reminders arriving while the app is open, to show on the screen
  /// itself: a sound alone does not reach someone who cannot hear it.
  Stream<ReminderAlert> get onAlert;

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

  /// The channel newer servers send reminders to (their
  /// REMINDER_ANDROID_CHANNEL_ID). Besides the sound it vibrates in a long,
  /// clear pattern and blinks the notification light, so a reminder also
  /// reaches people who are deaf or hard of hearing. A new channel because
  /// Android never changes the vibration of an existing one.
  static final _strongChannel = AndroidNotificationChannel(
    'medication_reminders_v2',
    'Medication reminders (sound, vibration and light)',
    description: 'Reminders to take your medicines on time',
    importance: Importance.max,
    vibrationPattern: _reminderVibration,
    enableLights: true,
    ledColor: const Color(0xFF3368A0),
  );
  static final _reminderVibration =
      Int64List.fromList([0, 700, 350, 700, 350, 700]);

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
  final _alerts = StreamController<ReminderAlert>.broadcast();

  @override
  Stream<ReminderAlert> get onAlert => _alerts.stream;
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
    await localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_strongChannel);
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

  /// Saves the picture at [url] to a temporary file and returns its path;
  /// null if there is none or it cannot be fetched quickly (the reminder
  /// must not wait for it).
  Future<String?> _downloadPicture(String? url) async {
    if (url == null || url.isEmpty) return null;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response =
          await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final bytes = await response
          .fold<List<int>>([], (all, chunk) => all..addAll(chunk))
          .timeout(const Duration(seconds: 8));
      final dir = await getTemporaryDirectory();
      // One file per photo version: the link changes when the photo does.
      final file = File('${dir.path}/reminder_${url.hashCode}.img');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
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
            : data['type'] == 'period_reminder'
                ? 'cycle'
                : null);
    final alarm = data['alert_style'] == 'alarm';
    if (data['type'] == 'medication_reminder') {
      _alerts.add(ReminderAlert(
        title: notification.title ?? '',
        body: notification.body ?? '',
        imageUrl: data['image'] as String?,
      ));
    }
    // The user's photo of the medicine: shown large, so the medicine can be
    // recognised without reading its name.
    final picture = await _downloadPicture(data['image'] as String?);
    final style = picture == null
        ? null
        : BigPictureStyleInformation(
            FilePathAndroidBitmap(picture),
            largeIcon: FilePathAndroidBitmap(picture),
            contentTitle: notification.title,
            summaryText: notification.body,
          );
    final largeIcon = picture == null ? null : FilePathAndroidBitmap(picture);
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
                  styleInformation: style,
                  largeIcon: largeIcon,
                )
              : AndroidNotificationDetails(
                  _strongChannel.id,
                  _strongChannel.name,
                  channelDescription: _strongChannel.description,
                  importance: Importance.max,
                  priority: Priority.high,
                  vibrationPattern: _reminderVibration,
                  enableLights: true,
                  ledColor: const Color(0xFF3368A0),
                  ledOnMs: 600,
                  ledOffMs: 400,
                  tag: tag,
                  styleInformation: style,
                  largeIcon: largeIcon,
                ),
        ),
      );
    } catch (e) {
      debugPrint('Could not show reminder notification: $e');
    }
  }
}
