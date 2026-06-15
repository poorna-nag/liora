import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A chat bubble for a user or assistant message, with optional image.
class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? imagePath;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isUser
        ? AppColors.userBubble
        : (isDark ? AppColors.aiBubbleDark : AppColors.aiBubbleLight);
    final fg = isUser ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(imagePath!),
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (text.isNotEmpty)
              Text(text, style: TextStyle(color: fg, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
