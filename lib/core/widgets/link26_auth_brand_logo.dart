import 'package:flutter/material.dart';

import 'package:link26_app/core/constants/image_assets.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/widgets/decoded_asset_image.dart';

/// 로그인·회원가입·환영 화면 상단 브랜드 이미지.
/// 기본은 `applogo.png`; [assetPath]로 화면별 에셋을 바꿀 수 있습니다.
class Link26AuthBrandLogo extends StatelessWidget {
  const Link26AuthBrandLogo({
    super.key,
    required this.maxWidth,
    this.compact = false,
    this.assetPath,
  });

  final double maxWidth;
  final bool compact;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final factor = compact ? 0.36 : 0.34;
    final side = (maxWidth * factor).clamp(96.0, compact ? 128.0 : 148.0);
    final path = assetPath ?? ImageAssets.applogo;
    return Center(
      child: SizedBox(
        width: side,
        height: side,
        child: DecodedAssetImage(
          path,
          width: side,
          height: side,
          fit: BoxFit.contain,
          borderRadius: BorderRadius.circular(Link26Surface.radiusInput * 1.25),
        ),
      ),
    );
  }
}
