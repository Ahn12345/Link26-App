import 'package:flutter/material.dart';

import 'package:link26_app/models/medicine.dart';

class AddMedicineSheet extends StatefulWidget {
  const AddMedicineSheet({super.key});

  @override
  State<AddMedicineSheet> createState() => _AddMedicineSheetState();
}

class _AddMedicineSheetState extends State<AddMedicineSheet> {
  final searchController = TextEditingController();
  final candidates = const [
    Medicine(
      name: '타이레놀',
      dose: '500mg',
      frequency: '1일 3회',
      time: '08:00',
    ),
    Medicine(
      name: '아모잘탄',
      dose: '5/50mg',
      frequency: '1일 1회',
      time: '09:00',
    ),
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.all(18),
      padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: bottomInset + 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(blurRadius: 24, color: Colors.black26),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '약 추가',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: '약 이름 검색',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 18),
          ...candidates.asMap().entries.map(
                (e) => Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Color(0x11000000), blurRadius: 12),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFF1F5F9),
                        child: Text('${e.key + 1}'),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          e.value.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context, e.value),
                        icon: const Icon(Icons.add),
                        label: const Text('추가'),
                      ),
                    ],
                  ),
                ),
              ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('직접 입력', style: TextStyle(fontWeight: FontWeight.w900)),
            trailing: const Icon(Icons.arrow_forward, size: 32),
            onTap: () => Navigator.pop(
              context,
              const Medicine(
                name: '직접 입력 약',
                dose: '용량 미정',
                frequency: '복용법 미정',
                time: '08:00',
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B6BFF),
                foregroundColor: Colors.white,
              ),
              child: const Text('완료', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}
