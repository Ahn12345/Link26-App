import 'dart:async';

import 'package:flutter/material.dart';

import 'package:link26_app/core/constants/image_assets.dart';
import 'package:link26_app/core/layout/link26_responsive_image_tokens.g.dart';
import 'package:link26_app/core/layout/link26_responsive_layout.dart';
import 'package:link26_app/core/layout/link26_responsive_tokens.g.dart';
import 'package:link26_app/core/layout/link26_responsive_ui_tokens.g.dart';
import 'package:link26_app/core/services/ai_chat_conversation_cache.dart';
import 'package:link26_app/core/services/ai_chat_session_store.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';
import 'package:link26_app/core/widgets/decoded_asset_image.dart';
import 'package:link26_app/core/widgets/link26_dashboard_widgets.dart';
import 'package:link26_app/features/ai_chat/ai_chat_service.dart';
import 'package:link26_app/l10n/app_localizations.dart';
import 'package:link26_app/models/link_models.dart';

/// AI 약 정보 채팅 — 색·타이포는 [Link26Surface]·디자인 토큰(`accent` #0047AB) 기준.
///
/// [embeddedInShell]: 하단 탭일 때 뒤로가기 없음.
class AiChatScreen extends StatelessWidget {
  const AiChatScreen({
    super.key,
    this.showScaffold = true,
    this.embeddedInShell = false,
    /// 하단 탭에서 다른 탭 → AI 로 전환될 때마다 증가시키면 첫 말풍선 접속 시각이 갱신됩니다.
    this.visitStamp = 0,
  });

  static const routeName = '/ai-chat';

  final bool showScaffold;
  final bool embeddedInShell;

  /// [embeddedInShell] 일 때만 사용. 라우트 단독 진입은 0 그대로 두면 됩니다.
  final int visitStamp;

  @override
  Widget build(BuildContext context) {
    final body = _AiChatBody(
      embeddedInShell: embeddedInShell,
      visitStamp: visitStamp,
    );
    if (!showScaffold) {
      return ColoredBox(color: Link26UnifiedPage.background, child: body);
    }
    return Scaffold(
      backgroundColor: Link26UnifiedPage.background,
      body: body,
    );
  }
}

class _AiChatBody extends StatefulWidget {
  const _AiChatBody({
    required this.embeddedInShell,
    required this.visitStamp,
  });

  final bool embeddedInShell;
  final int visitStamp;

  @override
  State<_AiChatBody> createState() => _AiChatBodyState();
}

class _AiChatBodyState extends State<_AiChatBody> {
  final controller = TextEditingController();

  /// 첫 말풍선 하단 시각 — [AiChatSessionStore.touchAccess] 로 저장되는 접속 시각과 동일.
  String? _welcomeAccessLabel;

  static const int _dailyLimit = 10;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await AiChatConversationCache.ensureReady();
    if (!mounted) return;
    setState(() {});
    await _refreshWelcomeAccess();
  }

  Future<void> _refreshWelcomeAccess() async {
    final at = await AiChatSessionStore.touchAccess();
    if (!mounted) return;
    setState(() {
      _welcomeAccessLabel = AiChatSessionStore.formatAccessLabel(at);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final l10n = AppLocalizations.of(context);
    final text = controller.text.trim();
    if (text.isEmpty || _sending) return;
    if (AiChatConversationCache.dailyUsed >= _dailyLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiChatDailyLimitReached)),
      );
      return;
    }

    setState(() {
      AiChatConversationCache.messages.add(
        ChatMessage(isUser: true, time: _nowLabel(), text: text),
      );
      _sending = true;
    });
    controller.clear();
    await AiChatConversationCache.persist();

    try {
      final triage = await AiChatService().triageMessage(text);
      if (!mounted) return;
      final primary = triage.primaryAnswer.trim();
      final follow = triage.followUpPrompt.trim();
      final buf = StringBuffer();
      if (primary.isNotEmpty) buf.writeln(primary);
      if (follow.isNotEmpty) {
        if (buf.isNotEmpty) buf.writeln();
        buf.writeln(follow);
      }
      final body = buf.toString().trim();
      setState(() {
        AiChatConversationCache.messages.add(
          ChatMessage(
            isUser: false,
            time: _nowLabel(),
            text: body.isEmpty ? l10n.aiChatReplyError : body,
          ),
        );
        if (AiChatConversationCache.dailyUsed < _dailyLimit) {
          AiChatConversationCache.dailyUsed++;
        }
        _sending = false;
      });
      await AiChatConversationCache.persist();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        AiChatConversationCache.messages.add(
          ChatMessage(
            isUser: false,
            time: _nowLabel(),
            text: l10n.aiChatReplyError,
          ),
        );
        _sending = false;
      });
      await AiChatConversationCache.persist();
    }
  }

  Future<void> openCamera() async {
    final l10n = AppLocalizations.of(context);
    if (_sending) return;
    if (AiChatConversationCache.dailyUsed >= _dailyLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiChatDailyLimitReached)),
      );
      return;
    }
    setState(() {
      AiChatConversationCache.messages.add(
        ChatMessage(
          isUser: true,
          time: _nowLabel(),
          text: l10n.aiChatCameraUserMessage,
        ),
      );
      AiChatConversationCache.messages.add(
        ChatMessage(
          isUser: false,
          time: _nowLabel(),
          text: l10n.aiChatCameraReplyStub,
        ),
      );
      if (AiChatConversationCache.dailyUsed < _dailyLimit) {
        AiChatConversationCache.dailyUsed++;
      }
    });
    await AiChatConversationCache.persist();
  }

  String _nowLabel() =>
      AiChatSessionStore.formatAccessLabel(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final embedded = widget.embeddedInShell;
    final shellNavPad =
        embedded ? MediaQuery.of(context).padding.bottom + 88.0 : 0.0;
    final inputEnabled =
        !_sending && AiChatConversationCache.dailyUsed < _dailyLimit;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final sideScreen = Link26Layout.horizontalPadding(w);
        final inner = Link26Layout.innerWidth(w);
        final bubbleMax = Link26Layout.chatBubbleMaxWidth(inner);
        final aiArtH = Link26ResponsiveImageHeights.aiChat(w);
        final aiArtW = (Link26ResponsiveImageHeights.aiChatDisplayWidth(w)).clamp(0.0, inner);

        return SafeArea(
          bottom: true,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: shellNavPad),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: sideScreen),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: Link26ResponsiveTokens.contentMaxWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ChatHeader(
                            title: l10n.aiChatBrandTitle,
                            quotaHint: l10n.aiChatQuotaResetHint,
                            used: AiChatConversationCache.dailyUsed,
                            limit: _dailyLimit,
                            embedded: embedded,
                            horizontalPad: 0,
                            layoutWidth: w,
                          ),
                          SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                          Expanded(
                            child: ColoredBox(
                              color: Link26UnifiedPage.background,
                              child: ListView(
                                padding: EdgeInsets.fromLTRB(
                                  0,
                                  Link26ResponsiveUi.gapSm(w),
                                  0,
                                  Link26ResponsiveUi.gapSm(w),
                                ),
                                children: [
                                  Center(
                                    child: SizedBox(
                                      width: aiArtW,
                                      child: DecodedAssetImage(
                                        ImageAssets.aichat,
                                        height: aiArtH,
                                        fit: BoxFit.contain,
                                        borderRadius: BorderRadius.circular(Link26Surface.radiusInput),
                                        errorBuilder: (context, error, stackTrace) =>
                                            const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: Link26ResponsiveUi.heroArtToContent(w)),
                                  _AiWelcomeBubble(
                                    timeLabel: _welcomeAccessLabel ?? '…',
                                    maxBubbleWidth: bubbleMax,
                                  ),
                                  ...AiChatConversationCache.messages.map(
                                    (m) => Padding(
                                      padding: EdgeInsets.only(top: Link26ResponsiveUi.gapMd(w)),
                                      child: _ChatBubble(
                                        message: m,
                                        maxBubbleWidth: bubbleMax,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _DisclaimerBanner(text: l10n.aiChatDisclaimerShort),
                          _InputBar(
                            controller: controller,
                            enabled: inputEnabled,
                            sending: _sending,
                            hintText: l10n.aiChatInputPlaceholder,
                            onSend: () => unawaited(sendMessage()),
                            onCamera: () => unawaited(openCamera()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!embedded)
                Positioned(
                  top: 4,
                  left: sideScreen.clamp(4.0, double.infinity),
                  child: IconButton(
                    style: IconButton.styleFrom(foregroundColor: Link26Surface.textPrimary),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.quotaHint,
    required this.used,
    required this.limit,
    required this.embedded,
    required this.horizontalPad,
    required this.layoutWidth,
  });

  final String title;
  final String quotaHint;
  final int used;
  final int limit;
  final bool embedded;
  final double horizontalPad;
  final double layoutWidth;

  @override
  Widget build(BuildContext context) {
    final progress = limit > 0 ? used / limit : 0.0;
    final leftPad = horizontalPad + (embedded ? 0 : 40);
    final w = layoutWidth;
    final padV = Link26ResponsiveUi.chatHeaderPadV(w);

    return Container(
      decoration: link26ElevatedCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(leftPad, padV, horizontalPad + 8, padV),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: Link26ResponsiveUi.chatTitle(w),
                fontWeight: FontWeight.w900,
                color: Link26Surface.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: Link26ResponsiveUi.chatHeaderTitleGap(w)),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: Link26ResponsiveUi.progressBarHeight(w),
                      backgroundColor: Link26Surface.outline,
                      color: Link26Surface.accent,
                    ),
                  ),
                ),
                SizedBox(width: Link26ResponsiveUi.chatHeaderRowGap(w)),
                Text(
                  '$used/$limit',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: Link26ResponsiveUi.chatCounter(w),
                    color: Link26Surface.accent,
                  ),
                ),
              ],
            ),
            SizedBox(height: Link26ResponsiveUi.gapSm(w)),
            Text(
              quotaHint,
              style: TextStyle(
                fontSize: Link26ResponsiveUi.chatHint(w),
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 첫 AI 말풍선 — [timeLabel]은 접속 시각([AiChatSessionStore])과 동일 포맷.
class _AiWelcomeBubble extends StatelessWidget {
  const _AiWelcomeBubble({
    required this.timeLabel,
    required this.maxBubbleWidth,
  });

  final String timeLabel;
  final double maxBubbleWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxBubbleWidth,
        ),
        padding: const EdgeInsets.all(16),
        decoration: link26ElevatedCardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Link26Surface.textPrimary,
                  fontSize: 15,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(text: l10n.aiChatWelcomeIntro),
                  TextSpan(text: l10n.aiChatWelcomeUploadHint),
                  TextSpan(text: l10n.aiChatWelcomeTipEmoji),
                  TextSpan(
                    text: l10n.aiChatWelcomeTipTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Link26Surface.accent,
                    ),
                  ),
                  const TextSpan(text: '\n'),
                  TextSpan(text: l10n.aiChatWelcomeTipList),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              timeLabel,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Link26Surface.chipTint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Link26Surface.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: Link26Surface.accent,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Link26Surface.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.sending,
    required this.hintText,
    required this.onSend,
    required this.onCamera,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool sending;
  final String hintText;
  final VoidCallback onSend;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final canAct = enabled && !sending;
    final softOutline = Link26Surface.outline.withValues(alpha: 0.45);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            onPressed: canAct ? onCamera : null,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: canAct
                  ? Link26Surface.textSecondary
                  : Link26Surface.textSecondary.withValues(alpha: 0.35),
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.photo_camera_outlined, size: 26),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: canAct,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                ),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: softOutline, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Link26Surface.accent,
                    width: 1.5,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: softOutline, width: 1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canAct ? onSend : null,
              customBorder: const CircleBorder(),
              child: Ink(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: canAct
                      ? Link26Surface.accent
                      : Link26Surface.accent.withValues(alpha: 0.4),
                ),
                child: sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.maxBubbleWidth,
  });

  final ChatMessage message;
  final double maxBubbleWidth;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bg = isUser ? Link26Surface.chipTint : Colors.white;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: align,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxBubbleWidth,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Link26Surface.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Link26Surface.textPrimary,
              ),
            ),
            if (message.cardTitle != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Link26Surface.badgeTint,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Link26Surface.outline),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.medication_outlined, color: Link26Surface.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.cardTitle!,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(message.cardSubtitle ?? ''),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              message.time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
