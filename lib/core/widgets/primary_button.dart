import 'package:flutter/material.dart';

/// ì£¼ìš” ?¡ì…˜??ë²„íŠ¼. ?”ë©´?¤ì—???¬ì‚¬?©í•©?ˆë‹¤.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(label),
            ],
          );

    return FilledButton(
      onPressed: onPressed,
      child: child,
    );
  }
}
