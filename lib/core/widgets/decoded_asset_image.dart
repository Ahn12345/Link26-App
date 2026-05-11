import 'package:flutter/material.dart';

/// [Image.asset] with decode size capped to on-screen pixels (large PNG ANR 완화).
class DecodedAssetImage extends StatelessWidget {
  const DecodedAssetImage(
    this.assetName, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.errorBuilder,
  });

  final String assetName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final BorderRadius? borderRadius;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final size = MediaQuery.sizeOf(context);
    final int? cw = width != null
        ? (width! * dpr).round().clamp(1, 4096)
        : (height != null
            ? (size.width * dpr).round().clamp(1, 4096)
            : null);
    final int? ch = height != null
        ? (height! * dpr).round().clamp(1, 4096)
        : (width != null
            ? (size.height * dpr).round().clamp(1, 4096)
            : null);

    Widget img = Image.asset(
      assetName,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.medium,
      cacheWidth: cw,
      cacheHeight: ch,
      errorBuilder: errorBuilder ??
          (context, error, stackTrace) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: (width != null || height != null)
                      ? ((width ?? height ?? 24) * 0.35).clamp(18.0, 40.0)
                      : 28,
                  color: Colors.grey.shade500,
                ),
              ),
    );

    if (borderRadius != null) {
      img = ClipRRect(borderRadius: borderRadius!, child: img);
    }
    return img;
  }
}
