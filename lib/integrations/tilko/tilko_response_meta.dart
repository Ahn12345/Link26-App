/// 틸코·NHIS JSON 루트의 Status/Message 등 공통 필드.
Map<String, String?> tilkoApiStatusFields(Map<String, dynamic> root) {
  String? pick(List<String> keys) {
    for (final k in keys) {
      final v = root[k];
      if (v == null) continue;
      final s = '$v'.trim();
      if (s.isNotEmpty && s != 'null') return s;
    }
    return null;
  }

  return {
    'code': pick([
      'Status',
      'status',
      'ErrorCode',
      'errorCode',
      'ResultCode',
      'resultCode',
      'Result',
    ]),
    'message': pick([
      'Message',
      'message',
      'ErrorMessage',
      'errorMessage',
      'ResultMessage',
      'resultMessage',
    ]),
  };
}

bool tilkoApiIndicatesFailure(Map<String, dynamic> root) {
  final code = (tilkoApiStatusFields(root)['code'] ?? '').toUpperCase();
  if (code.isEmpty) return false;
  const ok = {'OK', 'SUCCESS', 'Y', 'TRUE', '0', '0000', 'CF-00000'};
  return !ok.contains(code);
}
