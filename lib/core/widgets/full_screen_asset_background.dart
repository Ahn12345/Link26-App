import 'package:flutter/material.dart';

/// 시안: 연한 블루 톤 베이스 + (있으면) PNG 한 장을 화면 전체에 덮고 [child]를 위에 올림.
class FullScreenAssetBackground extends StatelessWidget {
  const FullScreenAssetBackground({
    super.key,
    required this.assetPath,
    this.fallbackAssetPath,
    required this.child,
  });

  final String assetPath;
  final String? fallbackAssetPath;
  final Widget child;

  static const List<Color> _designBackdropGradient = [
    Color(0xFFE4EEF8),
    Color(0xFFEEF4FA),
    Color(0xFFF5F9FD),
  ];

  @override
  Widget build(BuildContext context) {
    Widget imageLayer(String path) => Image.asset(
          path,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          width: double.infinity,
          height: double.infinity,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) =>
              const SizedBox.shrink(),
        );

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _designBackdropGradient,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              final fb = fallbackAssetPath;
              if (fb != null && fb.isNotEmpty) {
                return imageLayer(fb);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        child,
      ],
    );
  }
}
