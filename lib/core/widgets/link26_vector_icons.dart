import 'package:flutter/material.dart';

/// Material / Cupertino 글꼴이 기기에서 깨질 때를 대비한 **폰트 미사용** 미니 아이콘.
abstract final class Link26VectorIcons {
  static Widget sized(CustomPainter painter, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: painter),
    );
  }

  static Widget home(Color color, {double size = 22}) =>
      sized(_HomePainter(color), size);

  static Widget chat(Color color, {double size = 22}) =>
      sized(_ChatPainter(color), size);

  static Widget more(Color color, {double size = 22}) =>
      sized(_MorePainter(color), size);

  static Widget search(Color color, {double size = 20}) =>
      sized(_SearchPainter(color), size);

  static Widget bell(Color color, {double size = 20}) =>
      sized(_BellPainter(color), size);

  static Widget phone(Color color, {double size = 20}) =>
      sized(_PhonePainter(color), size);

  static Widget check(Color color, {double size = 20}) =>
      sized(_CheckPainter(color), size);

  static Widget capsule(Color color, {double size = 20}) =>
      sized(_CapsulePainter(color), size);

  static Widget pencil(Color color, {double size = 20}) =>
      sized(_PencilPainter(color), size);

  static Widget paperclip(Color color, {double size = 20}) =>
      sized(_PaperclipPainter(color), size);

  static Widget xMark(Color color, {double size = 18}) =>
      sized(_XMarkPainter(color), size);

  static Widget send(Color color, {double size = 20}) =>
      sized(_SendPainter(color), size);

  static Widget lock(Color color, {double size = 20}) =>
      sized(_LockPainter(color), size);

  static Widget info(Color color, {double size = 20}) =>
      sized(_InfoPainter(color), size);

  static Widget chevronBack(Color color, {double size = 18}) =>
      sized(_ChevronBackPainter(color), size);
}

abstract class _StrokePainter extends CustomPainter {
  _StrokePainter(this.color);
  final Color color;

  Paint stroke([double w = 1.85]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}

class _HomePainter extends _StrokePainter {
  _HomePainter(super.color);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final roof = Path()
      ..moveTo(w * 0.5, h * 0.18)
      ..lineTo(w * 0.16, h * 0.44)
      ..lineTo(w * 0.84, h * 0.44)
      ..close();
    canvas.drawPath(roof, fill);
    final body = RRect.fromLTRBR(
      w * 0.22,
      h * 0.42,
      w * 0.78,
      h * 0.86,
      const Radius.circular(2.2),
    );
    canvas.drawRRect(body, stroke(1.7));
  }

  @override
  bool shouldRepaint(covariant _HomePainter old) => old.color != color;
}

class _ChatPainter extends _StrokePainter {
  _ChatPainter(super.color);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    final r = RRect.fromLTRBR(
      w * 0.12,
      h * 0.18,
      w * 0.88,
      h * 0.72,
      Radius.circular(h * 0.14),
    );
    canvas.drawRRect(r, stroke(1.7));
    final tail = Path()
      ..moveTo(w * 0.28, h * 0.68)
      ..lineTo(w * 0.18, h * 0.88)
      ..lineTo(w * 0.42, h * 0.72);
    canvas.drawPath(tail, stroke(1.7));
  }

  @override
  bool shouldRepaint(covariant _ChatPainter old) => old.color != color;
}

class _MorePainter extends _StrokePainter {
  _MorePainter(super.color);

  @override
  void paint(Canvas canvas, Size s) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final r = s.width * 0.085;
    final cy = s.height * 0.5;
    for (final cx in [s.width * 0.28, s.width * 0.5, s.width * 0.72]) {
      canvas.drawCircle(Offset(cx, cy), r, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _MorePainter old) => old.color != color;
}

class _SearchPainter extends _StrokePainter {
  _SearchPainter(super.color);

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width * 0.42, s.height * 0.42);
    final rad = s.width * 0.26;
    canvas.drawCircle(c, rad, stroke(1.85));
    final p0 = Offset(c.dx + rad * 0.65, c.dy + rad * 0.65);
    final p1 = Offset(s.width * 0.88, s.height * 0.88);
    canvas.drawLine(p0, p1, stroke(1.85));
  }

  @override
  bool shouldRepaint(covariant _SearchPainter old) => old.color != color;
}

class _BellPainter extends _StrokePainter {
  _BellPainter(super.color);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    final path = Path()
      ..moveTo(w * 0.34, h * 0.36)
      ..quadraticBezierTo(w * 0.34, h * 0.12, w * 0.5, h * 0.12)
      ..quadraticBezierTo(w * 0.66, h * 0.12, w * 0.66, h * 0.36)
      ..lineTo(w * 0.66, h * 0.62)
      ..lineTo(w * 0.34, h * 0.62)
      ..close();
    canvas.drawPath(path, stroke(1.75));
    canvas.drawLine(
      Offset(w * 0.38, h * 0.72),
      Offset(w * 0.62, h * 0.72),
      stroke(1.75),
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.82),
      w * 0.045,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _BellPainter old) => old.color != color;
}

class _PhonePainter extends _StrokePainter {
  _PhonePainter(super.color);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    final r = RRect.fromLTRBR(
      w * 0.34,
      h * 0.12,
      w * 0.66,
      h * 0.88,
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(r, stroke(1.75));
    canvas.drawLine(
      Offset(w * 0.42, h * 0.22),
      Offset(w * 0.58, h * 0.22),
      stroke(1.4),
    );
  }

  @override
  bool shouldRepaint(covariant _PhonePainter old) => old.color != color;
}

class _CheckPainter extends _StrokePainter {
  _CheckPainter(super.color);

  @override
  void paint(Canvas canvas, Size s) {
    final p = Path()
      ..moveTo(s.width * 0.2, s.height * 0.52)
      ..lineTo(s.width * 0.42, s.height * 0.72)
      ..lineTo(s.width * 0.82, s.height * 0.28);
    canvas.drawPath(p, stroke(2.0));
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.color != color;
}

class _CapsulePainter extends _StrokePainter {
  _CapsulePainter(super.color);

  @override
  void paint(Canvas canvas, Size s) {
    final r = RRect.fromLTRBR(
      s.width * 0.18,
      s.height * 0.32,
      s.width * 0.82,
      s.height * 0.68,
      Radius.circular(s.height * 0.18),
    );
    canvas.drawRRect(r, stroke(1.75));
  }

  @override
  bool shouldRepaint(covariant _CapsulePainter old) => old.color != color;
}

class _PencilPainter extends _StrokePainter {
  _PencilPainter(super.color);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    canvas.drawLine(
      Offset(w * 0.72, h * 0.18),
      Offset(w * 0.28, h * 0.62),
      stroke(1.85),
    );
    canvas.drawLine(
      Offset(w * 0.22, h * 0.68),
      Offset(w * 0.32, h * 0.78),
      stroke(1.85),
    );
  }

  @override
  bool shouldRepaint(covariant _PencilPainter old) => old.color != color;
}

class _PaperclipPainter extends _StrokePainter {
  _PaperclipPainter(super.color);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    final path = Path()
      ..moveTo(w * 0.72, h * 0.22)
      ..quadraticBezierTo(w * 0.38, h * 0.18, w * 0.28, h * 0.42)
      ..quadraticBezierTo(w * 0.22, h * 0.62, w * 0.38, h * 0.78)
      ..quadraticBezierTo(w * 0.58, h * 0.9, w * 0.72, h * 0.72);
    canvas.drawPath(path, stroke(1.75));
  }

  @override
  bool shouldRepaint(covariant _PaperclipPainter old) => old.color != color;
}

class _XMarkPainter extends _StrokePainter {
  _XMarkPainter(super.color);

  @override
  void paint(Canvas canvas, Size s) {
    final p = stroke(1.85);
    canvas.drawLine(Offset(s.width * 0.22, s.height * 0.22),
        Offset(s.width * 0.78, s.height * 0.78), p);
    canvas.drawLine(Offset(s.width * 0.78, s.height * 0.22),
        Offset(s.width * 0.22, s.height * 0.78), p);
  }

  @override
  bool shouldRepaint(covariant _XMarkPainter old) => old.color != color;
}

class _SendPainter extends _StrokePainter {
  _SendPainter(super.color);

  @override
  void paint(Canvas canvas, Size s) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(s.width * 0.22, s.height * 0.48)
      ..lineTo(s.width * 0.78, s.height * 0.28)
      ..lineTo(s.width * 0.55, s.height * 0.78)
      ..close();
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant _SendPainter old) => old.color != color;
}

class _LockPainter extends _StrokePainter {
  _LockPainter(super.color);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    final arc = Path()
      ..moveTo(w * 0.34, h * 0.42)
      ..quadraticBezierTo(w * 0.34, h * 0.18, w * 0.5, h * 0.18)
      ..quadraticBezierTo(w * 0.66, h * 0.18, w * 0.66, h * 0.42);
    canvas.drawPath(arc, stroke(1.75));
    final body = RRect.fromLTRBR(
      w * 0.28,
      h * 0.4,
      w * 0.72,
      h * 0.82,
      Radius.circular(2),
    );
    canvas.drawRRect(body, stroke(1.75));
  }

  @override
  bool shouldRepaint(covariant _LockPainter old) => old.color != color;
}

class _InfoPainter extends _StrokePainter {
  _InfoPainter(super.color);

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width * 0.5, s.height * 0.5);
    canvas.drawCircle(c, s.width * 0.36, stroke(1.75));
    canvas.drawLine(
      Offset(c.dx, c.dy - s.height * 0.14),
      Offset(c.dx, c.dy + s.height * 0.02),
      stroke(2.0)..strokeCap = StrokeCap.square,
    );
    canvas.drawCircle(Offset(c.dx, c.dy + s.height * 0.14), 1.4,
        Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _InfoPainter old) => old.color != color;
}

class _ChevronBackPainter extends _StrokePainter {
  _ChevronBackPainter(super.color);

  @override
  void paint(Canvas canvas, Size s) {
    final p = stroke(2.0);
    canvas.drawLine(
      Offset(s.width * 0.62, s.height * 0.22),
      Offset(s.width * 0.32, s.height * 0.5),
      p,
    );
    canvas.drawLine(
      Offset(s.width * 0.32, s.height * 0.5),
      Offset(s.width * 0.62, s.height * 0.78),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _ChevronBackPainter old) => old.color != color;
}
