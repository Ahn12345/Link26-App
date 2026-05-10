import 'package:flutter/material.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import '../../core/constants/design_assets.dart';
import '../../core/services/monthly_hira_auth_gate.dart';
import '../../core/widgets/full_screen_asset_background.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../home/home_screen.dart';
import '../more/more_screen.dart';

/// 하단 탭: 홈(배경 + 대시보드) · AI 채팅 · 더보기(실제 메뉴 UI).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const routeName = '/home';

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;

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
      backgroundColor: scheme.surface,
      body: IndexedStack(
        index: _index,
        sizing: StackFit.expand,
        children: [
          FullScreenAssetBackground(
            assetPath: DesignAssets.homeFullBackground,
            fallbackAssetPath: DesignAssets.homeBackground,
            child: const HomeDashboardContent(),
          ),
          const AiChatScreen(showScaffold: false, embeddedInShell: true),
          const MoreScreen(showScaffold: false),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            indicatorColor: scheme.primaryContainer.withValues(alpha: 0.65),
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
          color: scheme.surface,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          child: SafeArea(
            top: false,
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: l10n.homeTitle,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.chat_bubble_outline),
                  selectedIcon: const Icon(Icons.chat_bubble),
                  label: l10n.aiChatTitle,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.more_horiz),
                  selectedIcon: const Icon(Icons.more_horiz),
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
