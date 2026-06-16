import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

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
            // Redirect after build completes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (user != null) {
                context.go('/home');
              } else {
                context.go('/login');
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