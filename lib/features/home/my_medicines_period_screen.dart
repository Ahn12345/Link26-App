import 'dart:async';

import 'package:flutter/material.dart';

import 'package:link26_app/core/layout/link26_responsive_ui_tokens.g.dart';
import 'package:link26_app/core/services/dose_reminder_completion_store.dart';
import 'package:link26_app/core/services/local_medicine_list_store.dart';
import 'package:link26_app/core/services/nhis_medicine_cache_store.dart';
import 'package:link26_app/core/theme/link26_surface_style.dart';
import 'package:link26_app/core/theme/link26_unified_page.dart';
import 'package:link26_app/core/widgets/link26_dashboard_widgets.dart';
import 'package:link26_app/features/medicine/add_medicine_sheet.dart';
import 'package:link26_app/l10n/app_localizations.dart';
import 'package:link26_app/models/medicine.dart';

/// 홈 「내 약 목록」 전체보기 — 기간 칩 + 동기화 약 + 기간 내 복용 완료 횟수.
class MyMedicinesPeriodScreen extends StatefulWidget {
  const MyMedicinesPeriodScreen({super.key, this.onMedicinesChanged});

  /// 약 추가 후 홈 목록을 갱신할 때 호출합니다.
  final VoidCallback? onMedicinesChanged;

  @override
  State<MyMedicinesPeriodScreen> createState() =>
      _MyMedicinesPeriodScreenState();
}

enum _PeriodSpan {
  oneMonth(Duration(days: 30)),
  threeMonths(Duration(days: 90)),
  sixMonths(Duration(days: 180)),
  oneYear(Duration(days: 365));

  const _PeriodSpan(this.lookback);
  final Duration lookback;
}

class _MyMedicinesPeriodScreenState extends State<MyMedicinesPeriodScreen> {
  _PeriodSpan _span = _PeriodSpan.oneMonth;
  List<Medicine> _medicines = [];
  Map<String, int> _completionByNorm = {};
  bool _loading = true;

  String _normMedName(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  (DateTime, DateTime) _rangeForSpan() {
    final end = DateTime.now();
    final start = end.subtract(_span.lookback);
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return (startDay, endDay);
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final cached = await NhisMedicineCacheStore.loadMedicines();
    final manualNames = await LocalMedicineListStore.load();
    final byName = <String, Medicine>{};
    for (final m in cached) {
      final k = _normMedName(m.name);
      if (k.isEmpty) continue;
      byName[k] = m;
    }
    for (final n in manualNames) {
      final k = _normMedName(n);
      if (k.isEmpty) continue;
      byName.putIfAbsent(
        k,
        () => Medicine(name: n.trim(), dose: '-', frequency: '-', time: '-'),
      );
    }
    final merged = byName.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final range = _rangeForSpan();
    final completions = await DoseReminderCompletionStore.completionCountsByNormInRange(
      fromInclusive: range.$1,
      toInclusive: range.$2,
    );
    if (!mounted) return;
    setState(() {
      _medicines = merged;
      _completionByNorm = completions;
      _loading = false;
    });
  }

  Future<void> _openAddMedicine() async {
    final result = await showModalBottomSheet<Medicine>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMedicineSheet(),
    );
    if (result == null) return;
    await LocalMedicineListStore.add(result.name);
    await NhisMedicineCacheStore.upsert(result);
    widget.onMedicinesChanged?.call();
    await _reload();
  }

  String _ymd(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final w = MediaQuery.sizeOf(context).width;
    final range = _rangeForSpan();
    final chips = <(_PeriodSpan, String)>[
      (_PeriodSpan.oneMonth, l10n.myMedicinesPeriod1m),
      (_PeriodSpan.threeMonths, l10n.myMedicinesPeriod3m),
      (_PeriodSpan.sixMonths, l10n.myMedicinesPeriod6m),
      (_PeriodSpan.oneYear, l10n.myMedicinesPeriod1y),
    ];

    return Scaffold(
      backgroundColor: Link26UnifiedPage.background,
      appBar: AppBar(
        title: Text(
          l10n.homeMyMedicinesTitle,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMedicine,
        icon: const Icon(Icons.add),
        label: Text(l10n.myMedicinesAddMedicineFab),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  Link26ResponsiveUi.homeScrollPadH(w),
                  Link26ResponsiveUi.gapMd(w),
                  Link26ResponsiveUi.homeScrollPadH(w),
                  96,
                ),
                children: [
                  Text(
                    '${l10n.myMedicinesPeriodLabel} ${_ymd(range.$1)} ~ ${_ymd(range.$2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: Link26ResponsiveUi.bodySmall(w),
                      color: Link26Surface.textSecondary,
                    ),
                  ),
                  SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                  Text(
                    l10n.myMedicinesPeriodHint,
                    style: TextStyle(
                      fontSize: Link26ResponsiveUi.caption(w),
                      height: 1.35,
                      color: Link26Surface.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: Link26ResponsiveUi.gapMd(w)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: chips.map((e) {
                      final selected = e.$1 == _span;
                      return ChoiceChip(
                        label: Text(e.$2),
                        selected: selected,
                        onSelected: (v) {
                          if (!v) return;
                          setState(() => _span = e.$1);
                          unawaited(_reload());
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: Link26ResponsiveUi.gapLg(w)),
                  Text(
                    l10n.myMedicinesSyncedSectionTitle,
                    style: TextStyle(
                      fontSize: Link26ResponsiveUi.subsectionHeader(w),
                      fontWeight: FontWeight.w900,
                      color: Link26Surface.textPrimary,
                    ),
                  ),
                  SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                  if (_medicines.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top: Link26ResponsiveUi.gapMd(w),
                        bottom: Link26ResponsiveUi.gapLg(w),
                      ),
                      child: Text(
                        l10n.myMedicinesNoMedicines,
                        style: TextStyle(
                          color: Link26Surface.textMuted,
                          fontSize: Link26ResponsiveUi.bodySmall(w),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    ..._medicines.map((m) => _MedicineRow(medicine: m)),
                  SizedBox(height: Link26ResponsiveUi.gapLg(w)),
                  Text(
                    l10n.myMedicinesCompletionsSectionTitle,
                    style: TextStyle(
                      fontSize: Link26ResponsiveUi.subsectionHeader(w),
                      fontWeight: FontWeight.w900,
                      color: Link26Surface.textPrimary,
                    ),
                  ),
                  SizedBox(height: Link26ResponsiveUi.gapSm(w)),
                  if (_completionByNorm.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: Link26ResponsiveUi.gapMd(w)),
                      child: Text(
                        l10n.myMedicinesNoCompletions,
                        style: TextStyle(
                          color: Link26Surface.textMuted,
                          fontSize: Link26ResponsiveUi.bodySmall(w),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    ..._sortedCompletionRows().map(
                      (e) => Padding(
                        padding: EdgeInsets.only(
                          top: Link26ResponsiveUi.medicineTileGapTop(w),
                        ),
                        child: Link26ElevatedCard(
                          padding: EdgeInsets.symmetric(
                            horizontal: Link26ResponsiveUi.profileRowGap(w),
                            vertical: Link26ResponsiveUi.gapSm(w) +
                                Link26ResponsiveUi.gapXs(w),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.$1,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: Link26ResponsiveUi.medicineName(w),
                                    color: Link26Surface.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                l10n.myMedicinesCompletionCountLabel(e.$2),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Link26Surface.accent,
                                  fontSize: Link26ResponsiveUi.bodySmall(w),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  /// 표시용 이름: 동기화 목록에서 찾은 표기를 우선합니다.
  List<(String, int)> _sortedCompletionRows() {
    final rows = <(String, int)>[];
    for (final e in _completionByNorm.entries) {
      var label = e.key;
      for (final m in _medicines) {
        if (_normMedName(m.name) == e.key) {
          label = m.name;
          break;
        }
      }
      rows.add((label, e.value));
    }
    rows.sort((a, b) => b.$2.compareTo(a.$2));
    return rows;
  }
}

class _MedicineRow extends StatelessWidget {
  const _MedicineRow({required this.medicine});

  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.only(top: Link26ResponsiveUi.medicineTileGapTop(w)),
      child: Link26ElevatedCard(
        padding: EdgeInsets.symmetric(
          horizontal: Link26ResponsiveUi.profileRowGap(w),
          vertical: Link26ResponsiveUi.gapSm(w) + Link26ResponsiveUi.gapXs(w),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: Link26ResponsiveUi.medicineAvatarRadius(w),
              backgroundColor: const Color(0xFFEAF3FF),
              child: const Icon(
                Icons.medication_outlined,
                color: Link26Surface.accent,
              ),
            ),
            SizedBox(width: Link26ResponsiveUi.gapMd(w)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: Link26ResponsiveUi.medicineName(w),
                      color: Link26Surface.textPrimary,
                    ),
                  ),
                  SizedBox(height: Link26ResponsiveUi.gapXs(w)),
                  Text(
                    '${medicine.dose}   ${medicine.frequency}   ${medicine.time}',
                    style: TextStyle(
                      color: Link26Surface.textMuted,
                      fontSize: Link26ResponsiveUi.medicineMeta(w),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
