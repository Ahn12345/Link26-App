import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:link26_app/core/constants/gemini_runtime_config.dart';
import 'package:link26_app/core/services/prescription_register_service.dart';
import 'package:link26_app/core/services/user_pinned_medicine_store.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';
import 'package:link26_app/models/medicine.dart';

/// 처방전 사진·텍스트로 약을 추출해 내 복약 목록에 등록합니다 (공단 DB 등록 아님).
class PrescriptionRegisterSheet extends StatefulWidget {
  const PrescriptionRegisterSheet({super.key});

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
  void dispose() {
    _pasteCtrl.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  Medicine _stub(String name) => Medicine(
        name: name,
        dose: '-',
        frequency: '-',
        time: '09:00',
      );

  void _setCandidates(List<String> names) {
    _normToLabel.clear();
    _selected.clear();
    for (final n in names) {
      final norm = UserPinnedMedicineStore.norm(n);
      _normToLabel[norm] = n;
      _selected[norm] = true;
    }
    _status = names.isEmpty ? null : '아래에서 등록할 약을 선택하세요.';
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_busy) return;
    final file = await _picker.pickImage(source: source, imageQuality: 88);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _busy = true;
      _status = '처방전을 분석하는 중…';
    });
    final result = await PrescriptionRegisterService.extractFromImage(
      bytes: Uint8List.fromList(bytes),
      mimeType: _mimeFromPath(file.path),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _setCandidates(result.names);
      if (result.errorMessageKo != null) {
        _status = result.errorMessageKo;
      }
    });
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
      return;
    }
    setState(() {
      _busy = true;
      _status = '텍스트를 분석하는 중…';
    });
    final result =
        await PrescriptionRegisterService.extractFromPastedText(text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _setCandidates(result.names);
      if (result.errorMessageKo != null) {
        _status = result.errorMessageKo;
      }
    });
  }

  Future<void> _addManual() async {
    final name = _manualCtrl.text.trim();
    if (name.isEmpty) return;
    final norm = UserPinnedMedicineStore.norm(name);
    if (_confirmed.any((m) => UserPinnedMedicineStore.norm(m.name) == norm)) {
      _manualCtrl.clear();
      return;
    }
    await UserPinnedMedicineStore.pin(name);
    if (!mounted) return;
    setState(() {
      _confirmed.add(_stub(name));
      _manualCtrl.clear();
    });
  }

  Future<void> _registerSelected() async {
    for (final entry in _selected.entries) {
      if (!entry.value) continue;
      final label = _normToLabel[entry.key];
      if (label == null || label.isEmpty) continue;
      final norm = entry.key;
      if (_confirmed.any((m) => UserPinnedMedicineStore.norm(m.name) == norm)) {
        continue;
      }
      await UserPinnedMedicineStore.pin(label);
      _confirmed.add(_stub(label));
    }
    _selected.clear();
    _normToLabel.clear();
    if (!mounted) return;
    setState(() => _status = '선택한 약을 등록 목록에 넣었습니다.');
  }

  void _finish() {
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
              '병원 처방전을 앱 「내 복약」에 등록합니다. '
              '건강보험·심평원 DB에 자동 신고되지는 않으며, '
              '약국 조제 후에는 「심평원에서 불러오기」로 맞춰 주세요.',
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
                '사진 인식: .env에 GEMINI_API_KEY 설정 후 앱 재빌드. '
                '키 없이도 텍스트 붙여넣기·직접 입력은 가능합니다.',
                style: TextStyle(
                  fontSize: 13,
                  color: Link26Surface.textMuted,
                  fontWeight: FontWeight.w600,
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
                      : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('사진 촬영'),
                ),
                FilledButton.tonalIcon(
                  onPressed:
                      _busy ? null : () => _pickImage(ImageSource.gallery),
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
                onPressed: _busy ? null : _analyzePaste,
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
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _busy ? null : () => unawaited(_registerSelected()),
                  style: Link26UnifiedPage.filledCtaButton(),
                  child: const Text('선택 약 등록'),
                ),
              ),
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
                onPressed: _busy ? null : _finish,
                style: Link26UnifiedPage.filledCtaButton(),
                child: Text(
                  _confirmed.isEmpty ? '닫기' : '완료 (${_confirmed.length}건)',
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
