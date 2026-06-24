import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Top-level handler — REQUIRED to be top-level (not inside a class) so it
/// can run in the background isolate when the app is killed.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No UI work here — OS shows the notification automatically for
  // killed/background state using the "notification" payload from FCM.
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  /// Call once in main() before runApp().
  static Future<void> init() async {
    // Ask user for notification permission (required on iOS, Android 13+).
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Local notifications setup — used to show a banner while app is OPEN
    // (FCM does not auto-display a system notification in foreground).
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);

    // Background/terminated messages go through this top-level handler.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages — app open and visible, show our own banner.
    FirebaseMessaging.onMessage.listen((message) {
      final notif = message.notification;
      if (notif == null) return;
      _localNotifications.show(
        notif.hashCode,
        notif.title,
        notif.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_messages',
            'Chat Messages',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });
  }

  /// Save this device's FCM token to the user's Firestore doc, and keep
  /// it updated if Firebase rotates the token.
  static Future<void> saveTokenForUser(String uid) async {
    final token = await _messaging.getToken();
    log('TOKEN TO SAVE: $token for uid: $uid');
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
      log('TOKEN SAVED SUCCESSFULLY');
    }

    _messaging.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': newToken}, SetOptions(merge: true));
    });
  }

  /// App icon badge — call with total unread count across all chats.
  /// Call with 0 to clear it.
static Future<void> updateBadge(int count) async {
  final isSupported = await AppBadgePlus.isSupported();
  if (!isSupported) return;
  await AppBadgePlus.updateBadge(count);
}
}