import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    _handleNotificationTap(message);
  });

  final token = await FirebaseMessaging.instance.getToken();
  log('MY FCM TOKEN: $token');

  runApp(const ProviderScope(child: MyApp()));

  // ✅ runApp ke BAAD — taake navigatorKey ready ho
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      Future.delayed(const Duration(milliseconds: 1), () {
        _handleNotificationTap(message);
      });
    }
  });
}
String? pendingNotificationUid;
String? pendingNotificationName;
// ✅ Handler function
void _handleNotificationTap(RemoteMessage message) {
  final senderUid = message.data['senderUid'];
  final senderName = message.data['senderName'];

  if (senderUid == null || senderName == null) return;

  final context = navigatorKey.currentContext;
  if (context == null) {
    pendingNotificationUid = senderUid;
    pendingNotificationName = senderName;
    return;
  }

  // ✅ Pehle home stack mein daalo silently, phir chat push karo
  context.go('/home');
  WidgetsBinding.instance.addPostFrameCallback((_) {
    navigatorKey.currentContext?.push('/chat', extra: {
      'uid': senderUid,
      'name': senderName,
      'email': '',
      'fcmToken': null,
    });
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ChatRiver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C47FF)),
        useMaterial3: true,
      ),
      routerConfig: appRouter, // ✅ navigatorKey app_router.dart mein add karna hai
    );
  }
}