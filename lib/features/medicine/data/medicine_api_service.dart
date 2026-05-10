import 'package:dio/dio.dart';

import 'package:link26_app/core/network/api_client.dart';
import 'package:link26_app/core/network/api_endpoints.dart';
import 'package:link26_app/models/link_models.dart';

class MedicineApiService {
  MedicineApiService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<List<Medication>> fetchMedicines() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.medicines);
    final raw = response.data;
    final list = raw is List
        ? raw
        : (raw is Map ? raw['items'] as List<dynamic>? ?? const [] : const []);
    return list
        .whereType<Map>()
        .map((e) => Medication.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Medication> addMedicine({
    required String name,
    required String dose,
    required String frequency,
    required String time,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.medicines,
      data: {'name': name, 'dose': dose, 'frequency': frequency, 'time': time},
    );
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return Medication.fromJson(
      data['item'] is Map
          ? Map<String, dynamic>.from(data['item'] as Map)
          : data,
    );
  }

  Future<void> deleteMedicine(String id) async {
    await _dio.delete<dynamic>('${ApiEndpoints.medicines}/$id');
  }
}
