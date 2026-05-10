import 'package:flutter/material.dart';

/// 에셋 이미지를 화면 전체에 깔고 [child]를 위에 올립니다. (중앙 작은 이미지 아님)
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget layer(String path) => Image.asset(
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
                return layer(fb);
              }
              return ColoredBox(color: theme.scaffoldBackgroundColor);
            },
          ),
        ),
        child,
      ],
    );
  }
}
