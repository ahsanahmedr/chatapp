import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../models/pending_message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_options_sheet.dart';
import '../widgets/edit_message_dialog.dart';
import '../widgets/chat_input_bar.dart';
import '../services/notification_helper.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final UserModel otherUser;
  const ChatScreen({super.key, required this.otherUser});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  @override
void initState() {
  super.initState();
  log('DEBUG myUid: ${ref.read(currentUidProvider)}');
  log('DEBUG otherUser uid: ${widget.otherUser.uid}');
  log('DEBUG otherUser name: ${widget.otherUser.name}');
}
  MessageModel? _editingMessage;

  // Messages that haven't been confirmed in Firestore yet.
  final List<PendingMessage> _pendingMessages = [];

  static const _primary = Color.from(alpha: 1, red: 0.424, green: 0.278, blue: 1);
  static const _bg = Color(0xFFF4F5F9);
  static const _dark = Color(0xFF12132A);

Future<void> _sendMessage(String myUid) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
        final allUsers = ref.read(allUsersProvider).value ?? [];
    final currentUser = allUsers.firstWhere(
      (u) => u.uid == myUid,
      
    );

    if (_editingMessage != null) {
      ref.read(chatServiceProvider).editMessage(
            uid1: myUid,
            uid2: widget.otherUser.uid,
            messageId: _editingMessage!.id,
            newText: text,
          );
      setState(() => _editingMessage = null);
      _messageController.clear();
      return;
    }

    _messageController.clear();

    final pending = PendingMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      timestamp: DateTime.now(),
    );
    setState(() => _pendingMessages.add(pending));
    _scrollToBottom();

    final result = await Connectivity().checkConnectivity();
    final hasInternet = !result.contains(ConnectivityResult.none);
    if (!hasInternet) {
      setState(() => pending.status = PendingStatus.failed);
      return;
    }

    try {
      await ref.read(chatServiceProvider).sendMessage(
            senderId: myUid,
            receiverId: widget.otherUser.uid,
            text: text,
          );
      setState(() => _pendingMessages.remove(pending));

      // ── NOTIFICATION YAHAN ADD HUI _______________
await NotificationHelper.sendPushNotification(
  receiverUid: widget.otherUser.uid,
  senderUid: myUid,
  senderName: currentUser.name,
  messageText: text,
);
log('DEBUG senderUid being sent: $myUid');
log('DEBUG receiverUid being sent: ${widget.otherUser.uid}');
      // ───────────────────────────────────

    } catch (_) {
      setState(() => pending.status = PendingStatus.failed);
    }
  }



  Future<void> _retryMessage(String myUid, PendingMessage pending) async {
    setState(() => pending.status = PendingStatus.sending);

    final result = await Connectivity().checkConnectivity();
    final hasInternet = !result.contains(ConnectivityResult.none);
    if (!hasInternet) {
      setState(() => pending.status = PendingStatus.failed);
      return;
    }

    try {
      await ref.read(chatServiceProvider).sendMessage(
            senderId: myUid,
            receiverId: widget.otherUser.uid,
            text: pending.text,
          );
      setState(() => _pendingMessages.remove(pending));
    } catch (_) {
      setState(() => pending.status = PendingStatus.failed);
    }
  }

  void _cancelEdit() {
    setState(() => _editingMessage = null);
    _messageController.clear();
  }

// Pehli baar open ho to seedha bottom pe jump karo (no animation)

void _jumpToBottom() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  });
}

// Naya message aaye to smooth scroll
void _scrollToBottom() {
  if (!_scrollController.hasClients) return;
  
  final pos = _scrollController.position;
  final isNearBottom = pos.maxScrollExtent - pos.pixels < 150;
  
  if (isNearBottom) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 1),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  final myUid = ref.watch(currentUidProvider);
  
  // Auth load hone tak wait karo
  if (myUid == null) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
final messagesAsync = ref.watch(
  messagesProvider((uid1: myUid, uid2: widget.otherUser.uid)),
);
log('DEBUG uid1: $myUid');
log('DEBUG uid2: ${widget.otherUser.uid}');

    // Mark messages as seen whenever this conversation emits data — covers
    // both opening the chat and new messages arriving while it's open.
    ref.listen(
      messagesProvider((uid1: myUid, uid2: widget.otherUser.uid)),
      (previous, next) {
        next.whenData((_) {
          ref.read(chatServiceProvider).markMessagesAsSeen(
                uid1: myUid,
                uid2: widget.otherUser.uid,
                myUid: myUid,
              );
        });
      },
    );

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/home');
  }
},
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
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: _primary)),
              error: (err, stack) => Center(child: Text('Error: $err')),
             data: (messages) {
  if (_pendingMessages.isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _pendingMessages.removeWhere((pending) =>
            messages.any((m) =>
                m.senderId == myUid && m.text == pending.text));
      });
    });
  }

  // ✅ Messages load hone ke BAAD jump — no delay needed
  if (messages.isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

                if (messages.isEmpty && _pendingMessages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Say hi!',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                final itemCount = messages.length + _pendingMessages.length;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: itemCount,
                  itemBuilder: (_, i) {
                    // Confirmed Firestore messages first.
                    if (i < messages.length) {
                      final msg = messages[i];
                      final isMe = msg.senderId == myUid;
                      return MessageBubble(
                        text: msg.text,
                        timestamp: msg.timestamp,
                        isMe: isMe,
                        isEdited: msg.isEdited,
                        reactions: msg.reactions,
                        onLongPress: () => showMessageOptionsSheet(
                          context: context,
                          isMe: isMe,
                          onReact: (emoji) =>
                              ref.read(chatServiceProvider).toggleReaction(
                                    uid1: myUid,
                                    uid2: widget.otherUser.uid,
                                    messageId: msg.id,
                                    userId: myUid,
                                    emoji: emoji,
                                  ),
                          onEdit: () => showEditMessageDialog(
                            context: context,
                            initialText: msg.text,
                            onSave: (newText) =>
                                ref.read(chatServiceProvider).editMessage(
                                      uid1: myUid,
                                      uid2: widget.otherUser.uid,
                                      messageId: msg.id,
                                      newText: newText,
                                    ),
                          ),
                          onDelete: () =>
                              ref.read(chatServiceProvider).deleteMessage(
                                    uid1: myUid,
                                    uid2: widget.otherUser.uid,
                                    messageId: msg.id,
                                  ),
                        ),
                      );
                    }

                    // Locally pending (sending/failed) messages at the end.
                    final pending = _pendingMessages[i - messages.length];
                    return MessageBubble(
                      text: pending.text,
                      timestamp: pending.timestamp,
                      isMe: true,
                      status: pending.status == PendingStatus.sending
                          ? 'sending'
                          : 'failed',
                      onRetry: () => _retryMessage(myUid, pending),
                    );
                  },
                );
              },
            ),
          ),
          ChatInputBar(
            controller: _messageController,
            isEditing: _editingMessage != null,
            editingText: _editingMessage?.text,
            onSend: () => _sendMessage(myUid),
            onCancelEdit: _cancelEdit,
          ),
        ],
      ),
    );
  }
}
