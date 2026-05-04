import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.text, this.incoming = true});

  final String text;
  final bool incoming;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = incoming ? scheme.surfaceContainerHighest : scheme.primaryContainer;
    final fg = incoming ? scheme.onSurface : scheme.onPrimaryContainer;
    return Align(
      alignment: incoming ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: TextStyle(color: fg)),
      ),
    );
  }
}
