import 'package:flutter/material.dart';

import 'package:link26_app/core/constants/image_assets.dart';
import 'package:link26_app/core/widgets/decoded_asset_image.dart';
import 'package:link26_app/features/auth/auth_welcome_screen.dart';

/// 네이티브 스플래시와 맞춘 배경색 + [ImageAssets.applogo] (런처 아이콘과 동일 에셋).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

  static const Color splashColor = Color(0xFFEEF4FA);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 한 프레임 그린 뒤 바로 환영 화면(불필요한 500ms 대기 제거).
    WidgetsBinding.instance.addPostFrameCallback((_) => _goNext());
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AuthWelcomeScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SplashScreen.splashColor,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            DecodedAssetImage(
              ImageAssets.applogo,
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
