import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../i18n.dart';

const _bg = Color(0xFF15171B);
const _amber = Color(0xFFFFC72C);
const _xray = Color(0xFF5BE7FF);

/// Branded loading screen: bags ride a baggage carousel through an X-ray gate
/// while a luggage tag swings in with the game title.
class SplashScreen extends StatefulWidget {
  /// True once the save has loaded; the bar then fills to the end.
  final bool ready;
  const SplashScreen({super.key, required this.ready});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))..repeat();
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();
  Timer? _phraseTimer;
  int _phrase = 0;

  static const _phrases = [
    'Weighing suitcases…',
    'Bribing the customs dog…',
    'Untangling the conveyor belt…',
    'Counting odd socks…',
    'Polishing fake watches…',
    'Waking up Gus…',
    'Peeling off hotel stickers…',
    'Guessing combination locks…',
  ];

  @override
  void initState() {
    super.initState();
    _phrase = Random().nextInt(_phrases.length);
    _phraseTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (mounted) setState(() => _phrase = (_phrase + 1) % _phrases.length);
    });
  }

  @override
  void dispose() {
    _phraseTimer?.cancel();
    _loop.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.35),
            radius: 1.1,
            colors: [Color(0xFF2A2416), _bg],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _intro,
                      builder: (context, _) {
                        final t = Curves.elasticOut.transform(const Interval(0, 0.6).transform(_intro.value));
                        final fade = const Interval(0, 0.2).transform(_intro.value);
                        return Opacity(
                          opacity: fade,
                          child: Transform.translate(
                            offset: Offset(0, -60 * (1 - t)),
                            child: Transform.rotate(
                              angle: (-0.42 + 0.35 * t),
                              alignment: Alignment.topLeft,
                              child: const _LuggageTag(),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: AnimatedBuilder(
                        animation: _loop,
                        builder: (context, _) => CustomPaint(painter: _CarouselPainter(_loop.value)),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 24,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
                            child: child,
                          ),
                        ),
                        child: Text(
                          tr(_phrases[_phrase]),
                          key: ValueKey(_phrase),
                          style: const TextStyle(color: Color(0xFFB9BCC4), fontSize: 15, letterSpacing: 0.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AnimatedBuilder(
                      animation: _intro,
                      builder: (context, _) {
                        final v = widget.ready ? 1.0 : 0.92 * Curves.easeOut.transform(_intro.value);
                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: v),
                          duration: const Duration(milliseconds: 250),
                          builder: (context, x, _) => ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: x,
                              minHeight: 6,
                              backgroundColor: const Color(0xFF2B2E35),
                              color: _amber,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LuggageTag extends StatelessWidget {
  const _LuggageTag();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      height: 118,
      child: CustomPaint(
        painter: _TagPainter(),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(62, 18, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'LOST',
                style: TextStyle(
                    color: _bg, fontSize: 34, height: 1, fontWeight: FontWeight.w900, letterSpacing: 6),
              ),
              Text(
                'LUGGAGE',
                style: TextStyle(
                    color: _bg, fontSize: 34, height: 1.05, fontWeight: FontWeight.w900, letterSpacing: 3),
              ),
              SizedBox(height: 6),
              Text(
                'CLAIM NO. LL-100000 · UNCLAIMED',
                style: TextStyle(color: Color(0xAA15171B), fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const cut = 26.0;
    final tag = Path()
      ..moveTo(cut, 0)
      ..lineTo(w - 12, 0)
      ..quadraticBezierTo(w, 0, w, 12)
      ..lineTo(w, h - 12)
      ..quadraticBezierTo(w, h, w - 12, h)
      ..lineTo(cut, h)
      ..lineTo(0, h - cut)
      ..lineTo(0, cut)
      ..close();
    canvas.drawShadow(tag, Colors.black, 10, false);
    canvas.drawPath(tag, Paint()..color = _amber);
    // perforated strip
    final dash = Paint()
      ..color = _bg.withAlpha(70)
      ..strokeWidth = 1.5;
    for (var y = 8.0; y < h - 8; y += 9) {
      canvas.drawLine(Offset(46, y), Offset(46, y + 4), dash);
    }
    // eyelet
    final c = Offset(22, h / 2);
    canvas.drawCircle(c, 9, Paint()..color = const Color(0xFFE0A21B));
    canvas.drawCircle(c, 5.5, Paint()..color = _bg);
    // string
    final string = Path()
      ..moveTo(c.dx, c.dy)
      ..cubicTo(-10, h / 2 - 20, -30, 10, -46, -18);
    canvas.drawPath(
      string,
      Paint()
        ..color = const Color(0xFFD8CDB5)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Bag {
  final double w;
  final double h;
  final Color color;
  final bool hardShell;
  final List<IconData> inside;
  final bool treasure;
  const _Bag(this.w, this.h, this.color, this.hardShell, this.inside, {this.treasure = false});
}

const _bags = [
  _Bag(64, 50, Color(0xFF3B78DB), true, [Icons.smartphone, Icons.checkroom]),
  _Bag(54, 38, Color(0xFFE5383B), false, [Icons.toys, Icons.menu_book]),
  _Bag(70, 56, Color(0xFF4E9A63), true, [Icons.watch, Icons.diamond], treasure: true),
  _Bag(50, 44, Color(0xFF9653CF), false, [Icons.headphones, Icons.local_cafe]),
];

class _CarouselPainter extends CustomPainter {
  final double t;
  _CarouselPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final beltTop = size.height - 44;
    const beltH = 22.0;

    // belt body
    final belt = RRect.fromRectAndRadius(Rect.fromLTWH(0, beltTop, w, beltH), const Radius.circular(11));
    canvas.drawRRect(belt, Paint()..color = const Color(0xFF262A31));
    canvas.save();
    canvas.clipRRect(belt);
    final slat = Paint()
      ..color = const Color(0xFF353A43)
      ..strokeWidth = 3;
    const gap = 16.0;
    final shift = (t * (w + 120)) % gap;
    for (var x = -gap + shift; x < w + gap; x += gap) {
      canvas.drawLine(Offset(x, beltTop + 3), Offset(x - 5, beltTop + beltH - 3), slat);
    }
    canvas.restore();
    // rollers and legs
    final leg = Paint()..color = const Color(0xFF1E2127);
    for (final fx in [0.12, 0.88]) {
      canvas.drawRect(Rect.fromLTWH(w * fx - 5, beltTop + beltH, 10, 22), leg);
    }
    final roller = Paint()..color = const Color(0xFF3F4550);
    for (var x = 14.0; x < w; x += 34) {
      canvas.drawCircle(Offset(x, beltTop + beltH + 4), 3, roller);
    }

    // bags
    final spacing = (w + 120) / _bags.length;
    final travel = w + 120;
    final gateW = 96.0;
    final gate = Rect.fromLTWH(w / 2 - gateW / 2, beltTop - 104, gateW, 104);
    for (var i = 0; i < _bags.length; i++) {
      final b = _bags[i];
      final x = ((t * travel + i * spacing) % travel) - 80;
      final r = Rect.fromLTWH(x, beltTop - b.h + 2, b.w, b.h);
      _drawBag(canvas, b, r);
    }

    // x-ray view inside the gate
    canvas.save();
    canvas.clipRect(gate);
    canvas.drawRect(gate, Paint()..color = const Color(0xFF0B1C2A));
    for (var i = 0; i < _bags.length; i++) {
      final b = _bags[i];
      final x = ((t * travel + i * spacing) % travel) - 80;
      final r = Rect.fromLTWH(x, beltTop - b.h + 2, b.w, b.h);
      if (r.overlaps(gate)) _drawXrayBag(canvas, b, r);
    }
    // scan beam
    final beamY = gate.top + 8 + (gate.height - 16) * (0.5 + 0.5 * sin(t * 2 * pi * 6));
    canvas.drawRect(
      Rect.fromLTWH(gate.left, beamY - 10, gate.width, 20),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_xray.withAlpha(0), _xray.withAlpha(90), _xray.withAlpha(0)],
        ).createShader(Rect.fromLTWH(gate.left, beamY - 10, gate.width, 20)),
    );
    canvas.drawLine(Offset(gate.left, beamY), Offset(gate.right, beamY), Paint()
      ..color = _xray
      ..strokeWidth = 1.2);
    canvas.restore();

    // gate frame
    final frame = Paint()..color = const Color(0xFF3A3F49);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(gate.left - 10, gate.top - 18, gate.width + 20, 20), const Radius.circular(6)),
        frame);
    canvas.drawRect(Rect.fromLTWH(gate.left - 10, gate.top, 10, gate.height + 2), frame);
    canvas.drawRect(Rect.fromLTWH(gate.right, gate.top, 10, gate.height + 2), frame);
    _text(canvas, 'X-RAY', Offset(gate.center.dx, gate.top - 8), 10, const Color(0xFFB9BCC4), bold: true);
    // status light: red when a treasure bag is inside, otherwise green
    var alarm = false;
    for (var i = 0; i < _bags.length; i++) {
      final b = _bags[i];
      final x = ((t * travel + i * spacing) % travel) - 80;
      if (b.treasure && Rect.fromLTWH(x, beltTop - b.h, b.w, b.h).overlaps(gate)) alarm = true;
    }
    final lamp = Offset(gate.right + 2, gate.top - 8);
    canvas.drawCircle(lamp, 7, Paint()..color = (alarm ? _amber : const Color(0xFF16A35A)).withAlpha(70));
    canvas.drawCircle(lamp, 3.5, Paint()..color = alarm ? _amber : const Color(0xFF3DDC84));
  }

  void _drawBag(Canvas canvas, _Bag b, Rect r) {
    final body = RRect.fromRectAndRadius(r, Radius.circular(b.hardShell ? 8 : 14));
    // handle
    final handle = Paint()
      ..color = const Color(0xFF1B1D22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(r.center.dx - 11, r.top - 9, 22, 14), const Radius.circular(5)), handle);
    canvas.drawRRect(body, Paint()..color = b.color);
    canvas.drawRRect(body, Paint()
      ..color = Colors.black.withAlpha(50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    if (b.hardShell) {
      final rib = Paint()
        ..color = Colors.white.withAlpha(45)
        ..strokeWidth = 2;
      for (var k = 1; k < 4; k++) {
        final x = r.left + r.width * k / 4;
        canvas.drawLine(Offset(x, r.top + 5), Offset(x, r.bottom - 5), rib);
      }
    } else {
      final strap = Paint()..color = Colors.black.withAlpha(60);
      canvas.drawRect(Rect.fromLTWH(r.left, r.center.dy - 3, r.width, 6), strap);
    }
    // hotel sticker
    canvas.drawCircle(Offset(r.left + r.width * 0.28, r.top + r.height * 0.35), r.height * 0.14,
        Paint()..color = const Color(0xFFF4E3B5));
  }

  void _drawXrayBag(Canvas canvas, _Bag b, Rect r) {
    final body = RRect.fromRectAndRadius(r, Radius.circular(b.hardShell ? 8 : 14));
    canvas.drawRRect(body, Paint()..color = _xray.withAlpha(30));
    canvas.drawRRect(body, Paint()
      ..color = _xray.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(r.center.dx - 11, r.top - 9, 22, 14), const Radius.circular(5)),
        Paint()
          ..color = _xray.withAlpha(150)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final n = b.inside.length;
    for (var k = 0; k < n; k++) {
      final c = Offset(r.left + r.width * (k + 1) / (n + 1), r.center.dy);
      final color = b.treasure && k == n - 1 ? _amber : _xray;
      if (b.treasure && k == n - 1) {
        canvas.drawCircle(c, r.height * 0.42, Paint()..color = _amber.withAlpha(60));
      }
      _icon(canvas, b.inside[k], c, r.height * 0.42, color);
    }
  }

  void _icon(Canvas canvas, IconData icon, Offset center, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: size, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _text(Canvas canvas, String s, Offset center, double size, Color color, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
            fontSize: size, color: color, letterSpacing: 2, fontWeight: bold ? FontWeight.w800 : FontWeight.w400),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _CarouselPainter old) => old.t != t;
}
