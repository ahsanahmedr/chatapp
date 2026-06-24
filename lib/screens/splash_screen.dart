import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'package:chats/main.dart';
import '../router/app_router.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override

  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state — automatically redirect based on login status
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF6C47FF),
      body: Center(
        child: authState.when(
          loading: () => const CircularProgressIndicator(color: Colors.white),
          error: (err, stack) => const Icon(Icons.error, color: Colors.white),
data: (user) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (user != null) {
      // ✅ Pending notification check karo
      final pendingUid = pendingNotificationUid;
      final pendingName = pendingNotificationName;
      
      if (pendingUid != null && pendingName != null) {
        // Notification thi — seedha chat pe jao
        pendingNotificationUid = null;
        pendingNotificationName = null;
        appRouter.go('/home');
        Future.delayed(const Duration(milliseconds: 1), () {
          appRouter.push('/chat', extra: {
            'uid': pendingUid,
            'name': pendingName,
            'email': '',
            'fcmToken': null,
          });
        });
      } else {
        appRouter.go('/home');
      }
    } else {
      appRouter.go('/login');
    }
  });
            return const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 64),
                SizedBox(height: 16),
                Text(
                  'ChatRiver',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}