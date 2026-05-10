import 'package:flutter/material.dart';

import 'package:link26_app/core/constants/design_assets.dart';

/// 목업 이미지 한 장으로 탭 화면을 채웁니다. [DesignFit] 은 [design_assets.dart] 에 정의.
class DesignBackdrop extends StatelessWidget {
  const DesignBackdrop({
    super.key,
    required this.assetPath,
    this.fit = DesignFit.screenCover,
    this.alignment = Alignment.topCenter,
  });

  final String assetPath;
  final DesignFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget missing(String msg) => ColoredBox(
          color: theme.scaffoldBackgroundColor,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                msg,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );

    switch (fit) {
      case DesignFit.screenCover:
        return Image.asset(
          assetPath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          alignment: alignment,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) => missing(
            '이미지를 불러올 수 없습니다.\n\n$assetPath\n\n'
            '`assets/images/` 에 파일을 넣은 뒤 재실행 하세요.',
          ),
        );
      case DesignFit.widthScroll:
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Image.asset(
                assetPath,
                width: w,
                fit: BoxFit.fitWidth,
                alignment: alignment,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => missing(
                  '이미지를 불러올 수 없습니다.\n\n$assetPath',
                ),
              ),
            );
          },
        );
      case DesignFit.containLetterbox:
        return LayoutBuilder(
          builder: (context, constraints) {
            return ColoredBox(
              color: Colors.black,
              child: Center(
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  alignment: alignment,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => missing(
                    '이미지를 불러올 수 없습니다.\n\n$assetPath',
                  ),
                ),
              ),
            );
          },
        );
    }
  }
}
