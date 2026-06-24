import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/new_chat_screen.dart';
import '../models/user_model.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
  path: '/chat',
  builder: (context, state) {
    final extra = state.extra;
    if (extra is UserModel) {
      return ChatScreen(otherUser: extra);
    }
    final data = extra as Map<String, dynamic>;
    return ChatScreen(
      otherUser: UserModel(
        uid: data['uid'],
        name: data['name'],
        email: data['email'] ?? '',
        fcmToken: null,
      ),
    );
  },
),
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

    GoRoute(path: '/new-chat', builder: (context, state) => const NewChatScreen()),
  ],
);