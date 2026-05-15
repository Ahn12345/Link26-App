import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// PC `link26_bff` 가 보내는 UDP 비콘(`link26_bff_lan_beacon.dart`)을 잠깐 듣고
/// `http://IP:port` 베이스 URL 목록을 만듭니다. [tool/link26_bff_lan_beacon.dart] 와 포트·접두어가 같아야 합니다.
abstract final class Link26LanBffDiscovery {
  static const int _udpPort = 41234;
  static const String _prefix = 'link26-bff-v1 ';

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
    return List<String>.unmodifiable(found);
  }
}
