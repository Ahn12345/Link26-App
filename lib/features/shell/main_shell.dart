import 'package:flutter/material.dart';
import 'package:link26_app/core/services/main_shell_tab_bus.dart';
import 'package:link26_app/core/services/monthly_hira_auth_gate.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';
import 'package:link26_app/core/widgets/link26_vector_icons.dart';
import 'package:link26_app/l10n/app_localizations.dart';

import '../ai_chat/ai_chat_screen.dart';
import '../home/home_screen.dart';
import '../more/more_screen.dart';

/// 하단 탭: 홈 · AI 채팅 · 더보기.
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
    MainShellTabBus.bind((index) {
      if (!mounted) return;
      setState(() {
        final from = _index;
        _index = index.clamp(0, 2);
        if (_index == 1 && from != 1) {
          _aiVisitStamp++;
        }
      });
    });
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 홈 첫 프레임·입력 반응 이후에 다이얼로그 (ANR 체감 완화).
      Future<void>.delayed(const Duration(milliseconds: 200), () {
        if (mounted) MonthlyHiraAuthGate.maybeShow(context);
      });
    });
  }

  @override
  void dispose() {
    MainShellTabBus.unbind();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        if (mounted) MonthlyHiraAuthGate.maybeShow(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBody: true,
      backgroundColor: Link26UnifiedPage.background,
      // IndexedStack 은 숨긴 탭도 매 프레임 build → 에뮬에서 ANR. 현재 탭만 마운트.
      body: _ActiveTabBody(index: _index, aiVisitStamp: _aiVisitStamp),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            // 홈 시안(참조 #6): 선택 탭 = 연한 파란 pill + 채움 아이콘
            indicatorColor: Link26Surface.chipTint,
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
                  icon: Link26VectorIcons.home(
                    scheme.onSurfaceVariant,
                    size: 24,
                  ),
                  selectedIcon: Link26VectorIcons.home(
                    scheme.primary,
                    size: 24,
                  ),
                  label: l10n.homeTitle,
                ),
                NavigationDestination(
                  icon: Link26VectorIcons.chat(
                    scheme.onSurfaceVariant,
                    size: 24,
                  ),
                  selectedIcon: Link26VectorIcons.chat(
                    scheme.primary,
                    size: 24,
                  ),
                  label: l10n.aiChatTitle,
                ),
                NavigationDestination(
                  icon: Link26VectorIcons.more(
                    scheme.onSurfaceVariant,
                    size: 24,
                  ),
                  selectedIcon: Link26VectorIcons.more(
                    scheme.primary,
                    size: 24,
                  ),
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

class _ActiveTabBody extends StatelessWidget {
  const _ActiveTabBody({
    required this.index,
    required this.aiVisitStamp,
  });

  final int index;
  final int aiVisitStamp;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    switch (index) {
      case 0:
        child = const HomeDashboardContent();
        break;
      case 1:
        child = ColoredBox(
          color: Link26UnifiedPage.background,
          child: AiChatScreen(
            showScaffold: false,
            embeddedInShell: true,
            visitStamp: aiVisitStamp,
          ),
        );
        break;
      case 2:
        child = const MoreScreen(showScaffold: false);
        break;
      default:
        child = const HomeDashboardContent();
    }
    return KeyedSubtree(key: ValueKey<int>(index), child: child);
  }
}
