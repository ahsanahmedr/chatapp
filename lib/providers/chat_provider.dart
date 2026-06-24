import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/chat_preview_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate consistent chat room id from two user ids
  String getChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

  // Send a message
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final chatId = getChatId(senderId, receiverId);

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': Timestamp.now(),
      'isEdited': false,
      'seen': false,
    });

    // Update last message info for the home screen list + unread dot.
    // merge:true so we never wipe out other chat-doc fields.
    await _firestore.collection('chats').doc(chatId).set({
      'participants': [senderId, receiverId],
      'lastMessage': text,
      'lastTimestamp': Timestamp.now(),
      'lastSenderId': senderId,
      'lastSeen': false,
    }, SetOptions(merge: true));
  }

  // Get real-time messages stream between two users
  Stream<List<MessageModel>> getMessages(String uid1, String uid2) {
    final chatId = getChatId(uid1, uid2);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Real-time preview of a chat (last message + seen flag) — used on the
  // home screen so it doesn't have to stream every message per tile.
  Stream<ChatPreview> getChatPreview(String uid1, String uid2) {
    final chatId = getChatId(uid1, uid2);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) => ChatPreview.fromMap(doc.data()));
  }

  // Mark every message sent TO me in this conversation as seen.
  // Call when the chat screen opens, and whenever new messages arrive
  // while it's open.
  Future<void> markMessagesAsSeen({
    required String uid1,
    required String uid2,
    required String myUid,
  }) async {
    final chatId = getChatId(uid1, uid2);
    final chatRef = _firestore.collection('chats').doc(chatId);

    final unseen = await chatRef
        .collection('messages')
        .where('receiverId', isEqualTo: myUid)
        .where('seen', isEqualTo: false)
        .get();

    if (unseen.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unseen.docs) {
      batch.update(doc.reference, {'seen': true});
    }
    // Also flip the chat doc's flag so the home list's blue dot disappears
    // instantly without waiting on the messages subcollection.
    batch.update(chatRef, {'lastSeen': true});

    await batch.commit();
  }

  // Delete entire conversation including all messages
  Future<void> deleteChat(String uid1, String uid2) async {
    final chatId = getChatId(uid1, uid2);
    final chatRef = _firestore.collection('chats').doc(chatId);

    final messages = await chatRef.collection('messages').get();
    for (var doc in messages.docs) {
      await doc.reference.delete();
    }

    await chatRef.delete();
  }

  // Edit an existing message's text
  Future<void> editMessage({
    required String uid1,
    required String uid2,
    required String messageId,
    required String newText,
  }) async {
    final chatId = getChatId(uid1, uid2);
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': newText,
      'isEdited': true,
    });
  }

  // Delete a single message
  Future<void> deleteMessage({
    required String uid1,
    required String uid2,
    required String messageId,
  }) async {
    final chatId = getChatId(uid1, uid2);
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // Add or update a reaction on a message
  Future<void> toggleReaction({
    required String uid1,
    required String uid2,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    final chatId = getChatId(uid1, uid2);
    final msgRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    final doc = await msgRef.get();
    final currentReactions =
        Map<String, String>.from(doc.data()?['reactions'] ?? {});

    // If same emoji already set by this user, remove it (toggle off)
    if (currentReactions[userId] == emoji) {
      currentReactions.remove(userId);
    } else {
      currentReactions[userId] = emoji;
    }

    await msgRef.update({'reactions': currentReactions});
  }
}

// Chat service provider
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

// Messages stream provider — takes two user ids as parameter
final messagesProvider =
    StreamProvider.family<List<MessageModel>, ({String uid1, String uid2})>(
        (ref, ids) {
  return ref.watch(chatServiceProvider).getMessages(ids.uid1, ids.uid2);
});

// Chat preview (last message + seen flag) — used on the home screen list.
final chatPreviewProvider =
    StreamProvider.family<ChatPreview, ({String uid1, String uid2})>(
        (ref, ids) {
  return ref.watch(chatServiceProvider).getChatPreview(ids.uid1, ids.uid2);
});