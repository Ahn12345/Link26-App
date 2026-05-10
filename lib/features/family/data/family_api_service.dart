import 'package:dio/dio.dart';

import 'package:link26_app/core/network/api_client.dart';
import 'package:link26_app/core/network/api_endpoints.dart';
import 'package:link26_app/models/link_models.dart';

class FamilyApiService {
  FamilyApiService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<List<FamilyMember>> fetchMembers() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.familyMembers);
    final raw = response.data;
    final list = raw is List
        ? raw
        : (raw is Map ? raw['items'] as List<dynamic>? ?? const [] : const []);
    return list.whereType<Map>().map((e) {
      final m = Map<String, dynamic>.from(e);
      final nameStr = '${m['name'] ?? ''}';
      return FamilyMember(
        name: nameStr,
        relation: '${m['relation'] ?? ''}',
        phone: '${m['phone'] ?? ''}',
        avatarText:
            '${m['avatarText'] ?? (nameStr.isNotEmpty ? String.fromCharCode(nameStr.runes.first) : '?')}',
      );
    }).toList();
  }

  Future<FamilyMember> addMember({
    required String name,
    required String relation,
    required String phone,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.familyMembers,
      data: {'name': name, 'relation': relation, 'phone': phone},
    );
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    final item = data['item'] is Map
        ? Map<String, dynamic>.from(data['item'] as Map)
        : data;
    return FamilyMember(
      name: '${item['name'] ?? name}',
      relation: '${item['relation'] ?? relation}',
      phone: '${item['phone'] ?? phone}',
      avatarText: '${item['avatarText'] ?? (name.isNotEmpty ? name[0] : '?')}',
    );
  }
}
