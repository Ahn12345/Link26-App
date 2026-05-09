import 'package:flutter/material.dart';

import 'home_screen.dart';

/// 이전(영문 AppBar·히어로 이미지) 레이아웃 대신 목업과 동일한 대시보드를 씁니다.
/// 구버전 빌드·다른 진입 경로에서 [HomeLandingScreen] 을 열어도 우측 목 디자인과 맞습니다.
class HomeLandingScreen extends StatelessWidget {
  const HomeLandingScreen({super.key});

  @override
  Widget build(BuildContext context) => const HomeDashboardContent();
}
