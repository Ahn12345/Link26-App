import 'package:flutter/material.dart';
import 'package:link26_app/features/more/privacy_consent_pdf_screen.dart';
import 'package:link26_app/l10n/app_localizations.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <(String, String)>[
      ('계정 및 프로필 설정', '프로필 정보를 확인하고 가족 구성원을 추가하여 편리하게 관리할 수 있습니다.'),
      ('가족 구성원 추가', '가족 구성원을 추가하면 연락처와 알림을 공유할 수 있습니다.'),
      ('연락처 관리', '가족 및 보호자 연락처를 등록하고 쉽게 관리할 수 있습니다.'),
      ('알림 설정', '중요한 알림을 놓치지 않도록 알림 설정을 관리해보세요.'),
    ];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new),
                ),
                const Text('사용 가이드', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '링크를 더 스마트하게,\n쉽게 사용해보세요\n\n링크의 주요 기능과 사용 방법을 안내해 드립니다.',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(
                l10n.privacyConsentDocumentTitle,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(l10n.guidePrivacyConsentSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivacyConsentPdfScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ...items.map(
              (e) => ListTile(
                title: Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(e.$2),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
