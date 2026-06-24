import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../providers/chat_provider.dart';
import '../services/notification_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _bg = Color(0xFFF4F5F9);
  static const _dark = Color(0xFF12132A);
  static const _muted = Color(0xFF8E92AA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
      final myUid = ref.watch(currentUidProvider);
  if (myUid != null) {
    NotificationService.saveTokenForUser(myUid);
  }
    // Watch filtered users list — updates automatically on search/data change
    final users = ref.watch(filteredUsersProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('Chats',
            style: TextStyle(
                color: _dark, fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: _dark),
            onPressed: () async {
              // Ask for confirmation before logging out
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content:
                      const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Logout',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              // Wait for Firebase signOut (and any cleanup) to finish
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // Users list
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
                      return _UserTile(user: user);
                    },
                  ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF6C47FF),
                ),
                child: IconButton(
                  onPressed: () {
                    // Open the New Chat screen — search + select user
                    context.push('/new-chat');
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  final UserModel user;
  const _UserTile({required this.user});

  static const _primary = Color(0xFF6C47FF);
  static const _dark = Color(0xFF12132A);
  static const _muted = Color(0xFF8E92AA);
  static const _unreadBlue = Color(0xFF2196F3);

  // Show delete confirmation before removing the conversation
  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final myUid = ref.read(currentUidProvider)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Chat',
            style: TextStyle(fontWeight: FontWeight.w700, color: _dark)),
        content: Text(
          'Delete entire conversation with ${user.name}? This cannot be undone.',
          style: const TextStyle(color: _muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _muted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Delete entire chat and its messages from Firestore
              await ref.read(chatServiceProvider).deleteChat(myUid, user.uid);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(currentUidProvider)!;

    // Real-time last-message + seen status for this conversation.
    final previewAsync =
        ref.watch(chatPreviewProvider((uid1: myUid, uid2: user.uid)));
    final preview = previewAsync.valueOrNull;

    // Unread only if there IS a last message, it wasn't seen yet, and it
    // wasn't sent by me (no dot for my own outgoing messages).
    final hasUnseen = preview != null &&
        !preview.lastSeen &&
        preview.lastSenderId != null &&
        preview.lastSenderId != myUid;

    final String subtitleText;
    if (preview?.lastMessage != null && preview!.lastMessage!.trim().isNotEmpty) {
      subtitleText = preview.lastSenderId == myUid
          ? 'You: ${preview.lastMessage}'
          : preview.lastMessage!;
    } else {
      subtitleText = 'Say hi 👋';
    }

    return GestureDetector(
      onTap: () {
        // Open chat screen with selected user
        context.push('/chat', extra: user);
      },
      onLongPress: () => _confirmDelete(context, ref), // ← delete trigger
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
                  Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                hasUnseen ? FontWeight.w700 : FontWeight.w600,
                            color: _dark,
                          ),
                        ),
                      ),
                      if (hasUnseen) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: _unreadBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasUnseen ? _dark : _muted,
                      fontWeight:
                          hasUnseen ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}