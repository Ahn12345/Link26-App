import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:link26_app/core/constants/gemini_runtime_config.dart';
import 'package:link26_app/core/services/prescription_medicine_persistence.dart';
import 'package:link26_app/core/services/prescription_register_service.dart';
import 'package:link26_app/core/services/user_pinned_medicine_store.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';
import 'package:link26_app/models/medicine.dart';

/// 처방전 사진·텍스트로 약을 추출해 내 복약 목록에 등록합니다 (공단 DB 등록 아님).
class PrescriptionRegisterSheet extends StatefulWidget {
  const PrescriptionRegisterSheet({super.key, this.openCameraOnStart = false});

  final bool openCameraOnStart;

  @override
  State<PrescriptionRegisterSheet> createState() =>
      _PrescriptionRegisterSheetState();
}

class _PrescriptionRegisterSheetState extends State<PrescriptionRegisterSheet> {
  final _pasteCtrl = TextEditingController();
  final _manualCtrl = TextEditingController();
  final _picker = ImagePicker();

  bool _busy = false;
  String? _status;
  final Map<String, String> _normToLabel = {};
  final Map<String, bool> _selected = {};
  final List<Medicine> _confirmed = [];

  @override
  void initState() {
    super.initState();
    if (widget.openCameraOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_pickImage(ImageSource.camera));
      });
    }
  }

  @override
  void dispose() {
    _pasteCtrl.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 5)),
    );
  }

  void _setCandidates(List<String> names) {
    _normToLabel.clear();
    _selected.clear();
    for (final n in names) {
      final norm = UserPinnedMedicineStore.norm(n);
      _normToLabel[norm] = n;
      _selected[norm] = true;
    }
  }

  Future<void> _addNamesToConfirmed(Iterable<String> names) async {
    for (final raw in names) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      final norm = UserPinnedMedicineStore.norm(name);
      if (_confirmed.any((m) => UserPinnedMedicineStore.norm(m.name) == norm)) {
        continue;
      }
      await UserPinnedMedicineStore.pin(name);
      _confirmed.add(PrescriptionMedicinePersistence.stub(name));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_busy) return;
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 88);
      if (file == null) return;
      if (!mounted) return;
      setState(() {
        _busy = true;
        _status = '처방전을 분석하는 중…';
      });
      final bytes = await file.readAsBytes();
      final result = await PrescriptionRegisterService.extractFromImage(
        bytes: Uint8List.fromList(bytes),
        mimeType: _mimeFromPath(file.path),
      );
      if (!mounted) return;
      if (result.names.isNotEmpty) {
        _setCandidates(result.names);
        await _addNamesToConfirmed(result.names);
        setState(() {
          _busy = false;
          _status =
              '약 ${result.names.length}건을 인식했습니다. 아래 「목록에 반영」을 눌러 주세요.';
        });
        return;
      }
      setState(() {
        _busy = false;
        _setCandidates([]);
        _status = result.errorMessageKo ??
            '사진에서 약 이름을 찾지 못했습니다. 직접 입력하거나 텍스트 붙여넣기를 이용해 주세요.';
      });
      _toast(_status!);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = '사진을 불러오지 못했습니다. ($e)';
      });
      _toast(_status!);
    }
  }

  String _mimeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _analyzePaste() async {
    if (_busy) return;
    final text = _pasteCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _status = '처방전에서 복사한 텍스트를 붙여넣어 주세요.');
      _toast(_status!);
      return;
    }
    setState(() {
      _busy = true;
      _status = '텍스트를 분석하는 중…';
    });
    final result =
        await PrescriptionRegisterService.extractFromPastedText(text);
    if (!mounted) return;
    if (result.names.isNotEmpty) {
      _setCandidates(result.names);
      await _addNamesToConfirmed(result.names);
      setState(() {
        _busy = false;
        _status = '약 ${result.names.length}건을 찾았습니다. 「목록에 반영」을 눌러 주세요.';
      });
      return;
    }
    setState(() {
      _busy = false;
      _setCandidates([]);
      _status = result.errorMessageKo ?? '텍스트에서 약 이름을 찾지 못했습니다.';
    });
    _toast(_status!);
  }

  Future<void> _addManual() async {
    final name = _manualCtrl.text.trim();
    if (name.isEmpty) return;
    await _addNamesToConfirmed([name]);
    if (!mounted) return;
    setState(() {
      _manualCtrl.clear();
      _status = '「$name」을 등록 목록에 넣었습니다. 「목록에 반영」을 눌러 주세요.';
    });
  }

  Future<void> _mergeSelectedIntoConfirmed() async {
    final names = <String>[];
    for (final entry in _selected.entries) {
      if (!entry.value) continue;
      final label = _normToLabel[entry.key];
      if (label != null && label.isNotEmpty) names.add(label);
    }
    await _addNamesToConfirmed(names);
  }

  Future<void> _applyToMyList() async {
    await _mergeSelectedIntoConfirmed();
    if (_confirmed.isEmpty) {
      _toast(
        GeminiRuntimeConfig.isConfigured
            ? '등록할 약이 없습니다. 사진·텍스트·직접 입력으로 약을 추가한 뒤 다시 시도하세요.'
            : '사진 인식에는 GEMINI_API_KEY가 필요합니다. '
                '아래에서 약 이름을 직접 입력한 뒤 「목록에 반영」을 눌러 주세요.',
      );
      return;
    }
    await PrescriptionMedicinePersistence.saveAll(_confirmed);
    if (!mounted) return;
    Navigator.pop(context, List<Medicine>.from(_confirmed));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasCandidates = _normToLabel.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(18),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: bottomInset + 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(blurRadius: 24, color: Colors.black26),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '처방전 등록',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Link26Surface.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              '사진·텍스트로 약을 찾은 뒤 반드시 아래 「목록에 반영」을 눌러 주세요.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Link26Surface.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!GeminiRuntimeConfig.isConfigured) ...[
              const SizedBox(height: 8),
              Text(
                '사진 자동 인식: 루트 .env에 GEMINI_API_KEY → '
                'tool/sync_dotenv_asset.ps1 후 앱 재빌드. '
                '지금은 직접 입력이 가장 빠릅니다.',
                style: TextStyle(
                  fontSize: 13,
                  color: Link26Surface.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Gemini 키 로드됨 · 모델 ${GeminiRuntimeConfig.modelId}',
                style: TextStyle(
                  fontSize: 12,
                  color: Link26Surface.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            if (_status != null) ...[
              const SizedBox(height: 8),
              Text(
                _status!,
                style: TextStyle(
                  fontSize: 13,
                  color: Link26Surface.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _busy
                      ? null
                      : () => unawaited(_pickImage(ImageSource.camera)),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('사진 촬영'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _busy
                      ? null
                      : () => unawaited(_pickImage(ImageSource.gallery)),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('앨범'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pasteCtrl,
              maxLines: 4,
              decoration: Link26Surface.inputDecoration(
                labelText: '처방 내용 붙여넣기',
                hintText: '처방전 약품명 줄을 복사해 붙여넣기',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: _busy ? null : () => unawaited(_analyzePaste()),
                child: const Text('텍스트에서 약 찾기'),
              ),
            ),
            if (hasCandidates) ...[
              const SizedBox(height: 12),
              ..._normToLabel.entries.map((e) {
                final norm = e.key;
                final label = e.value;
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _selected[norm] ?? false,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _selected[norm] = v ?? false),
                  title: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _manualCtrl,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => unawaited(_addManual()),
              decoration: Link26Surface.inputDecoration(
                labelText: '약 이름 직접 입력',
                hintText: '예: 케피람정 100mg',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => unawaited(_addManual()),
                icon: const Icon(Icons.add),
                label: const Text('추가'),
              ),
            ),
            if (_confirmed.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '등록 예정 (${_confirmed.length}건)',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Link26Surface.textPrimary,
                ),
              ),
              ..._confirmed.map(
                (m) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.check_circle, color: Link26Surface.accent),
                  title: Text(m.name),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : () => unawaited(_applyToMyList()),
                style: Link26UnifiedPage.filledCtaButton(),
                child: Text(
                  _confirmed.isEmpty
                      ? '목록에 반영'
                      : '목록에 반영 (${_confirmed.length}건)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
