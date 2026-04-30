import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background handler — top-level function (FCM requirement)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.saveToPrefs(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
  AndroidNotificationChannel(
    'coursemart_channel',
    'CourseMart Notifications',
    description: 'Exam reminders & new lecture alerts',
    importance: Importance.high,
    playSound: true,
  );

  // ─── Initialize ────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    await _requestPermission();
    await _setupLocal();
    await _subscribeTopics();

    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onTap);

    final init = await _fcm.getInitialMessage();
    if (init != null) await saveToPrefs(init);

    await _saveToken();
  }

  // ─── Permission ────────────────────────────────────────────────────────────
  Future<void> _requestPermission() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ─── Local notification setup ──────────────────────────────────────────────
  Future<void> _setupLocal() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  // ─── FCM Topics ────────────────────────────────────────────────────────────
  Future<void> _subscribeTopics() async {
    await _fcm.subscribeToTopic('exam_reminder');
    await _fcm.subscribeToTopic('lecture_uploaded');
  }

  Future<void> unsubscribeAll() async {
    await _fcm.unsubscribeFromTopic('exam_reminder');
    await _fcm.unsubscribeFromTopic('lecture_uploaded');
  }

  // ─── Foreground: show local notification ───────────────────────────────────
  Future<void> _onForeground(RemoteMessage message) async {
    await saveToPrefs(message);
    final n = message.notification;
    if (n == null) return;

    await _local.show(
      message.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ─── Notification tapped ───────────────────────────────────────────────────
  void _onTap(RemoteMessage message) {
    saveToPrefs(message);
  }

  // ─── Save FCM Token ────────────────────────────────────────────────────────
  Future<void> _saveToken() async {
    final token = await _fcm.getToken();
    if (token == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);

    _fcm.onTokenRefresh.listen((newToken) async {
      final p = await SharedPreferences.getInstance();
      await p.setString('fcm_token', newToken);
    });
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  // ─── Save notification to SharedPreferences ────────────────────────────────
  static Future<void> saveToPrefs(RemoteMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('notifications') ?? [];

    final item = jsonEncode({
      'id': message.messageId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'type': message.data['type'] ?? 'general',
      'data': message.data,
      'time': DateTime.now().toIso8601String(),
      'isRead': false,
    });

    existing.insert(0, item);

    if (existing.length > 50) existing.removeLast();

    await prefs.setStringList('notifications', existing);
  }
}