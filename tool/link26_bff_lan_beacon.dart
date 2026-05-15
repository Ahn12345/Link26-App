import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// PC BFF가 LAN에서 자동 발견되도록 UDP 비콘을 주기적으로 보냅니다.
/// 앱은 [lib/core/services/link26_lan_bff_discovery.dart] 와 동일 포트에서 수신합니다.
const int kLink26BffLanUdpPort = 41234;
const String kLink26BffLanPayloadPrefix = 'link26-bff-v1 ';

bool _isPrivateLanIpv4(InternetAddress a) {
  if (a.type != InternetAddressType.IPv4 || a.isLoopback) return false;
  final parts = a.address.split('.');
  if (parts.length != 4) return false;
  final o1 = int.tryParse(parts[0]);
  final o2 = int.tryParse(parts[1]);
  if (o1 == null || o2 == null) return false;
  if (o1 == 10) return true;
  if (o1 == 172 && o2 >= 16 && o2 <= 31) return true;
  if (o1 == 192 && o2 == 168) return true;
  return false;
}

/// 사설 IPv4에 대해 일반적인 /24 브로드캐스트 주소를 추정합니다.
InternetAddress? _broadcastFor(InternetAddress a) {
  final parts = a.address.split('.');
  if (parts.length != 4) return null;
  final o1 = int.tryParse(parts[0]);
  final o2 = int.tryParse(parts[1]);
  final o3 = int.tryParse(parts[2]);
  if (o1 == null || o2 == null || o3 == null) return null;
  if (o1 == 192 && o2 == 168) {
    return InternetAddress('192.168.$o3.255');
  }
  if (o1 == 10) {
    return InternetAddress('10.$o2.$o3.255');
  }
  if (o1 == 172 && o2 >= 16 && o2 <= 31) {
    return InternetAddress('172.$o2.$o3.255');
  }
  return null;
}

/// Hyper-V·WSL·가상머신 NIC 으로 브로드캐스트하면 폰이 `172.*` 등 **잘못된 BFF IP** 를 잡는 경우가 많습니다.
bool _isLikelyVirtualInterface(String name) {
  final n = name.toLowerCase();
  return n.contains('vethernet') ||
      n.contains('hyper-v') ||
      n.contains('virtualbox') ||
      n.contains('vmware') ||
      n.contains('wsl') ||
      n.contains('virtual ') ||
      n.contains('vpn') ||
      n.contains('tap-windows') ||
      n.contains('zerotier') ||
      n.contains('tailscale') ||
      n.contains('nordlynx') ||
      n.contains('wireguard');
}

Future<Set<InternetAddress>> _broadcastTargets() async {
  final out = <InternetAddress>{};
  try {
    for (final ni in await NetworkInterface.list(includeLoopback: false)) {
      if (_isLikelyVirtualInterface(ni.name)) continue;
      for (final addr in ni.addresses) {
        if (!_isPrivateLanIpv4(addr)) continue;
        final b = _broadcastFor(addr);
        if (b != null) out.add(b);
      }
    }
  } catch (_) {}
  try {
    out.add(InternetAddress('255.255.255.255'));
  } catch (_) {}
  return out;
}

Timer? _link26BffLanBeaconTimer;

/// BFF 기동 후 호출. [httpPort] 는 `HttpServer.port`.
void startLink26BffLanBeacon(int httpPort) {
  _link26BffLanBeaconTimer?.cancel();
  unawaited(() async {
    RawDatagramSocket? s;
    try {
      s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      s.broadcastEnabled = true;
    } catch (_) {
      return;
    }
    final payload = utf8.encode('$kLink26BffLanPayloadPrefix$httpPort');
    Future<void> sendOnce() async {
      final sock = s;
      if (sock == null) return;
      final targets = await _broadcastTargets();
      for (final t in targets) {
        try {
          sock.send(payload, t, kLink26BffLanUdpPort);
        } catch (_) {}
      }
    }

    await sendOnce();
    _link26BffLanBeaconTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(sendOnce());
    });
  }());
}
