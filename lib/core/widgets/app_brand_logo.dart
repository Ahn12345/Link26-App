import 'package:flutter/material.dart';

/// Bundled brand mark: prefers [primaryAsset] (e.g. `logo2.png`), then [fallbackAsset].
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.primaryAsset = 'assets/images/logo2.png',
    this.fallbackAsset = 'assets/images/logo.png',
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final String primaryAsset;
  final String fallbackAsset;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconSize = width ?? height ?? 80;
    return Image.asset(
      primaryAsset,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('AppBrandLogo primary missing: $error');
        return Image.asset(
          fallbackAsset,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('AppBrandLogo fallback missing: $error');
            return Icon(
              Icons.link,
              size: iconSize,
              color: scheme.primary,
            );
          },
        );
      },
    );
  }
}
