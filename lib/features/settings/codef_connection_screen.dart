import 'package:flutter/material.dart';

import 'package:link26_app/core/database/user_local_repository.dart';
import 'package:link26_app/core/navigation/link26_route_observer.dart';
import 'package:link26_app/integrations/nhis/nhis_runtime_config.dart';
import 'package:link26_app/l10n/app_localizations.dart';

/// CODEF `connectedId` 저장 — BFF `/v1/medications` 쿼리로 전달됩니다.
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
                  'assets/env/dotenv 및 PC BFF .env 에서 '
                  'NHIS_USE_MOCK=false, NHIS_BASE_URL, CODEF_CONNECTED_ID 를 맞춘 뒤 '
                  '앱을 다시 빌드하거나, 위 입력란에 connectedId 를 저장하고 홈에서 '
                  '당겨서 새로고침해 보세요.\n\n'
                  '키를 넣었는데도 안 되면 CODEF·틸코 권한 환경(샌드박스 vs 실연동)을 '
                  '다시 확인하세요. CODEF 콘솔에서 발급받은 클라이언트가 개발용이면 '
                  'BFF .env 의 CODEF_BASE_URL 을 development.codef.io(또는 문서의 개발 호스트)에, '
                  '운영·실연동용이면 api.codef.io 등 운영 호스트에 맞춥니다. '
                  '호스트와 키 종류가 어긋나면 CF-00404/404·인증 오류가 날 수 있고, '
                  'connectedId 도 같은 환경에서 발급·저장된 값이어야 합니다. '
                  '틸코는 TILKO_API_HOST 가 dev.tilko.net 인지 api.tilko.net 인지 가입·플로우와 맞는지 점검하세요.\n\n'
                  'apidemo.tilko.net 문서 URL에 API_VERSION=v2.0 이 보여도, '
                  '「진료 및 투약 정보(공동인증)」본문의 실제 주소는 /api/v1.0/Nhis/... 입니다. '
                  '그 API는 공동인증서(CertFile·KeyFile)용이고, 이 앱이 쓰는 심평원 간편인증(/api/v1.0/hirasimpleauth/...)·CODEF 건보 상품과는 다른 제품입니다. '
                  '데모 페이지의 빈 API KEY 칸에는 콘솔에 발급된 일반용 키(표에 있는 값)를 넣어야 하며, 빈 칸 그대로는 호출되지 않습니다.\n\n'
                  'CF-00003(요청 서비스 상품 정보 없음)은 CODEF 쪽 상품 구독·CODEF_BASE_URL·상품 경로 이슈이며, '
                  '틸코 API KEY만 바꿔서는 해결되지 않을 수 있습니다.\n\n'
                  '문제가 계속되면 NHIS_SHOW_SYNC_SNACKBARS=true 로 스낵바 원인을 켤 수 있습니다.',
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
        ? 'connectedId: 설정됨 (앱 저장값 또는 빌드 .env)'
        : 'connectedId: 없음 — CODEF 본인조회에 필요 (아래 입력 후 저장, 또는 .env의 CODEF_CONNECTED_ID)';

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
            '공단·BFF 복약 동기화 점검',
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
                '→ CODEF connectedId 가 없으면 본인 진료·투약 조회가 막힐 수 있습니다.',
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
