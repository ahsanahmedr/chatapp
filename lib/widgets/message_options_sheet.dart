import 'package:flutter/material.dart';

const _primary = Color(0xFF6C47FF);
const _bg = Color(0xFFF4F5F9);
const List<String> quickEmojis = ['👍', '❤️', '😂', '😮', '😢'];

/// Long-press options sheet: quick reactions + edit/delete (for own messages).
void showMessageOptionsSheet({
  required BuildContext context,
  required bool isMe,
  required void Function(String emoji) onReact,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: quickEmojis.map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        onReact(emoji);
                      },
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              if (isMe)
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: _primary, size: 18),
                  ),
                  title: const Text('Edit Message',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onEdit();
                  },
                ),
              if (isMe)
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                  ),
                  title: const Text('Delete Message',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}