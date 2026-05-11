import 'package:flutter/material.dart';

import '../constants/image_assets.dart';

/// [Image.asset] with decode size capped to on-screen pixels (large PNG ANR 완화).
///
/// 로드 실패 시 깨진 이미지·스택 대신 [ImageAssets.applogo]를 같은 크기·fit으로 표시하고,
/// 기본 로고까지 실패하면 작은 중립 아이콘만 보입니다.
class DecodedAssetImage extends StatelessWidget {
  const DecodedAssetImage(
    this.assetName, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.borderRadius,
  });

  final String assetName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final BorderRadius? borderRadius;

  (int?, int?) _decodeCacheSize(BuildContext context) {
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
    return (cw, ch);
  }

  Widget _neutralPlaceholder() {
    final double iconSize = (width != null || height != null)
        ? ((width ?? height ?? 24) * 0.35).clamp(18.0, 48.0)
        : 32.0;
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: iconSize,
        color: Colors.grey.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (cw, ch) = _decodeCacheSize(context);

    Widget img = Image.asset(
      assetName,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.medium,
      cacheWidth: cw,
      cacheHeight: ch,
      errorBuilder: (context, error, stackTrace) {
        if (assetName == ImageAssets.applogo) {
          return _neutralPlaceholder();
        }
        return Image.asset(
          ImageAssets.applogo,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          filterQuality: FilterQuality.medium,
          cacheWidth: cw,
          cacheHeight: ch,
          errorBuilder: (context, error, stackTrace) => _neutralPlaceholder(),
        );
      },
    );

    if (borderRadius != null) {
      img = ClipRRect(borderRadius: borderRadius!, child: img);
    }
    return img;
  }
}
