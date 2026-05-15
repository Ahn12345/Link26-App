import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// PC `link26_bff` 가 보내는 UDP 비콘(`link26_bff_lan_beacon.dart`)을 잠깐 듣고
/// `http://IP:port` 베이스 URL 목록을 만듭니다. [tool/link26_bff_lan_beacon.dart] 와 포트·접두어가 같아야 합니다.
abstract final class Link26LanBffDiscovery {
  static const int _udpPort = 41234;
  static const String _prefix = 'link26-bff-v1 ';

  static bool _isPrivateLanIpv4(String host) {
    final parts = host.split('.');
    if (parts.length != 4) return false;
    final o1 = int.tryParse(parts[0]);
    final o2 = int.tryParse(parts[1]);
    if (o1 == null || o2 == null) return false;
    if (o1 == 10) return true;
    if (o1 == 172 && o2 >= 16 && o2 <= 31) return true;
    if (o1 == 192 && o2 == 168) return true;
    return false;
  }

  /// `192.168.1.5` → `192.168.1` (사설 IPv4만).
  static String? _slash24Key(String ipv4) {
    if (!_isPrivateLanIpv4(ipv4)) return null;
    final parts = ipv4.split('.');
    if (parts.length != 4) return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }

  static Future<Set<String>> _deviceSlash24Keys() async {
    final keys = <String>{};
    try {
      for (final ni in await NetworkInterface.list(includeLoopback: false)) {
        for (final a in ni.addresses) {
          if (a.type != InternetAddressType.IPv4) continue;
          final k = _slash24Key(a.address);
          if (k != null) keys.add(k);
        }
      }
    } catch (_) {}
    return keys;
  }

  /// 폰·태블릿이 붙어 있는 Wi‑Fi 대역과 같은 /24 인 BFF 주소를 앞으로 둡니다.
  static Future<List<String>> prioritizeForDeviceLan(List<String> bases) async {
    if (bases.isEmpty || kIsWeb) return bases;
    final keys = await _deviceSlash24Keys();
    if (keys.isEmpty) return bases;
    bool onSameSlash24(String base) {
      try {
        final host = Uri.parse(base).host;
        final k = _slash24Key(host);
        return k != null && keys.contains(k);
      } catch (_) {
        return false;
      }
    }

    final primary = <String>[];
    final secondary = <String>[];
    for (final b in bases) {
      if (onSameSlash24(b)) {
        primary.add(b);
      } else {
        secondary.add(b);
      }
    }
    return List<String>.unmodifiable([...primary, ...secondary]);
  }

  /// 웹·바인드 실패 시 빈 목록.
  static Future<List<String>> discoverOnce({
    Duration listenFor = const Duration(milliseconds: 3500),
  }) async {
    if (kIsWeb) return const [];
    late final RawDatagramSocket s;
    try {
      s = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _udpPort,
        reuseAddress: true,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Link26LanBffDiscovery: UDP $_udpPort 바인드 실패(다른 프로세스?): $e');
      }
      return const [];
    }

    final found = <String>[];
    final seen = <String>{};

    late final StreamSubscription<RawSocketEvent> sub;
    sub = s.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = s.receive();
      if (dg == null) return;
      final text = utf8.decode(dg.data, allowMalformed: true).trim();
      if (!text.startsWith(_prefix)) return;
      final portStr = text.substring(_prefix.length).trim();
      final port = int.tryParse(portStr);
      if (port == null || port <= 0 || port > 65535) return;
      final ip = dg.address.address;
      if (ip.isEmpty || ip == '0.0.0.0') return;
      final base = 'http://$ip:$port';
      if (seen.add(base)) {
        found.add(base);
        if (kDebugMode) {
          debugPrint('Link26LanBffDiscovery: 발견 $base');
        }
      }
    });

    await Future<void>.delayed(listenFor);
    await sub.cancel();
    s.close();
    return List<String>.unmodifiable(await prioritizeForDeviceLan(found));
  }
}
