import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Single chat bubble. Works for real (Firestore) messages and for
/// locally pending messages (status == 'sending' / 'failed').
class MessageBubble extends StatelessWidget {
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final bool isEdited;
  final Map<String, String> reactions;
  final String? status; // null = sent normally, 'sending', 'failed'
  final VoidCallback? onLongPress;
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.isEdited = false,
    this.reactions = const {},
    this.status,
    this.onLongPress,
    this.onRetry,
  });

  static const _primary = Color(0xFF6C47FF);
  static const _dark = Color(0xFF12132A);

  @override
  Widget build(BuildContext context) {
    final isFailed = status == 'failed';
    final isSending = status == 'sending';

    return GestureDetector(
      onTap: isFailed ? onRetry : null,
      onLongPress: isFailed ? null : onLongPress,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              decoration: BoxDecoration(
                color: isFailed
                    ? Colors.red.shade50
                    : (isMe ? _primary : Colors.white),
                border:
                    isFailed ? Border.all(color: Colors.red.shade200) : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Opacity(
                    opacity: isSending ? 0.55 : 1,
                    child: Text(
                      text,
                      style: TextStyle(
                        color: isFailed
                            ? Colors.red.shade700
                            : (isMe ? Colors.white : _dark),
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isEdited) ...[
                        Text(
                          'edited',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontStyle: FontStyle.italic,
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      if (isSending)
                        Text(
                          'Sending...',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.grey.shade400,
                          ),
                        )
                      else if (isFailed)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                size: 12, color: Colors.red.shade700),
                            const SizedBox(width: 3),
                            Text(
                              'Not sent · tap to retry',
                              style: TextStyle(
                                  fontSize: 10.5, color: Colors.red.shade700),
                            ),
                          ],
                        )
                      else
                        Text(
                          DateFormat('hh:mm a').format(timestamp),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.grey.shade400,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (reactions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8, top: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: reactions.values
                      .toSet()
                      .map((emoji) =>
                          Text(emoji, style: const TextStyle(fontSize: 13)))
                      .toList(),
                ),
              )
            else
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}