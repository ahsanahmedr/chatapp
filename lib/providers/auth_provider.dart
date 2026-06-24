import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Firebase Auth instance provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Current logged in user — stream that updates on login/logout
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Auth state class — loading, error, success
class AuthState {
  final bool isLoading;
  final String? errorMessage;

  AuthState({this.isLoading = false, this.errorMessage});
}

// Auth controller — handles login, register, logout
class AuthController extends StateNotifier<AuthState> {
  final FirebaseAuth _auth;

  AuthController(this._auth) : super(AuthState());

  // Register new user and save to Firestore
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = AuthState(isLoading: true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Save user info in Firestore 'users' collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'name': name.trim(),
        'email': email.trim(),
        'createdAt': Timestamp.now(),
      });

      state = AuthState(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = AuthState(isLoading: false, errorMessage: _mapError(e.code));
      return false;
    }
  }

  // Login existing user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = AuthState(isLoading: true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      state = AuthState(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = AuthState(isLoading: false, errorMessage: _mapError(e.code));
      return false;
    }
  }

  // Logout current user
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Convert Firebase error codes to readable messages
  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email.';
      case 'weak-password':
        return 'Password is too weak.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

// Auth controller provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(firebaseAuthProvider));
});