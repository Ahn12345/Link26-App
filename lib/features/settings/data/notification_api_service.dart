import 'package:dio/dio.dart';

import 'package:link26_app/core/network/api_client.dart';
import 'package:link26_app/core/network/api_endpoints.dart';

class NotificationSettingsDto {
  const NotificationSettingsDto({
    required this.all,
    required this.message,
    required this.family,
    required this.phone,
  });

  final bool all;
  final bool message;
  final bool family;
  final bool phone;

  factory NotificationSettingsDto.fromJson(Map<String, dynamic> json) =>
      NotificationSettingsDto(
        all: json['all'] == true,
        message: json['message'] == true,
        family: json['family'] == true,
        phone: json['phone'] == true,
      );

  Map<String, dynamic> toJson() => {
        'all': all,
        'message': message,
        'family': family,
        'phone': phone,
      };
}

class NotificationApiService {
  NotificationApiService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<NotificationSettingsDto> fetchSettings() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.notificationSettings);
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return NotificationSettingsDto.fromJson(data);
  }

  Future<NotificationSettingsDto> updateSettings(
    NotificationSettingsDto settings,
  ) async {
    final response = await _dio.put<dynamic>(
      ApiEndpoints.notificationSettings,
      data: settings.toJson(),
    );
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : settings.toJson();
    return NotificationSettingsDto.fromJson(data);
  }
}
