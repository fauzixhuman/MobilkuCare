import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler — must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message received: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Android notification channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'mobilku_care_channel',
    'Perawatan Mobilku',
    description: 'Notifikasi perawatan dan pengingat cuci kendaraan',
    importance: Importance.high,
  );

  Future<void> init() async {
    try {
      // ── Local Notifications Setup ──
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(initSettings);

      // Create the notification channel on Android
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channel);
        // Request notification permission on Android 13+
        await androidPlugin.requestNotificationsPermission();
      }

      // ── Firebase Cloud Messaging Setup ──
      FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler);

      // Request FCM permission (iOS / Android 13+)
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('FCM Permission status: ${settings.authorizationStatus}');

      // Listen for foreground FCM messages and show them as local notifications
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Get and save FCM token
      final token = await _fcm.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _saveFcmToken(token);
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_saveFcmToken);
    } catch (e) {
      debugPrint('NotificationService init error (OK on web): $e');
    }
  }

  /// Handle foreground FCM messages — show as local notification + save to Firestore
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      debugPrint(
          '🔔 Foreground message: ${notification.title} - ${notification.body}');

      // Show as local notification on device
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );

      // Save to Firestore for in-app history
      FirebaseFirestore.instance.collection('notifications').add({
        'title': notification.title ?? '',
        'body': notification.body ?? '',
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Save FCM token to Firestore for server-side messaging
  Future<void> _saveFcmToken(String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc('device')
          .set({
        'token': token,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Show a local notification on the device AND save to Firestore history
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String userId = '',
  }) async {
    // 1. Show actual system notification on the device
    try {
      await _localNotifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
      debugPrint('🔔 Local notification shown: $title - $body');
    } catch (e) {
      debugPrint('Error showing local notification (OK on web): $e');
    }

    // 2. Save to Firestore for notification history (with user_id)
    try {
      final data = <String, dynamic>{
        'title': title,
        'body': body,
        'created_at': FieldValue.serverTimestamp(),
      };
      if (userId.isNotEmpty) {
        data['user_id'] = userId;
      }
      await FirebaseFirestore.instance.collection('notifications').add(data);
    } catch (e) {
      debugPrint('Error saving notification to Firestore: $e');
    }
  }
}
