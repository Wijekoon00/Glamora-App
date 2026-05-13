import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum ArOverlayStyle { hairstyle, beard, hairColor }

// =============================================================================
// FaceScreenData — all coordinates already in screen space
// Computed once per frame in the camera page, not inside the painter
// =============================================================================
class FaceScreenData {
  final Rect box;           // bounding box in screen pixels
  final double yaw;         // head turn angle (degrees)
  final double roll;        // head tilt angle (degrees)
  final Map<FaceLandmarkType, Offset> landmarks;  // screen-space landmarks
  final List<Offset> contour;                     // screen-space face outline

  const FaceScreenData({
    required this.box,
    required this.yaw,
    required this.roll,
    required this.landmarks,
    required this.contour,
  });

  double get cx => box.center.dx;
  double get cy => box.center.dy;
  double get w  => box.width;
  double get h  => box.height;
}

// =============================================================================
// CoordTransformer — sensor space → screen space
// Used in the camera page where canvas size is known
// =============================================================================
class CoordTransformer {
  final Size imageSize;
  final Size canvasSize;
  final int  sensorDegrees;
  final bool isFrontCamera;

  late final double _sx, _sy, _ox, _oy;
  late final Size   _rotated;

  CoordTransformer({
    required this.imageSize,
    required this.canvasSize,
    required this.sensorDegrees,
    required this.isFrontCamera,
  }) {
    final bool r90 = sensorDegrees == 90 || sensorDegrees == 270;
    _rotated = r90 ? Size(imageSize.height, imageSize.width) : imageSize;

    final double ia = _rotated.width / _rotated.height;
    final double ca = canvasSize.width / canvasSize.height;

    double rW, rH;
    if (ia > ca) { rH = canvasSize.height; rW = rH * ia; }
    else         { rW = canvasSize.width;  rH = rW / ia; }

    _sx = rW / _rotated.width;
    _sy = rH / _rotated.height;
    _ox = (canvasSize.width  - rW) / 2;
    _oy = (canvasSize.height - rH) / 2;
  }

  Offset pt(double rawX, double rawY) {
    double x = rawX, y = rawY;

    // ML Kit returns coordinates already in the rotated portrait space
    // when InputImageMetadata rotation is set correctly.
    // We only need to mirror for front camera.
    if (isFrontCamera) {
      x = _rotated.width - x;
    }

    return Offset(x * _sx + _ox, y * _sy + _oy);
  }

  static int transformMode = 1;

  Rect rect(Rect r) => Rect.fromPoints(pt(r.left, r.top), pt(r.right, r.bottom));

  /// Convert a full Face into FaceScreenData
  FaceScreenData convert(Face face) {
    final box = rect(face.boundingBox);

    final lm = <FaceLandmarkType, Offset>{};
    for (final e in face.landmarks.entries) {
      final l = e.value;
      if (l != null) lm[e.key] = pt(l.position.x.toDouble(), l.position.y.toDouble());
    }

    final rawC = face.contours[FaceContourType.face];
    final contour = rawC != null
        ? rawC.points.map((p) => pt(p.x.toDouble(), p.y.toDouble())).toList()
        : <Offset>[];

    return FaceScreenData(
      box:       box,
      yaw:       face.headEulerAngleY ?? 0.0,
      roll:      face.headEulerAngleZ ?? 0.0,
      landmarks: lm,
      contour:   contour,
    );
  }
}

// =============================================================================
// SmoothedFaceState — lerps FaceScreenData between frames
// =============================================================================
class SmoothedFaceState {
  static const double _a = 0.40; // lerp factor: higher = snappier

  double left, top, right, bottom;
  double yaw, roll;
  final Map<FaceLandmarkType, Offset> landmarks = {};
  List<Offset> contour = [];

  SmoothedFaceState.fromData(FaceScreenData d)
      : left   = d.box.left,
        top    = d.box.top,
        right  = d.box.right,
        bottom = d.box.bottom,
        yaw    = d.yaw,
        roll   = d.roll {
    landmarks.addAll(d.landmarks);
    contour = List.from(d.contour);
  }

  static double _l(double a, double b) => a + (b - a) * _a;
  static Offset _lo(Offset a, Offset b) => Offset(_l(a.dx, b.dx), _l(a.dy, b.dy));

  void update(FaceScreenData d) {
    left   = _l(left,   d.box.left);
    top    = _l(top,    d.box.top);
    right  = _l(right,  d.box.right);
    bottom = _l(bottom, d.box.bottom);
    yaw    = _l(yaw,    d.yaw);
    roll   = _l(roll,   d.roll);

    for (final e in d.landmarks.entries) {
      final prev = landmarks[e.key];
      landmarks[e.key] = prev == null ? e.value : _lo(prev, e.value);
    }

    if (d.contour.length == contour.length && contour.isNotEmpty) {
      for (int i = 0; i < contour.length; i++) {
        contour[i] = _lo(contour[i], d.contour[i]);
      }
    } else {
      contour = List.from(d.contour);
    }
  }

  Rect   get box    => Rect.fromLTRB(left, top, right, bottom);
  double get cx     => (left + right) / 2;
  double get cy     => (top + bottom) / 2;
  double get w      => right - left;
  double get h      => bottom - top;
}

// =============================================================================
// ArFacePainter — pure drawing, zero coordinate math
// =============================================================================
class ArFacePainter extends CustomPainter {
  final List<SmoothedFaceState> states;
  final ArOverlayStyle overlayStyle;
  final String styleName;
  final Color  hairColor;
  final bool   debugMode;

  const ArFacePainter({
    required this.states,
    required this.overlayStyle,
    required this.styleName,
    required this.hairColor,
    this.debugMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in states) {
      if (debugMode) _drawDebug(canvas, s);

      _withRoll(canvas, s, () {
        switch (overlayStyle) {
          case ArOverlayStyle.hairstyle:  _drawHair(canvas, s);      break;
          case ArOverlayStyle.beard:      _drawBeard(canvas, s);     break;
          case ArOverlayStyle.hairColor:  _drawHairColor(canvas, s); break;
        }
      });

      _drawContourGuide(canvas, s);
    }
  }

  // ── Roll transform ──────────────────────────────────────────────────────────
  void _withRoll(Canvas canvas, SmoothedFaceState s, VoidCallback fn) {
    final rad = -s.roll * math.pi / 180.0;
    if (rad.abs() < 0.01) { fn(); return; }
    canvas.save();
    canvas.translate(s.cx, s.cy);
    canvas.rotate(rad);
    canvas.translate(-s.cx, -s.cy);
    fn();
    canvas.restore();
  }

  // ── Debug: bright red box + landmarks ──────────────────────────────────────
  void _drawDebug(Canvas canvas, SmoothedFaceState s) {
    // Red bounding box
    canvas.drawRect(s.box, Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke);

    // Green dots on every landmark
    for (final pt in s.landmarks.values) {
      canvas.drawCircle(pt, 5, Paint()..color = Colors.green);
    }

    // Blue dots on contour
    for (final pt in s.contour) {
      canvas.drawCircle(pt, 3, Paint()..color = Colors.blue);
    }

    // Yaw/roll text
    _label(canvas, 'yaw:${s.yaw.toStringAsFixed(1)} roll:${s.roll.toStringAsFixed(1)}',
        Offset(s.cx, s.top - 20), color: Colors.red);
  }

  // ── Hair overlay ────────────────────────────────────────────────────────────
  void _drawHair(Canvas canvas, SmoothedFaceState s) {
    final lm = s.landmarks;
    final leftEar  = lm[FaceLandmarkType.leftEar];
    final rightEar = lm[FaceLandmarkType.rightEar];
    final leftEye  = lm[FaceLandmarkType.leftEye];
    final rightEye = lm[FaceLandmarkType.rightEye];

    // Face width — prefer ear landmarks, fall back to bounding box
    double fL = leftEar?.dx  ?? s.left;
    double fR = rightEar?.dx ?? s.right;

    // Yaw perspective
    final double yf = (s.yaw / 90.0).clamp(-1.0, 1.0);
    final double fw = fR - fL;
    final double shift = fw * yf * 0.16;
    final double scale = 1.0 - yf.abs() * 0.22;
    final double cx = s.cx + shift;
    fL = cx - (fw * scale) / 2;
    fR = cx + (fw * scale) / 2;
    final double ew = fR - fL; // effective width after perspective

    // Forehead Y — use contour top points if available
    double foreY = s.top;
    if (s.contour.isNotEmpty) {
      final tops = s.contour.where((p) => p.dy < s.cy).toList();
      if (tops.isNotEmpty) foreY = tops.map((p) => p.dy).reduce(math.min);
    } else if (leftEye != null && rightEye != null) {
      final ey = (leftEye.dy + rightEye.dy) / 2;
      foreY = ey - (ey - s.top) * 1.15;
    }

    // Style-specific proportions
    double hH, hW, curve;
    if (_has(['Fade','Undercut','Crop','Buzz','Taper','French'])) {
      hH = ew * 0.18; hW = ew * 0.80; curve = hH * 0.30;
    } else if (_has(['Pompadour','Quiff','Faux Hawk','Mohawk'])) {
      hH = ew * 0.55; hW = ew * 0.70; curve = hH * 0.70;
    } else if (_has(['Bob','Lob','Bixie','Blunt'])) {
      hH = ew * 0.24; hW = ew * 1.20; curve = hH * 0.25;
    } else if (_has(['Wavy','Curly','Afro','Natural','Shag'])) {
      hH = ew * 0.46; hW = ew * 1.10; curve = hH * 0.50;
    } else {
      hH = ew * 0.34; hW = ew * 0.98; curve = hH * 0.42;
    }
    hW *= scale;

    final double top = foreY - hH;

    // Dome path
    final path = Path()
      ..moveTo(cx - hW / 2, foreY)
      ..cubicTo(cx - hW / 2, foreY - curve, cx - hW * 0.07, top, cx, top)
      ..cubicTo(cx + hW * 0.07, top, cx + hW / 2, foreY - curve, cx + hW / 2, foreY)
      ..close();

    canvas.drawPath(path, Paint()
      ..shader = ui.Gradient.linear(
          Offset(cx, foreY), Offset(cx, top),
          [hairColor.withAlpha(225), hairColor.withAlpha(95)])
      ..style = PaintingStyle.fill);

    // Side hair with yaw-based alpha
    _sideHair(canvas, s, fL, fR, foreY, hW, cx, yf);
    _label(canvas, _short, Offset(cx, top - 16));
  }

  void _sideHair(Canvas canvas, SmoothedFaceState s,
      double fL, double fR, double foreY, double hW, double cx, double yf) {
    final sH = s.h * 0.30;
    final sW = hW * 0.09;
    final aL = (1.0 - yf).clamp(0.15, 1.0);
    final aR = (1.0 + yf).clamp(0.15, 1.0);

    for (final isLeft in [true, false]) {
      final alpha = isLeft ? aL : aR;
      final ax = isLeft ? fL : fR;
      final ox = isLeft ? ax - sW : ax + sW;
      final p = Path()
        ..moveTo(ax, foreY)
        ..quadraticBezierTo(ox, foreY + sH * 0.5,
            isLeft ? ox + sW * 0.3 : ox - sW * 0.3, foreY + sH)
        ..quadraticBezierTo(ax, foreY + sH * 0.6, ax, foreY);
      canvas.drawPath(p, Paint()
        ..color = hairColor.withAlpha((155 * alpha).round())
        ..style = PaintingStyle.fill);
    }
  }

  // ── Beard overlay ───────────────────────────────────────────────────────────
  void _drawBeard(Canvas canvas, SmoothedFaceState s) {
    final lm = s.landmarks;
    final lMouth = lm[FaceLandmarkType.leftMouth];
    final rMouth = lm[FaceLandmarkType.rightMouth];
    final bMouth = lm[FaceLandmarkType.bottomMouth];
    final lCheek = lm[FaceLandmarkType.leftCheek];
    final rCheek = lm[FaceLandmarkType.rightCheek];

    final double yf    = (s.yaw / 90.0).clamp(-1.0, 1.0);
    final double shift = s.w * yf * 0.10;
    final double scale = 1.0 - yf.abs() * 0.18;
    final double cx    = s.cx + shift;
    final double fw    = s.w * scale;

    final double mY  = bMouth?.dy ?? (s.top + s.h * 0.73);
    final double chY = s.bottom - s.h * 0.03;

    double mL = (lMouth?.dx ?? (cx - fw * 0.17)) + shift;
    double mR = (rMouth?.dx ?? (cx + fw * 0.17)) + shift;
    double cL = (lCheek?.dx ?? (s.left  + fw * 0.07)) + shift;
    double cR = (rCheek?.dx ?? (s.right - fw * 0.07)) + shift;

    if (yf > 0) {
      mL = cx - (cx - mL) * (1 - yf * 0.28);
      cL = cx - (cx - cL) * (1 - yf * 0.28);
    } else {
      mR = cx + (mR - cx) * (1 + yf * 0.28);
      cR = cx + (cR - cx) * (1 + yf * 0.28);
    }

    if (_has(['Goatee','Chin Strap','Extended Goatee','Chin Curtain'])) {
      _goatee(canvas, cx, mY, chY, fw);
    } else if (_has(['Stubble','Light','3-5 day','Clean Shave'])) {
      _stubble(canvas, s, mY, cL, cR);
    } else {
      _fullBeard(canvas, cx, mL, mR, mY, chY, cL, cR, fw);
    }
    _label(canvas, _short, Offset(cx, s.bottom + 14));
  }

  void _goatee(Canvas canvas, double cx, double mY, double chY, double fw) {
    final w = fw * 0.19;
    final p = Path()
      ..moveTo(cx - w, mY)
      ..quadraticBezierTo(cx - w * 1.1, (mY + chY) / 2, cx, chY)
      ..quadraticBezierTo(cx + w * 1.1, (mY + chY) / 2, cx + w, mY)
      ..quadraticBezierTo(cx, mY + (chY - mY) * 0.22, cx - w, mY);
    canvas.drawPath(p, Paint()
      ..shader = ui.Gradient.linear(Offset(cx, mY), Offset(cx, chY),
          [hairColor.withAlpha(215), hairColor.withAlpha(85)])
      ..style = PaintingStyle.fill);
  }

  void _stubble(Canvas canvas, SmoothedFaceState s,
      double mY, double cL, double cR) {
    final rng = math.Random(42);
    final btm = s.bottom - s.h * 0.04;
    final p = Paint()..color = hairColor.withAlpha(90)..style = PaintingStyle.fill;
    for (double x = cL; x < cR; x += 5) {
      for (double y = mY - s.h * 0.06; y < btm; y += 5) {
        if (rng.nextDouble() > 0.42) {
          canvas.drawCircle(
            Offset(x + rng.nextDouble() * 3, y + rng.nextDouble() * 3),
            0.85 + rng.nextDouble() * 0.9, p);
        }
      }
    }
  }

  void _fullBeard(Canvas canvas, double cx,
      double mL, double mR, double mY, double chY,
      double cL, double cR, double fw) {
    final p = Path()
      ..moveTo(cL, mY - fw * 0.04)
      ..cubicTo(cL, mY + (chY - mY) * 0.4, cx - fw * 0.23, chY, cx, chY)
      ..cubicTo(cx + fw * 0.23, chY, cR, mY + (chY - mY) * 0.4, cR, mY - fw * 0.04)
      ..quadraticBezierTo(cx, mY + fw * 0.03, cL, mY - fw * 0.04);
    canvas.drawPath(p, Paint()
      ..shader = ui.Gradient.radial(Offset(cx, (mY + chY) / 2), fw * 0.43,
          [hairColor.withAlpha(210), hairColor.withAlpha(60)])
      ..style = PaintingStyle.fill);
    _moustache(canvas, cx, mL, mR, mY, fw);
  }

  void _moustache(Canvas canvas, double cx,
      double mL, double mR, double mY, double fw) {
    final tY = mY - fw * 0.086;
    final p = Path()
      ..moveTo(mL - fw * 0.04, mY)
      ..cubicTo(mL, tY, cx - fw * 0.04, tY + fw * 0.02, cx, tY + fw * 0.03)
      ..cubicTo(cx + fw * 0.04, tY + fw * 0.02, mR, tY, mR + fw * 0.04, mY)
      ..quadraticBezierTo(cx, mY + fw * 0.02, mL - fw * 0.04, mY);
    canvas.drawPath(p, Paint()
      ..color = hairColor.withAlpha(200)..style = PaintingStyle.fill);
  }

  // ── Hair color overlay ──────────────────────────────────────────────────────
  void _drawHairColor(Canvas canvas, SmoothedFaceState s) {
    final lm = s.landmarks;
    final lEye = lm[FaceLandmarkType.leftEye];
    final rEye = lm[FaceLandmarkType.rightEye];

    final double yf    = (s.yaw / 90.0).clamp(-1.0, 1.0);
    final double shift = s.w * yf * 0.13;
    final double scale = 1.0 - yf.abs() * 0.20;
    final double cx    = s.cx + shift;
    final double fw    = s.w * scale;

    double foreY = s.top;
    if (s.contour.isNotEmpty) {
      final tops = s.contour.where((p) => p.dy < s.cy).toList();
      if (tops.isNotEmpty) foreY = tops.map((p) => p.dy).reduce(math.min);
    } else if (lEye != null && rEye != null) {
      final ey = (lEye.dy + rEye.dy) / 2;
      foreY = ey - (ey - s.top) * 1.25;
    }

    final double hTop = foreY - fw * 0.36;
    final double hw   = fw * 0.52;

    final p = Path()
      ..moveTo(cx - hw, foreY)
      ..cubicTo(cx - hw, foreY - fw * 0.26, cx - fw * 0.08, hTop, cx, hTop)
      ..cubicTo(cx + fw * 0.08, hTop, cx + hw, foreY - fw * 0.26, cx + hw, foreY)
      ..close();

    canvas.drawPath(p, Paint()
      ..shader = ui.Gradient.radial(Offset(cx, foreY - fw * 0.16), fw * 0.56,
          [hairColor.withAlpha(180), hairColor.withAlpha(50)])
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver);

    _label(canvas, _short, Offset(cx, hTop - 16));
  }

  // ── Face contour guide ──────────────────────────────────────────────────────
  void _drawContourGuide(Canvas canvas, SmoothedFaceState s) {
    final paint = Paint()
      ..color = const Color(0xFF9D4EDD).withAlpha(90)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (s.contour.length >= 3) {
      final path = Path()..moveTo(s.contour[0].dx, s.contour[0].dy);
      for (int i = 1; i < s.contour.length; i++) {
        path.lineTo(s.contour[i].dx, s.contour[i].dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    } else {
      canvas.drawOval(s.box, paint);
    }
  }

  // ── Label ───────────────────────────────────────────────────────────────────
  void _label(Canvas canvas, String text, Offset pos,
      {Color color = const Color(0xFFEDD97A)}) {
    final tp = TextPainter(
      text: TextSpan(text: text,
          style: TextStyle(color: color, fontSize: 11,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(color: Colors.black, blurRadius: 5)])),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy));
  }

  bool _has(List<String> kw) =>
      kw.any((k) => styleName.toLowerCase().contains(k.toLowerCase()));

  String get _short {
    final p = styleName.split(' ');
    return p.length > 4 ? p.take(4).join(' ') : styleName;
  }

  @override
  bool shouldRepaint(ArFacePainter old) =>
      old.states != states ||
      old.overlayStyle != overlayStyle ||
      old.styleName != styleName ||
      old.hairColor != hairColor ||
      old.debugMode != debugMode;
}
