import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

/// 홈·내 약 목록에서 수액·주사 등 병원 투여 항목 숨김 여부.
abstract final class MedicationListDisplayPrefs {
  static Future<bool> hideHospitalSupplies() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(StorageKeys.medicationHideHospitalSupplies) ?? false;
  }

  static Future<void> setHideHospitalSupplies(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(StorageKeys.medicationHideHospitalSupplies, value);
  }
}
