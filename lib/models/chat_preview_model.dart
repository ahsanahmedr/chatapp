import 'package:cloud_firestore/cloud_firestore.dart';

/// Snapshot of a chat's last message — powers the home screen's preview
/// line and the unread "blue dot", without streaming every single message
/// just to show a list tile.
class ChatPreview {
  final String? lastMessage;
  final DateTime? lastTimestamp;
  final String? lastSenderId;
  final bool lastSeen;

  ChatPreview({
    this.lastMessage,
    this.lastTimestamp,
    this.lastSenderId,
    this.lastSeen = true,
  });

  factory ChatPreview.fromMap(Map<String, dynamic>? data) {
    if (data == null) return ChatPreview();
    return ChatPreview(
      lastMessage: data['lastMessage'] as String?,
      lastTimestamp: (data['lastTimestamp'] as Timestamp?)?.toDate(),
      lastSenderId: data['lastSenderId'] as String?,
      lastSeen: data['lastSeen'] as bool? ?? true,
    );
  }
}