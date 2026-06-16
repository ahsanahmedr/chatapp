import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';

class NewChatScreen extends ConsumerWidget {
  const NewChatScreen({super.key});

  static const _primary = Color(0xFF6C47FF);
  static const _bg = Color(0xFFF4F5F9);
  static const _dark = Color(0xFF12132A);
  static const _muted = Color(0xFF8E92AA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Same filtered list/search provider used on HomeScreen, reused here
    final users = ref.watch(filteredUsersProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _dark),
          onPressed: () {
            // clear the search before leaving so HomeScreen list isn't filtered
            ref.read(searchQueryProvider.notifier).state = '';
            context.pop();
          },
        ),
        title: const Text('New Chat',
            style: TextStyle(
                color: _dark, fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              onChanged: (val) =>
                  ref.read(searchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search by name',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: users.isEmpty
                ? const Center(
                    child: Text('No users found',
                        style: TextStyle(color: _muted)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: users.length,
                    itemBuilder: (_, i) {
                      final user = users[i];
                      return _SelectableUserTile(user: user);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SelectableUserTile extends ConsumerWidget {
  final UserModel user;
  const _SelectableUserTile({required this.user});

  static const _primary = Color(0xFF6C47FF);
  static const _dark = Color(0xFF12132A);
  static const _muted = Color(0xFF8E92AA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        // clear search so it doesn't carry over to HomeScreen
        ref.read(searchQueryProvider.notifier).state = '';
        context.push('/chat', extra: user);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _primary,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: _dark)),
                  const SizedBox(height: 2),
                  Text(user.email,
                      style: const TextStyle(fontSize: 12, color: _muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}