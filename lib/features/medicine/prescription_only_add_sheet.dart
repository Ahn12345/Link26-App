import 'package:flutter/material.dart';

import 'package:link26_app/core/services/user_pinned_medicine_store.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';
import 'package:link26_app/models/medicine.dart';

/// 조제 전·처방전 전용 약 — 심평원 API에 없을 때 직접 추가합니다.
class PrescriptionOnlyAddSheet extends StatefulWidget {
  const PrescriptionOnlyAddSheet({super.key});

  @override
  State<PrescriptionOnlyAddSheet> createState() =>
      _PrescriptionOnlyAddSheetState();
}

class _PrescriptionOnlyAddSheetState extends State<PrescriptionOnlyAddSheet> {
  final _nameCtrl = TextEditingController();
  final _added = <Medicine>[];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Medicine _stub(String name) => Medicine(
        name: name,
        dose: '-',
        frequency: '-',
        time: '09:00',
      );

  Future<void> _addCurrent() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final norm = UserPinnedMedicineStore.norm(name);
    if (_added.any((m) => UserPinnedMedicineStore.norm(m.name) == norm)) {
      _nameCtrl.clear();
      return;
    }
    await UserPinnedMedicineStore.pin(name);
    setState(() {
      _added.add(_stub(name));
      _nameCtrl.clear();
    });
  }

  void _finish() {
    Navigator.pop(context, List<Medicine>.from(_added));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '처방전 약 직접 추가',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Link26Surface.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '아직 약국에서 조제·신고되지 않은 약은 심평원·건보에 없습니다. '
            '여기서 추가하면 다음 「심평원에서 불러오기」 후에도 목록에 남습니다.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Link26Surface.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _addCurrent(),
            decoration: Link26Surface.inputDecoration(
              labelText: '약 이름',
              hintText: '예: 케피람, 토파맥스, 제비닉스',
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _addCurrent,
              icon: const Icon(Icons.add),
              label: const Text('목록에 넣기'),
            ),
          ),
          if (_added.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._added.map(
              (m) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.medication, color: Link26Surface.accent),
                title: Text(
                  m.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _finish,
              style: Link26UnifiedPage.filledCtaButton(),
              child: Text(
                _added.isEmpty ? '나중에' : '완료 (${_added.length}건)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
