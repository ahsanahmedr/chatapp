import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  static const _primary = Color(0xFF6C47FF);
  static const _bg = Color(0xFFF4F5F9);
  static const _dark = Color(0xFF12132A);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.chat_bubble_outline,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 24),
                const Text('Welcome Back!',
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold, color: _dark)),
                const SizedBox(height: 8),
                Text('Sign in to continue chatting',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
                const SizedBox(height: 40),

                _label('Email Address'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Enter your email', Icons.email_outlined),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Email is required.';
                    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!regex.hasMatch(val)) return 'Enter a valid email.';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                _label('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration(
                    'Enter your password',
                    Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Password is required.';
                    return null;
                  },
                ),

                if (authState.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(authState.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ],

                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('Sign In',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ",
                        style: TextStyle(color: Colors.grey.shade500)),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: const Text('Sign Up',
                          style: TextStyle(
                              color: _primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: _dark));

  InputDecoration _inputDecoration(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: _primary),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2)),
    );
  }
}