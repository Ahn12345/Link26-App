import 'package:flutter/material.dart';

import 'package:link26_app/core/database/home_notification_repository.dart';
import 'package:link26_app/core/services/ai_chat_home_alert_notifier.dart';
import 'package:link26_app/core/services/main_shell_tab_bus.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';
import 'package:link26_app/core/widgets/link26_dashboard_widgets.dart';
import 'package:link26_app/l10n/app_localizations.dart';
import 'package:link26_app/models/alarm_item.dart';

/// 홈 종 아이콘 — AI 알림·복용(앱)·전화 복용 알림을 한곳에서 확인합니다.
class HomeNotificationCenterScreen extends StatefulWidget {
  const HomeNotificationCenterScreen({
    super.key,
    required this.doseAlarms,
    required this.onListsChanged,
  });

  final List<AlarmItem> doseAlarms;
  final VoidCallback onListsChanged;

  @override
  State<HomeNotificationCenterScreen> createState() =>
      _HomeNotificationCenterScreenState();
}

enum _NotifTab { all, ai, app, call }

class _HomeNotificationCenterScreenState
    extends State<HomeNotificationCenterScreen> {
  _NotifTab _tab = _NotifTab.all;
  List<HomeNotificationRow> _aiRows = [];

  @override
  void initState() {
    super.initState();
    HomeNotificationRepository.revision.addListener(_onRepo);
    _loadAi();
  }

  void _onRepo() {
    if (mounted) _loadAi();
  }

  @override
  void dispose() {
    HomeNotificationRepository.revision.removeListener(_onRepo);
    super.dispose();
  }

  Future<void> _loadAi() async {
    final list = await HomeNotificationRepository.listAiChat();
    if (mounted) setState(() => _aiRows = list);
  }

  String _timeLabel(int ms) {
    final t = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${t.month}/${t.day} ${t.hour}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final alarms = widget.doseAlarms;
    final appAlarms = alarms.where((a) => a.type == AlarmType.app).toList();
    final callAlarms = alarms.where((a) => a.type == AlarmType.call).toList();

    return Scaffold(
      backgroundColor: Link26UnifiedPage.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      foregroundColor: Link26Surface.textPrimary,
                      backgroundColor: Colors.white,
                      elevation: 1,
                      shadowColor: Colors.black.withValues(alpha: 0.06),
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                  Expanded(
                    child: Text(
                      l10n.homeNotificationCenterTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Link26Surface.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await HomeNotificationRepository.markAllAiChatRead();
                      await AiChatHomeAlertNotifier.instance
                          .refreshBannerFromDb();
                      await _loadAi();
                      widget.onListsChanged();
                    },
                    child: Text(
                      l10n.homeNotificationMarkAiRead,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip(l10n.homeNotificationTabAll, _NotifTab.all),
                    _chip(l10n.homeNotificationTabAi, _NotifTab.ai),
                    _chip(l10n.homeNotificationTabDose, _NotifTab.app),
                    _chip(l10n.homeNotificationTabCall, _NotifTab.call),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                children: _buildContent(l10n, appAlarms, callAlarms),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, _NotifTab tab) {
    final sel = _tab == tab;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: sel ? Colors.white : Link26Surface.textPrimary,
          ),
        ),
        selected: sel,
        onSelected: (_) => setState(() => _tab = tab),
        selectedColor: Link26Surface.accent,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Link26Surface.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        showCheckmark: false,
      ),
    );
  }

  List<Widget> _buildContent(
    AppLocalizations l10n,
    List<AlarmItem> appAlarms,
    List<AlarmItem> callAlarms,
  ) {
    switch (_tab) {
      case _NotifTab.all:
        return [
          _sectionTitle(l10n.homeNotificationSectionAi),
          ..._aiTiles(l10n),
          _sectionTitle(l10n.homeNotificationSectionDose),
          ..._alarmTiles(l10n, appAlarms, isCall: false),
          _sectionTitle(l10n.homeNotificationSectionCall),
          ..._alarmTiles(l10n, callAlarms, isCall: true),
        ];
      case _NotifTab.ai:
        return _aiTiles(l10n);
      case _NotifTab.app:
        return _alarmTiles(l10n, appAlarms, isCall: false);
      case _NotifTab.call:
        return _alarmTiles(l10n, callAlarms, isCall: true);
    }
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        t,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          color: Link26Surface.textMuted,
        ),
      ),
    );
  }

  List<Widget> _aiTiles(AppLocalizations l10n) {
    if (_aiRows.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Text(
            l10n.homeNotificationEmptyAi,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Link26Surface.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ];
    }
    return _aiRows.map((r) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Link26ElevatedCard(
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                await HomeNotificationRepository.markRead(r.id);
                await AiChatHomeAlertNotifier.instance.refreshBannerFromDb();
                await _loadAi();
                widget.onListsChanged();
                if (context.mounted) {
                  MainShellTabBus.goTo(1);
                  Navigator.pop(context);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: Icon(
                        Icons.smart_toy_outlined,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  r.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                _timeLabel(r.createdAtMs),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Link26Surface.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          if (!r.read) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Link26Surface.chipTint,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l10n.homeNotificationNewBadge,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Link26Surface.accent,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            r.preview,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              color: Link26Surface.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.homeAiChatImageReplyCta,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Link26Surface.accent,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _alarmTiles(
    AppLocalizations l10n,
    List<AlarmItem> items, {
    required bool isCall,
  }) {
    if (items.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            isCall
                ? l10n.homeNotificationEmptyCall
                : l10n.homeNotificationEmptyDose,
            style: const TextStyle(
              color: Link26Surface.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ];
    }
    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Link26ElevatedCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Link26Surface.chipTint,
                child: Icon(
                  isCall ? Icons.call_outlined : Icons.notifications_none_rounded,
                  color: Link26Surface.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.time,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Link26Surface.badgeTint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isCall
                                ? l10n.homeNotificationKindCall
                                : l10n.homeNotificationKindApp,
                            style: const TextStyle(
                              color: Link26Surface.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (item.completed) ...[
                          const SizedBox(width: 8),
                          Text(
                            l10n.homeNotificationDoseConfirmed,
                            style: const TextStyle(
                              color: Link26Surface.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.medicineName} ${item.dose}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Link26Surface.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Link26Surface.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!item.completed)
                FilledButton(
                  onPressed: () {
                    setState(() {
                      item.completed = true;
                      widget.onListsChanged();
                    });
                  },
                  style: Link26Surface.filledAccentButton(),
                  child: Text(
                    l10n.homeNotificationMarkDoseDone,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
