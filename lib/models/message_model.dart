class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isEdited;
  final bool seen;
  final Map<String, String> reactions; // userId -> emoji

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isEdited = false,
    this.seen = false,
    this.reactions = const {},
  });

  factory MessageModel.fromMap(String id, Map<String, dynamic> data) {
    return MessageModel(
      id: id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
      isEdited: data['isEdited'] ?? false,
      seen: data['seen'] ?? false,
      reactions: Map<String, String>.from(data['reactions'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'isEdited': isEdited,
      'seen': seen,
      'reactions': reactions,
    };
  }
}