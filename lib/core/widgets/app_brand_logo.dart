import 'package:flutter/material.dart';

/// 앱 브랜드 마크(에셋 PNG 없이 Material 아이콘).
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.width,
    this.height,
    this.icon = Icons.link_rounded,
  });

  final double? width;
  final double? height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = width ?? height ?? 80;
    return Icon(
      icon,
      size: size,
      color: scheme.primary,
    );
  }
}
