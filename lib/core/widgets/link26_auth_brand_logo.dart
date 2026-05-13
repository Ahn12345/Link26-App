import 'package:flutter/material.dart';

import 'package:link26_app/core/constants/image_assets.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/widgets/decoded_asset_image.dart';

/// 로그인·회원가입·환영 화면 상단 — 앱 스토어와 동일한 `applogo.png`만 사용합니다.
class Link26AuthBrandLogo extends StatelessWidget {
  const Link26AuthBrandLogo({
    super.key,
    required this.maxWidth,
    this.compact = false,
  });

  final double maxWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final factor = compact ? 0.36 : 0.34;
    final side = (maxWidth * factor).clamp(96.0, compact ? 128.0 : 148.0);
    return Center(
      child: SizedBox(
        width: side,
        height: side,
        child: DecodedAssetImage(
          ImageAssets.applogo,
          width: side,
          height: side,
          fit: BoxFit.contain,
          borderRadius: BorderRadius.circular(Link26Surface.radiusInput * 1.25),
        ),
      ),
    );
  }
}
