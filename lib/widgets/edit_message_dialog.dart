import 'package:flutter/material.dart';

const _primary = Color(0xFF6C47FF);

/// Dialog to edit an existing message's text.
void showEditMessageDialog({
  required BuildContext context,
  required String initialText,
  required void Function(String newText) onSave,
}) {
  final editController = TextEditingController(text: initialText);
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
            if (newText.isNotEmpty) onSave(newText);
            Navigator.pop(ctx);
          },
          style: ElevatedButton.styleFrom(backgroundColor: _primary),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}