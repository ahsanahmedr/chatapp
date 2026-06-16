import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final UserModel otherUser;
  const ChatScreen({super.key, required this.otherUser});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();

  static const _primary = Color(0xFF6C47FF);
  static const _bg = Color(0xFFF4F5F9);
  static const _dark = Color(0xFF12132A);

  void _sendMessage(String myUid) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Send message using chat service
    ref.read(chatServiceProvider).sendMessage(
          senderId: myUid,
          receiverId: widget.otherUser.uid,
          text: text,
        );
    _messageController.clear();
  }

  // Quick reaction emojis
  static const List<String> _quickEmojis = ['👍', '❤️', '😂', '😮', '😢'];

  // Show options when message is long pressed
  void _showMessageOptions(MessageModel msg, bool isMe, String myUid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),

              // Reaction emoji row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _quickEmojis.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      // Toggle reaction on this message
                      ref.read(chatServiceProvider).toggleReaction(
                            uid1: myUid,
                            uid2: widget.otherUser.uid,
                            messageId: msg.id,
                            userId: myUid,
                            emoji: emoji,
                          );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),

              // Edit option — only for own messages
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: _primary),
                  title: const Text('Edit Message'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _editMessage(msg, myUid);
                  },
                ),

              // Delete option — only for own messages
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete Message',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(chatServiceProvider).deleteMessage(
                          uid1: myUid,
                          uid2: widget.otherUser.uid,
                          messageId: msg.id,
                        );
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // Open edit dialog and update message text
  void _editMessage(MessageModel msg, String myUid) {
    final editController = TextEditingController(text: msg.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          autofocus: true,
          maxLines: 4,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty) {
                // Update message in Firestore
                ref.read(chatServiceProvider).editMessage(
                      uid1: myUid,
                      uid2: widget.otherUser.uid,
                      messageId: msg.id,
                      newText: newText,
                    );
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(currentUidProvider)!;

    // Watch messages stream between current user and other user
    final messagesAsync = ref.watch(
      messagesProvider((uid1: myUid, uid2: widget.otherUser.uid)),
    );

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: _dark),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _primary,
              child: Text(
                widget.otherUser.name.isNotEmpty
                    ? widget.otherUser.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Text(widget.otherUser.name,
                style: const TextStyle(
                    color: _dark, fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: _primary)),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Say hi!',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
  final msg = messages[i];
  final isMe = msg.senderId == myUid;

  return GestureDetector(
    onLongPress: () => _showMessageOptions(msg, isMe, myUid), // ← long press
    child: Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(color: isMe ? Colors.white : _dark),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('hh:mm a').format(msg.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.grey.shade400,
                  ),
                ),
                // Show "edited" label if message was edited
                if (msg.isEdited) ...[
                  const SizedBox(width: 4),
                  Text(
                    '· edited',
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: isMe ? Colors.white70 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ],
            ),
            // Show reactions if any exist
            if (msg.reactions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 2,
                children: msg.reactions.values
                    .toSet() // unique emojis only
                    .map((emoji) => Text(emoji, style: const TextStyle(fontSize: 14)))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    ),
  );
},
                );
              },
            ),
          ),

          // Message input field
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: _primary,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: () => _sendMessage(myUid),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}