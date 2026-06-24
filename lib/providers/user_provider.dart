import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

// Firestore instance provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// All registered users — real-time stream from Firestore.
// Watches authStateProvider so that when the auth state changes
// (logout -> null -> new user login), this provider rebuilds:
// the old Firestore listener is disposed and a fresh one is created
// bound to the correctly authenticated user. While there is no
// logged-in user (momentarily, between logout and login) 
// an empty stream instead of attempting an unauthenticated read,
// which is what was causing the permission-denied error.
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final authState = ref.watch(authStateProvider);

  if (authState.valueOrNull == null) {
    return Stream.value(<UserModel>[]);
  }

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data()))
          .toList());
});

// Current logged in user's uid — now reactive, derived from authStateProvider
// instead of a one-time read of FirebaseAuth.instance.currentUser.
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

// Search query state — used to filter users on home screen
final searchQueryProvider = StateProvider<String>((ref) => '');
final showSearchProvider = StateProvider<bool>((ref) => false);

// Filtered users based on search query, excluding current user
final filteredUsersProvider = Provider<List<UserModel>>((ref) {
  final users = ref.watch(allUsersProvider).value ?? [];
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final currentUid = ref.watch(currentUidProvider);

  return users.where((user) {
    final isNotCurrentUser = user.uid != currentUid;
    final matchesSearch = user.name.toLowerCase().contains(query) ||
        user.email.toLowerCase().contains(query);
    return isNotCurrentUser && matchesSearch;
  }).toList();
});