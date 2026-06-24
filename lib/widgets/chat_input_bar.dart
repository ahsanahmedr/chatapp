import 'package:flutter/material.dart';

const _primary = Color(0xFF6C47FF);
const _bg = Color(0xFFF4F5F9);

/// Bottom text field + send button, plus an "editing" banner when active.
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isEditing;
  final String? editingText;
  final VoidCallback onSend;
  final VoidCallback onCancelEdit;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isEditing,
    required this.onSend,
    required this.onCancelEdit,
    this.editingText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isEditing)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: _primary.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(Icons.edit_rounded, size: 16, color: _primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Editing: ${editingText ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onCancelEdit,
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: _primary),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, -2)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: TextStyle(color: Color(0xFFB0B3C5)),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSend,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEditing ? Icons.check_rounded : Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}