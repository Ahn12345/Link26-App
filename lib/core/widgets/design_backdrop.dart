import 'package:flutter/material.dart';

enum DesignFit {
  screenCover,
  widthScroll,
  containLetterbox,
}

/// 목업 이미지 한 장으로 탭을 채우거나, [child] 가 있으면 배경 이미지 + 위에 콘텐츠를 겹칩니다.
class DesignBackdrop extends StatelessWidget {
  const DesignBackdrop({
    super.key,
    required this.assetPath,
    this.fit = DesignFit.screenCover,
    this.alignment = Alignment.topCenter,
    this.child,
    this.backgroundOpacity = 1.0,
  });

  final String assetPath;
  final DesignFit fit;
  final Alignment alignment;

  /// 배경 위에 올릴 위젯(홈 대시보드 등). null 이면 이미지만 전체 화면.
  final Widget? child;

  /// 배경 이미지 불투명도. [child] 가 있을 때만 적용(목업 전용 탭은 항상 1.0).
  final double backgroundOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.maybeOf(context);
    final int? cacheW;
    final int? cacheH;
    if (mq != null) {
      final dpr = mq.devicePixelRatio;
      cacheW = (mq.size.width * dpr).round().clamp(1, 4096);
      cacheH = (mq.size.height * dpr).round().clamp(1, 4096);
    } else {
      cacheW = null;
      cacheH = null;
    }

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

    if (child != null) {
      final o = backgroundOpacity.clamp(0.0, 1.0);
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: o,
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                alignment: alignment,
                filterQuality: FilterQuality.medium,
                cacheWidth: cacheW,
                cacheHeight: cacheH,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: theme.scaffoldBackgroundColor,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '배경 이미지를 불러올 수 없습니다.\n\n$assetPath',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child!,
        ],
      );
    }

    switch (fit) {
      case DesignFit.screenCover:
        return Image.asset(
          assetPath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          alignment: alignment,
          filterQuality: FilterQuality.medium,
          cacheWidth: cacheW,
          cacheHeight: cacheH,
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
                filterQuality: FilterQuality.medium,
                cacheWidth: (w * MediaQuery.devicePixelRatioOf(context)).round().clamp(1, 4096),
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
                  filterQuality: FilterQuality.medium,
                  cacheWidth: (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                      .round()
                      .clamp(1, 4096),
                  cacheHeight: (constraints.maxHeight * MediaQuery.devicePixelRatioOf(context))
                      .round()
                      .clamp(1, 4096),
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
