import 'package:flutter/material.dart';

import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/navigation/link26_route_observer.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';
import 'package:link26_app/l10n/app_localizations.dart';

/// 선택: BFF `GET /v1/medications?connectedId=` 용 CODEF `connectedId` 저장.
/// 심평원「내가 먹는 약」실데이터는 틸코 간편인증 BFF 플로우로 가져오며 connectedId와 무관합니다.
class CodefConnectionScreen extends StatefulWidget {
  const CodefConnectionScreen({super.key});

  static const routeName = '/settings/codef-connection';

  @override
  State<CodefConnectionScreen> createState() => _CodefConnectionScreenState();
}

class _CodefConnectionScreenState extends State<CodefConnectionScreen>
    with WidgetsBindingObserver, RouteAware {
  final _controller = TextEditingController();
  bool _loading = true;
  String? _phoneDigits;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_onConnectedIdEdited);
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) {
      link26RouteObserver.subscribe(this, route);
    }
  }

  void _onConnectedIdEdited() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  /// 다른 화면을 push했다가 pop으로 돌아올 때 (앱은 계속 포그라운드일 수 있음).
  @override
  void didPopNext() {
    _load();
  }

  Future<void> _load() async {
    final user = await UserLocalRepository.loadSignedInUserRecord();
    if (!mounted) return;
    if (user == null || user.phoneDigits.length < 10) {
      setState(() {
        _loading = false;
        _phoneDigits = user?.phoneDigits;
      });
      return;
    }
    _controller.text = user.codefConnectedId ?? '';
    setState(() {
      _loading = false;
      _phoneDigits = user.phoneDigits;
    });
  }

  @override
  void dispose() {
    link26RouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onConnectedIdEdited);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final phone = _phoneDigits;
    if (phone == null || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsCodefConnectionPhoneRequired)),
      );
      return;
    }
    await UserLocalRepository.updateCodefConnectedId(
      phone,
      connectedId: _controller.text.trim().isEmpty ? null : _controller.text,
    );
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsCodefConnectionSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsCodefConnectionTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  l10n.settingsCodefConnectionSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _NhisSyncChecklistCard(
                  useMock: NhisRuntimeConfig.useMock,
                  baseUrl: NhisRuntimeConfig.baseUrl,
                  dotenvConnectedId:
                      NhisRuntimeConfig.codefConnectedIdForMedications,
                  fieldConnectedId: _controller.text.trim(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: l10n.settingsCodefConnectedIdLabel,
                    hintText: l10n.settingsCodefConnectionHint,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _save,
                  child: Text(l10n.save),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    _controller.clear();
                  },
                  child: Text(l10n.settingsCodefConnectionClear),
                ),
                const SizedBox(height: 20),
                Text(
                  'assets/env/dotenv 및 PC BFF .env 에서 NHIS_USE_MOCK=false, '
                  'NHIS_BASE_URL, TILKO_API_KEY·TILKO_API_HOST 를 맞춘 뒤 앱을 다시 빌드하세요. '
                  '실제 복약 목록은 로그인·가입 시 주민번호 입력 후 틸코 간편인증 → '
                  'BFF 심평원「내가 먹는 약」조회가 성공하면 채워집니다.\n\n'
                  '아래 connectedId 는 BFF가 예전 방식(CODEF GET 복약)을 쓸 때만 필요합니다. '
                  '그 경로를 쓰지 않으면 비워 두어도 됩니다.\n\n'
                  'apidemo.tilko.net 문서에 v2.0 이 보여도, 간편인증 복약 API는 '
                  '/api/v1.0/hirasimpleauth/hiraa050300000100 등 문서의 v1.0 경로를 따릅니다. '
                  '공동인증서용 /api/v1.0/Nhis/... 상품과는 다른 흐름입니다.\n\n'
                  '문제가 계속되면 NHIS_SHOW_SYNC_SNACKBARS=true 로 홈 동기화 안내를 켤 수 있습니다.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                        height: 1.45,
                      ),
                ),
              ],
            ),
    );
  }
}

class _NhisSyncChecklistCard extends StatelessWidget {
  const _NhisSyncChecklistCard({
    required this.useMock,
    required this.baseUrl,
    required this.dotenvConnectedId,
    required this.fieldConnectedId,
  });

  final bool useMock;
  final String baseUrl;
  final String? dotenvConnectedId;
  final String fieldConnectedId;

  @override
  Widget build(BuildContext context) {
    final baseOk = baseUrl.trim().isNotEmpty;
    final envCid = (dotenvConnectedId ?? '').trim();
    final fieldCid = fieldConnectedId.trim();
    final cidOk = envCid.isNotEmpty || fieldCid.isNotEmpty;
    final cidLine = cidOk
        ? 'connectedId: 설정됨 (레거시 CODEF GET 복약용 · 선택)'
        : 'connectedId: 없음 — 레거시 CODEF GET 복약만 쓸 때 입력(.env의 CODEF_CONNECTED_ID)';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BFF·복약 동기화 점검',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 10),
          _line(!useMock, 'NHIS_USE_MOCK 꺼짐 (실연동)'),
          _line(baseOk, 'NHIS_BASE_URL 설정됨: ${baseOk ? _short(baseUrl, 48) : '비어 있음'}'),
          _line(cidOk, cidLine),
          if (useMock)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '→ 지금은 목(mock) 모드일 수 있어 데모 복약만 옵니다. '
                '.env 에 NHIS_USE_MOCK=false',
                style: TextStyle(
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (!baseOk)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '→ BFF 주소가 비어 있으면 요청이 나가지 않습니다.',
                style: TextStyle(
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (!cidOk)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '→ 레거시 CODEF GET 복약만 쓸 때 connectedId 가 없으면 그 경로 조회가 막힐 수 있습니다.',
                style: TextStyle(
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _line(bool ok, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _short(String s, int max) {
    final t = s.trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max)}…';
  }
}
