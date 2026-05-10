/// `NHIS_USE_MOCK=true` 일 때만 사용하는 고정 JSON (실제 BFF 전환 시 미사용).
abstract final class NhisMockPayloads {
  /// [NhisMedicationsParser] 가 읽을 수 있는 형식.
  static const medicationsJson = '{"items":['
      '{"name":"[모크] 종합비타민","dose":"1정","frequency":"1일 1회","time":"09:00"},'
      '{"name":"[모크] 오메가3","dose":"-","frequency":"1일 1회","time":"12:00"}'
      ']}';
}
