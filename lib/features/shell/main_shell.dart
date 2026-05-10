import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import '../../core/constants/image_assets.dart';
import '../../core/services/monthly_hira_auth_gate.dart';
import '../../core/widgets/full_screen_asset_background.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../home/home_screen.dart';
import '../more/more_screen.dart';

/// 하단 탭: 홈(배경 + 대시보드) · AI 채팅 · 더보기.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const routeName = '/home';

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;
  /// AI 탭으로 전환할 때마다 증가 → 첫 말풍선 접속 시각 갱신.
  int _aiVisitStamp = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) MonthlyHiraAuthGate.maybeShow(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      MonthlyHiraAuthGate.maybeShow(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFEEF4FA),
      body: IndexedStack(
        index: _index,
        sizing: StackFit.expand,
        children: [
          FullScreenAssetBackground(
            assetPath: ImageAssets.homeTabBackground,
            fallbackAssetPath: null,
            child: const HomeDashboardContent(),
          ),
          AiChatScreen(
            showScaffold: false,
            embeddedInShell: true,
            visitStamp: _aiVisitStamp,
          ),
          FullScreenAssetBackground(
            assetPath: ImageAssets.setting,
            fallbackAssetPath: null,
            child: const MoreScreen(showScaffold: false),
          ),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            indicatorColor: scheme.primary.withValues(alpha: 0.14),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: scheme.primary,
                );
              }
              return TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              );
            }),
          ),
        ),
        child: Material(
          color: Colors.white,
          elevation: 12,
          shadowColor: Colors.black.withValues(alpha: 0.06),
          child: SafeArea(
            top: false,
            child: NavigationBar(
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              selectedIndex: _index,
              onDestinationSelected: (i) {
                setState(() {
                  final from = _index;
                  _index = i;
                  if (i == 1 && from != 1) {
                    _aiVisitStamp++;
                  }
                });
              },
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined, color: scheme.onSurfaceVariant),
                  selectedIcon: Icon(Icons.home, color: scheme.primary),
                  label: l10n.homeTitle,
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline, color: scheme.onSurfaceVariant),
                  selectedIcon: Icon(Icons.chat_bubble, color: scheme.primary),
                  label: l10n.aiChatTitle,
                ),
                NavigationDestination(
                  icon: Icon(Icons.more_horiz, color: scheme.onSurfaceVariant),
                  selectedIcon: Icon(Icons.more_horiz, color: scheme.primary),
                  label: l10n.moreTitle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
