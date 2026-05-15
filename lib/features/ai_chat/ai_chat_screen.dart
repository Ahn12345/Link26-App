import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'package:link26_app/core/layout/link26_responsive_layout.dart';
import 'package:link26_app/core/layout/link26_responsive_ui_tokens.g.dart';
import 'package:link26_app/core/services/ai_chat_conversation_cache.dart';
import 'package:link26_app/core/services/ai_chat_home_alert_notifier.dart';
import 'package:link26_app/core/services/ai_chat_outgoing_busy.dart';
import 'package:link26_app/core/services/ai_chat_pending_attachment_store.dart';
import 'package:link26_app/core/services/ai_chat_session_store.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';
import 'package:link26_app/core/widgets/decoded_asset_image.dart';
import 'package:link26_app/core/widgets/link26_vector_icons.dart';
import 'package:link26_app/core/widgets/link26_dashboard_widgets.dart';
import 'package:link26_app/core/constants/app_build_fingerprint.dart';
import 'package:link26_app/core/constants/gemini_runtime_config.dart';
import 'package:link26_app/core/constants/image_assets.dart';
import 'package:link26_app/features/ai_chat/ai_chat_service.dart';
import 'package:link26_app/l10n/app_localizations.dart';
import 'package:link26_app/models/link_models.dart';

typedef _BytesMime = ({Uint8List bytes, String mime});

/// 로컬 DB에 base64 로 넣기 전에 용량을 줄입니다(초대형 사진 폭주 방지).
_BytesMime _prepareImageForChatHistory(Uint8List raw, String mime) {
  const maxBytes = 260000;
  final m = mime.trim().isNotEmpty ? mime.trim() : 'image/jpeg';
  if (raw.length <= maxBytes) {
    return (bytes: raw, mime: m);
  }
  try {
    final decoded = img.decodeImage(raw);
    if (decoded == null) {
      return (bytes: raw, mime: m);
    }
    var scaled =
        decoded.width > 960 ? img.copyResize(decoded, width: 960) : decoded;
    var out = Uint8List.fromList(img.encodeJpg(scaled, quality: 82));
    if (out.length > maxBytes) {
      scaled = img.copyResize(scaled, width: 640);
      out = Uint8List.fromList(img.encodeJpg(scaled, quality: 76));
    }
    return (bytes: out, mime: 'image/jpeg');
  } catch (_) {
    return (bytes: raw, mime: m);
  }
}

Future<void> _finalizeAiChatSuccess({
  required bool hasPendingImage,
  required String analyzingLabel,
  required String body,
  required String replyError,
  required String homeAlertTitle,
  required int dailyLimit,
}) async {
  if (hasPendingImage && AiChatConversationCache.messages.isNotEmpty) {
    final last = AiChatConversationCache.messages.last;
    if (!last.isUser && last.text == analyzingLabel) {
      AiChatConversationCache.messages.removeLast();
    }
  }
  final replyText = body.isEmpty ? replyError : body;
  AiChatConversationCache.messages.add(
    ChatMessage(
      isUser: false,
      time: AiChatSessionStore.formatAccessLabel(DateTime.now()),
      text: replyText,
    ),
  );
  if (AiChatConversationCache.dailyUsed < dailyLimit) {
    AiChatConversationCache.dailyUsed++;
  }
  await AiChatConversationCache.persist();
  if (hasPendingImage) {
    await AiChatHomeAlertNotifier.instance.onNewAiChatImageReply(
      title: homeAlertTitle,
      previewText: replyText,
    );
  }
}

Future<void> _finalizeAiChatFailure({
  required bool hasPendingImage,
  required String analyzingLabel,
  required String replyError,
  required String homeAlertTitle,
  required int dailyLimit,
}) async {
  if (hasPendingImage && AiChatConversationCache.messages.isNotEmpty) {
    final last = AiChatConversationCache.messages.last;
    if (!last.isUser && last.text == analyzingLabel) {
      AiChatConversationCache.messages.removeLast();
    }
  }
  AiChatConversationCache.messages.add(
    ChatMessage(
      isUser: false,
      time: AiChatSessionStore.formatAccessLabel(DateTime.now()),
      text: replyError,
    ),
  );
  if (AiChatConversationCache.dailyUsed < dailyLimit) {
    AiChatConversationCache.dailyUsed++;
  }
  await AiChatConversationCache.persist();
  if (hasPendingImage) {
    await AiChatHomeAlertNotifier.instance.onNewAiChatImageReply(
      title: homeAlertTitle,
      previewText: replyError,
    );
  }
}

/// AI 약 정보 채팅 — 색·타이포는 [Link26Surface]·디자인 토큰(`accent` #0046AD) 기준.
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
      resizeToAvoidBottomInset: true,
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

  @override
  void initState() {
    super.initState();
    AiChatPendingAttachmentStore.instance.addListener(_onGlobalChatUiChanged);
    AiChatOutgoingBusy.instance.addListener(_onGlobalChatUiChanged);
    AiChatConversationCache.revision.addListener(_onGlobalChatUiChanged);
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

  void _onGlobalChatUiChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AiChatPendingAttachmentStore.instance.removeListener(_onGlobalChatUiChanged);
    AiChatOutgoingBusy.instance.removeListener(_onGlobalChatUiChanged);
    AiChatConversationCache.revision.removeListener(_onGlobalChatUiChanged);
    controller.dispose();
    super.dispose();
  }

  Future<void> _confirmAndResetDeviceQuota() async {
    final l10n = AppLocalizations.of(context);
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiChatResetQuotaTitle),
        content: SingleChildScrollView(
          child: Text(l10n.aiChatResetQuotaMessage),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.aiChatResetQuotaCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.aiChatResetQuotaConfirm),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    await AiChatConversationCache.resetDeviceDailyQuota();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.aiChatResetQuotaDone)),
    );
  }

  Future<void> sendMessage() async {
    final l10n = AppLocalizations.of(context);
    final text = controller.text.trim();
    if (AiChatOutgoingBusy.instance.value) return;

    final attach = AiChatPendingAttachmentStore.instance;
    final pendingBytes = attach.bytes;
    final pendingMime = attach.mime;
    final hasPendingImage =
        pendingBytes != null && pendingBytes.isNotEmpty && (pendingMime ?? '').isNotEmpty;

    if (text.isEmpty && !hasPendingImage) return;
    if (hasPendingImage && text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiChatImageNeedText)),
      );
      return;
    }

    if (AiChatConversationCache.dailyUsed >= _dailyLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiChatDailyLimitReached)),
      );
      return;
    }

    final homeAlertTitle = l10n.homeAiChatImageReplyTitle;
    final analyzingLabel = l10n.aiChatImageAnalyzing;
    final replyError = GeminiRuntimeConfig.isConfigured
        ? l10n.aiChatReplyError
        : l10n.aiChatGeminiKeyMissing;

    String? userImageB64;
    String? userImageMime;
    if (hasPendingImage && pendingBytes.isNotEmpty) {
      final packed = _prepareImageForChatHistory(
        pendingBytes,
        pendingMime ?? 'image/jpeg',
      );
      userImageB64 = base64Encode(packed.bytes);
      userImageMime = packed.mime;
    }

    setState(() {
      AiChatConversationCache.messages.add(
        ChatMessage(
          isUser: true,
          time: _nowLabel(),
          text: text,
          imageBase64: userImageB64,
          imageMime: userImageMime,
        ),
      );
      if (hasPendingImage) {
        AiChatConversationCache.messages.add(
          ChatMessage(
            isUser: false,
            time: _nowLabel(),
            text: analyzingLabel,
          ),
        );
      }
    });
    attach.clear();
    controller.clear();
    await AiChatConversationCache.persist();

    AiChatOutgoingBusy.instance.value = true;
    try {
      final body = (await AiChatService().respondChat(
        text,
        imageBytes: hasPendingImage ? pendingBytes : null,
        imageMime: hasPendingImage ? pendingMime : null,
      ))
          .trim();
      await _finalizeAiChatSuccess(
        hasPendingImage: hasPendingImage,
        analyzingLabel: analyzingLabel,
        body: body,
        replyError: replyError,
        homeAlertTitle: homeAlertTitle,
        dailyLimit: _dailyLimit,
      );
    } catch (_) {
      await _finalizeAiChatFailure(
        hasPendingImage: hasPendingImage,
        analyzingLabel: analyzingLabel,
        replyError: replyError,
        homeAlertTitle: homeAlertTitle,
        dailyLimit: _dailyLimit,
      );
    } finally {
      AiChatOutgoingBusy.instance.value = false;
      if (mounted) setState(() {});
    }
  }

  String _mimeFromImagePath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  /// 갤러리에서 이미지를 고릅니다. 분석은 텍스트 입력 후 전송 시 실행됩니다.
  Future<void> openMedicineImagePicker() async {
    final l10n = AppLocalizations.of(context);
    if (AiChatOutgoingBusy.instance.value) return;
    if (AiChatConversationCache.dailyUsed >= _dailyLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiChatDailyLimitReached)),
      );
      return;
    }

    final picker = ImagePicker();
    XFile? file;
    try {
      file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiChatImageOpenFailed)),
      );
      return;
    }
    if (!mounted || file == null) return;

    late Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiChatImageReadFailed)),
      );
      return;
    }

    final mime = _mimeFromImagePath(file.path);
    if (!mounted) return;
    AiChatPendingAttachmentStore.instance.setAttachment(bytes, mime);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.aiChatImagePendingSnack)),
    );
  }

  String _nowLabel() =>
      AiChatSessionStore.formatAccessLabel(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final embedded = widget.embeddedInShell;
    final keyboardLift = MediaQuery.viewInsetsOf(context).bottom;
    // 하단 탭: [extendBody] 이라 본문이 내비 뒤까지 깔림. bottom padding 이 클수록 입력 카드가 **위로** 올라감.
    // 키보드가 올라오면 아래에 `keyboardLift` 를 또 더하므로, 탭바용 패딩은 줄여 Column 오버플로를 막습니다.
    final shellNavPad = embedded
        ? MediaQuery.viewPaddingOf(context).bottom +
            (keyboardLift > 0 ? 40.0 : 118.0)
        : 0.0;
    final inputEnabled = !AiChatOutgoingBusy.instance.value &&
        AiChatConversationCache.dailyUsed < _dailyLimit;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final sideScreen = Link26Layout.horizontalPadding(w);
        final inner = Link26Layout.innerWidth(w);
        final bubbleMax = Link26Layout.chatBubbleMaxWidth(inner);

        return SafeArea(
          bottom: !embedded,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: shellNavPad + keyboardLift,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: sideScreen),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: Link26Layout.innerWidth(w),
                            ),
                            child: _ChatHeader(
                              title: l10n.aiChatBrandTitle,
                              quotaHint: l10n.aiChatQuotaResetHint,
                              used: AiChatConversationCache.dailyUsed,
                              limit: _dailyLimit,
                              embedded: embedded,
                              horizontalPad: 0,
                              layoutWidth: w,
                              onResetDeviceQuota:
                                  AiChatConversationCache.dailyUsed >=
                                          _dailyLimit
                                      ? () => unawaited(
                                            _confirmAndResetDeviceQuota(),
                                          )
                                      : null,
                            ),
                          ),
                        ),
                        SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                        if (!GeminiRuntimeConfig.isConfigured)
                          Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: Link26Layout.innerWidth(w),
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: Link26ResponsiveUi.gapSm(w),
                                ),
                                child: _GeminiSetupBanner(text: l10n.aiChatGeminiKeyMissing),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: Link26Layout.innerWidth(w),
                              ),
                              child: ColoredBox(
                                color: Link26UnifiedPage.background,
                                child: LayoutBuilder(
                                  builder: (context, vp) {
                                    final scrollPadBottom =
                                        Link26ResponsiveUi.gapSm(w);
                                    final minScrollBody =
                                        vp.maxHeight - scrollPadBottom;
                                    return SingleChildScrollView(
                                      padding: EdgeInsets.fromLTRB(
                                        0,
                                        0,
                                        0,
                                        scrollPadBottom,
                                      ),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: minScrollBody > 0
                                              ? minScrollBody
                                              : vp.maxHeight,
                                        ),
                                        child: ValueListenableBuilder<int>(
                                          valueListenable:
                                              AiChatConversationCache.revision,
                                          builder: (context, rev, _) {
                                            assert(rev >= 0);
                                            return Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                _AiWelcomeBubble(
                                                  timeLabel:
                                                      _welcomeAccessLabel ??
                                                          '…',
                                                  maxBubbleWidth: bubbleMax,
                                                  layoutWidth: w,
                                                ),
                                                ...AiChatConversationCache
                                                    .messages
                                                    .map(
                                                  (m) => Padding(
                                                    padding: EdgeInsets.only(
                                                      top: Link26ResponsiveUi
                                                          .gapMd(w),
                                                    ),
                                                    child: _ChatBubble(
                                                      message: m,
                                                      maxBubbleWidth:
                                                          bubbleMax,
                                                      layoutWidth: w,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: SingleChildScrollView(
                              clipBehavior: Clip.none,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.manual,
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: Link26Layout.innerWidth(w),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                _DisclaimerBanner(
                                  text: l10n.aiChatDisclaimerShort,
                                  layoutWidth: w,
                                ),
                                if (kDebugMode) ...[
                                  SizedBox(height: Link26ResponsiveUi.gapXs(w)),
                                  Text(
                                    '빌드 $kAppBuildNumber · $kAppBuildTag',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Link26Surface.textSecondary,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                                SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                                Transform.translate(
                                  offset: Offset(
                                    0,
                                    keyboardLift > 0
                                        ? 0.0
                                        : (embedded ? -10.0 : -6.0),
                                  ),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        Link26UnifiedPage.frameRadius,
                                      ),
                                      border: Border.all(
                                        color: Link26Surface.outline,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Link26Surface.cardShadow,
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        Link26ResponsiveUi.gapSm(w)
                                            .clamp(8.0, 14.0),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (AiChatPendingAttachmentStore
                                              .instance.hasPending)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                bottom:
                                                    Link26ResponsiveUi.gapSm(w),
                                              ),
                                              child: _PendingAttachmentChip(
                                                label: l10n
                                                    .aiChatImagePendingHint,
                                                compact: keyboardLift > 0,
                                                previewBytes:
                                                    AiChatPendingAttachmentStore
                                                        .instance.bytes,
                                                onRemove: AiChatOutgoingBusy
                                                        .instance.value
                                                    ? null
                                                    : () =>
                                                        AiChatPendingAttachmentStore
                                                            .instance.clear(),
                                              ),
                                            ),
                                          _InputBar(
                                            controller: controller,
                                            layoutWidth: w,
                                            attachTooltip: l10n
                                                .aiChatAttachGalleryTooltip,
                                            enabled: inputEnabled,
                                            sending: AiChatOutgoingBusy
                                                .instance.value,
                                            hintText:
                                                l10n.aiChatInputPlaceholder,
                                            onSend: () =>
                                                unawaited(sendMessage()),
                                            onAttachImage: () => unawaited(
                                                openMedicineImagePicker()),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!embedded)
                Positioned(
                  top: 4,
                  left: sideScreen.clamp(4.0, double.infinity),
                  child: IconButton(
                    style: IconButton.styleFrom(
                        foregroundColor: Link26Surface.textPrimary),
                    icon: Link26VectorIcons.chevronBack(
                      Link26Surface.textPrimary,
                      size: 20,
                    ),
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
    this.onResetDeviceQuota,
  });

  final String title;
  final String quotaHint;
  final int used;
  final int limit;
  final bool embedded;
  final double horizontalPad;
  final double layoutWidth;
  final VoidCallback? onResetDeviceQuota;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = limit > 0 ? used / limit : 0.0;
    final leftPad = horizontalPad + (embedded ? 0 : 40);
    final w = layoutWidth;
    final padV = Link26ResponsiveUi.chatHeaderPadV(w);
    final atLimit = used >= limit && limit > 0;

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
            if (atLimit && onResetDeviceQuota != null) ...[
              SizedBox(height: Link26ResponsiveUi.gapSm(w)),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onResetDeviceQuota,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Link26Surface.accent,
                    side: const BorderSide(color: Link26Surface.accent),
                    padding: EdgeInsets.symmetric(
                      vertical: Link26ResponsiveUi.gapSm(w),
                      horizontal: Link26ResponsiveUi.gapMd(w),
                    ),
                  ),
                  child: Text(
                    l10n.aiChatResetQuotaButton,
                    style: TextStyle(
                      fontSize: Link26ResponsiveUi.chatHint(w),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
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
    required this.layoutWidth,
  });

  final String timeLabel;
  final double maxBubbleWidth;
  final double layoutWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final w = layoutWidth;
    final bodyPx = Link26ResponsiveUi.body(w);
    final pad = Link26ResponsiveUi.gapMd(w).clamp(14.0, 22.0);
    final timePx = Link26ResponsiveUi.bodySmall(w);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxBubbleWidth,
        ),
        padding: EdgeInsets.all(pad),
        decoration: link26ElevatedCardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Link26Surface.textPrimary,
                  fontSize: bodyPx,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(text: l10n.aiChatWelcomeIntro),
                  TextSpan(text: l10n.aiChatWelcomeUploadHint),
                  TextSpan(text: l10n.aiChatWelcomeTipEmoji),
                  TextSpan(
                    text: l10n.aiChatWelcomeTipTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: bodyPx,
                      color: Link26Surface.accent,
                    ),
                  ),
                  const TextSpan(text: '\n'),
                  TextSpan(text: l10n.aiChatWelcomeTipList),
                ],
              ),
            ),
            SizedBox(height: Link26ResponsiveUi.gapSm(w)),
            Text(
              timeLabel,
              style: TextStyle(
                fontSize: timePx,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeminiSetupBanner extends StatelessWidget {
  const _GeminiSetupBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC107)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Link26VectorIcons.lock(Colors.amber.shade900, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Colors.brown.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner({
    required this.text,
    required this.layoutWidth,
  });

  final String text;
  final double layoutWidth;

  @override
  Widget build(BuildContext context) {
    final w = layoutWidth;
    final fontPx = Link26ResponsiveUi.bodySmall(w);
    final iconPx = (fontPx * 1.35).clamp(20.0, 26.0);
    final pad = Link26ResponsiveUi.gapMd(w).clamp(12.0, 18.0);
    final radius = (14.0 + w / 900).clamp(14.0, 20.0);
    return Padding(
      padding: EdgeInsets.only(bottom: Link26ResponsiveUi.gapSm(w)),
      child: Container(
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: Link26Surface.chipTint,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Link26Surface.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Link26VectorIcons.info(
              Link26Surface.accent,
              size: iconPx,
            ),
            SizedBox(width: Link26ResponsiveUi.gapSm(w)),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: fontPx,
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

/// 첨부 이미지가 전송 대기 중일 때 입력창 위에 표시합니다.
class _PendingAttachmentChip extends StatelessWidget {
  const _PendingAttachmentChip({
    required this.label,
    required this.onRemove,
    this.previewBytes,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onRemove;
  final Uint8List? previewBytes;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final softOutline = Link26Surface.outline.withValues(alpha: 0.45);
    final hasPreview = previewBytes != null && previewBytes!.isNotEmpty;
    final thumb = compact ? 40.0 : 52.0;
    final hPad = compact ? 8.0 : 12.0;
    final vPad = compact ? 6.0 : 8.0;
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: softOutline),
        ),
        child: Row(
          children: [
            if (hasPreview) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  previewBytes!,
                  width: thumb,
                  height: thumb,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stackTrace) =>
                      DecodedAssetImage(
                        ImageAssets.applogo,
                        width: thumb,
                        height: thumb,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(8),
                      ),
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
            ] else ...[
              Link26VectorIcons.paperclip(
                Link26Surface.accent,
                size: compact ? 18 : 20,
              ),
              SizedBox(width: compact ? 6 : 8),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Link26Surface.textPrimary,
                ),
              ),
            ),
            if (onRemove != null)
              IconButton(
                onPressed: onRemove,
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                icon: Link26VectorIcons.xMark(
                  Link26Surface.textSecondary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
    required this.layoutWidth,
    required this.attachTooltip,
    required this.enabled,
    required this.sending,
    required this.hintText,
    required this.onSend,
    required this.onAttachImage,
  });

  final TextEditingController controller;
  final double layoutWidth;
  final String attachTooltip;
  final bool enabled;
  final bool sending;
  final String hintText;
  final VoidCallback onSend;
  final VoidCallback onAttachImage;

  @override
  Widget build(BuildContext context) {
    final canAct = enabled && !sending;
    final softOutline = Link26Surface.outline.withValues(alpha: 0.45);
    final w = layoutWidth;
    final hintPx = Link26ResponsiveUi.bodySmall(w);
    final fieldPadH = Link26ResponsiveUi.gapMd(w).clamp(14.0, 20.0);
    final fieldPadV = (hintPx * 0.75).clamp(10.0, 14.0);
    final borderR = (12.0 + w / 700).clamp(12.0, 18.0);
    final iconPx = (hintPx * 1.35).clamp(22.0, 30.0);
    final attachTap = (iconPx * 1.65).clamp(44.0, 52.0);
    final sendSize = (48.0 + (w / 500).clamp(0, 1) * 4).clamp(46.0, 54.0);
    final sendIconPx = (sendSize * 0.45).clamp(20.0, 26.0);
    final gapAttach = Link26ResponsiveUi.gapXs(w);
    final gapSend = Link26ResponsiveUi.gapSm(w);

    return Padding(
      padding: EdgeInsets.only(
        bottom: Link26ResponsiveUi.gapXs(w).clamp(2.0, 8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            onPressed: canAct ? onAttachImage : null,
            tooltip: attachTooltip,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: canAct
                  ? Link26Surface.textSecondary
                  : Link26Surface.textSecondary.withValues(alpha: 0.35),
              minimumSize: Size(attachTap, attachTap),
              padding: EdgeInsets.zero,
            ),
            icon: Icon(
              Icons.attach_file_rounded,
              size: iconPx,
              color: canAct
                  ? Link26Surface.textSecondary
                  : Link26Surface.textSecondary.withValues(alpha: 0.35),
            ),
          ),
          SizedBox(width: gapAttach),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: canAct,
              minLines: 1,
              maxLines: 5,
              scrollPhysics: const BouncingScrollPhysics(),
              style: TextStyle(
                fontSize: Link26ResponsiveUi.body(w),
                color: Link26Surface.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: hintPx,
                ),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: fieldPadH,
                  vertical: fieldPadV,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderR),
                  borderSide: BorderSide(color: softOutline, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderR),
                  borderSide: const BorderSide(
                    color: Link26Surface.accent,
                    width: 1.5,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(borderR),
                  borderSide: BorderSide(color: softOutline, width: 1),
                ),
              ),
            ),
          ),
          SizedBox(width: gapSend),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canAct ? onSend : null,
              customBorder: const CircleBorder(),
              child: Ink(
                width: sendSize,
                height: sendSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: canAct
                      ? Link26Surface.accent
                      : Link26Surface.accent.withValues(alpha: 0.4),
                ),
                child: sending
                    ? Padding(
                        padding: EdgeInsets.all(sendSize * 0.22),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Center(
                        child: Link26VectorIcons.send(
                          Colors.white,
                          size: sendIconPx * 1.35,
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

/// 말풍선에 저장된 base64 이미지 — [build] 마다 디코드하지 않도록 한 번만 풉니다.
class _BubbleInlineImage extends StatefulWidget {
  const _BubbleInlineImage({
    required this.base64,
    required this.maxWidth,
  });

  final String base64;
  final double maxWidth;

  @override
  State<_BubbleInlineImage> createState() => _BubbleInlineImageState();
}

class _BubbleInlineImageState extends State<_BubbleInlineImage> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    try {
      _bytes = base64Decode(widget.base64);
    } catch (_) {
      _bytes = null;
    }
  }

  @override
  void didUpdateWidget(covariant _BubbleInlineImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.base64 != widget.base64) {
      try {
        _bytes = base64Decode(widget.base64);
      } catch (_) {
        _bytes = null;
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _bytes;
    if (b == null || b.isEmpty) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth.clamp(40, 900),
          maxHeight: 260,
        ),
        child: Image.memory(
          b,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.maxBubbleWidth,
    required this.layoutWidth,
  });

  final ChatMessage message;
  final double maxBubbleWidth;
  final double layoutWidth;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bg = isUser ? Link26Surface.chipTint : Colors.white;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final w = layoutWidth;
    final bodyPx = Link26ResponsiveUi.body(w);
    final pad = Link26ResponsiveUi.gapMd(w).clamp(12.0, 18.0);
    final radius = (14.0 + w / 800).clamp(14.0, 20.0);
    final inlineImageB64 = message.imageBase64?.trim() ?? '';
    final hasInlineImage = inlineImageB64.isNotEmpty;

    return Align(
      alignment: align,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxBubbleWidth,
        ),
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Link26Surface.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasInlineImage) ...[
              _BubbleInlineImage(
                base64: inlineImageB64,
                maxWidth: maxBubbleWidth - pad * 2,
              ),
              if (message.text.trim().isNotEmpty)
                SizedBox(height: Link26ResponsiveUi.gapSm(w)),
            ],
            if (message.text.trim().isNotEmpty)
              Text(
                message.text,
                style: TextStyle(
                  fontSize: bodyPx,
                  height: 1.5,
                  color: Link26Surface.textPrimary,
                ),
              ),
            if (message.cardTitle != null) ...[
              SizedBox(height: Link26ResponsiveUi.gapSm(w)),
              Container(
                padding: EdgeInsets.all(Link26ResponsiveUi.gapMd(w).clamp(10.0, 16.0)),
                decoration: BoxDecoration(
                  color: Link26Surface.badgeTint,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: Link26Surface.outline),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Link26VectorIcons.capsule(
                      Link26Surface.accent,
                      size: (bodyPx * 1.2).clamp(20.0, 26.0),
                    ),
                    SizedBox(width: Link26ResponsiveUi.gapSm(w)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.cardTitle!,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: bodyPx,
                            ),
                          ),
                          SizedBox(height: Link26ResponsiveUi.gapXs(w)),
                          Text(
                            message.cardSubtitle ?? '',
                            style: TextStyle(
                              fontSize: Link26ResponsiveUi.bodySmall(w),
                              color: Link26Surface.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: Link26ResponsiveUi.gapSm(w)),
            Text(
              message.time,
              style: TextStyle(
                fontSize: Link26ResponsiveUi.bodySmall(w),
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
