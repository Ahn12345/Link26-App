import 'package:dio/dio.dart';

import 'package:link26_app/core/network/api_client.dart';
import 'package:link26_app/core/network/api_endpoints.dart';
import 'package:link26_app/models/link_models.dart';

class HomeDashboardDto {
  const HomeDashboardDto({
    required this.medications,
    required this.alarms,
    required this.completedCount,
    required this.totalCount,
  });

  final List<Medication> medications;
  final List<MedicineAlarm> alarms;
  final int completedCount;
  final int totalCount;

  factory HomeDashboardDto.fromJson(Map<String, dynamic> json) {
    final medicationsJson = json['medications'] as List<dynamic>? ?? const [];
    final alarmsJson = json['alarms'] as List<dynamic>? ?? const [];
    return HomeDashboardDto(
      medications: medicationsJson
          .whereType<Map>()
          .map((e) => Medication.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      alarms: alarmsJson
          .whereType<Map>()
          .map((e) {
            final m = Map<String, dynamic>.from(e);
            return MedicineAlarm(
              id: '${m['id'] ?? ''}',
              dateLabel: '${m['dateLabel'] ?? m['date'] ?? ''}',
              time: '${m['time'] ?? ''}',
              type: '${m['type'] ?? 'alarm'}',
              medicineName: '${m['medicineName'] ?? m['name'] ?? ''}',
              dose: '${m['dose'] ?? ''}',
              status: '${m['status'] ?? ''}',
            );
          })
          .toList(),
      completedCount: int.tryParse('${json['completedCount'] ?? 0}') ?? 0,
      totalCount: int.tryParse('${json['totalCount'] ?? 0}') ?? 0,
    );
  }
}

class HomeApiService {
  HomeApiService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<HomeDashboardDto> fetchDashboard() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.homeDashboard);
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return HomeDashboardDto.fromJson(data);
  }
}
