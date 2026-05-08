import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum ArOverlayStyle { hairstyle, beard, hairColor }

// =============================================================================
// SmoothedFaceState — lerps face data between frames to eliminate jitter
// =============================================================================
class SmoothedFaceState {
  // Smoothed bounding box corners
  double left, top, right, bottom;

  // Smoothed Euler angles (head rotation)
  double yaw;   // headEulerAngleY: + = face turned right, - = turned left
  double roll;  // headEulerAngleZ: + = tilted right, - = tilted left

  // Smoothed landmark positions
  final Map<FaceLandmarkType, Offset> landmarks = {};

  // Smoothed contour points (face outline — 36 points)
  List<Offset> faceContour = [];

  SmoothedFaceState({
    required this.left, required this.top,
    required this.right, required this.bottom,
    required this.yaw, required this.roll,
  });

  // Linear interpolation factor — higher = snappier, lower = smoother
  static const double _alpha = 0.35;

  static double _lerp(double a, double b) => a + (b - a) * _alpha;
  static Offset _lerpOffset(Offset a, Offset b) =>
      Offset(_lerp(a.dx, b.dx), _lerp(a.dy, b.dy));

  /// Update this state by lerping toward the new raw face data.
  void update(Face face, _CoordTransformer t) {
    final box = t.transformRect(face.boundingBox);

    left   = _lerp(left,   box.left);
    top    = _lerp(top,    box.top);
    right  = _lerp(right,  box.right);
    bottom = _lerp(bottom, box.bottom);

    yaw  = _lerp(yaw,  face.headEulerAngleY ?? 0.0);
    roll = _lerp(roll, face.headEulerAngleZ ?? 0.0);

    // Smooth landmarks
    for (final entry in face.landmarks.entries) {
      final lm = entry.value;
      if (lm == null) continue;
      final raw = t.transform(lm.position.x.toDouble(), lm.position.y.toDouble());
      final prev = landmarks[entry.key];
      landmarks[entry.key] = prev == null ? raw : _lerpOffset(prev, raw);
    }

    // Smooth face contour
    final rawContour = face.contours[FaceContourType.face];
    if (rawContour != null && rawContour.points.isNotEmpty) {
      final rawPts = rawContour.points
          .map((p) => t.transform(p.x.toDouble(), p.y.toDouble()))
          .toList();

      if (faceContour.length != rawPts.length) {
        faceContour = rawPts;
      } else {
        for (int i = 0; i < rawPts.length; i++) {
          faceContour[i] = _lerpOffset(faceContour[i], rawPts[i]);
        }
      }
    }
  }

  Rect get rect => Rect.fromLTRB(left, top, right, bottom);
  double get width  => right - left;
  double get height => bottom - top;
  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;
}

// =============================================================================
// Coordinate transformer — sensor space → screen space
// =============================================================================
class _CoordTransformer {
  final Size imageSize;
  final Size canvasSize;
  final int sensorDegrees;
  final bool isFrontCamera;

  late final double _scaleX, _scaleY, _offsetX, _offsetY;
  late final Size _rotatedImageSize;

  _CoordTransformer({
    required this.imageSize,
    required this.canvasSize,
    required this.sensorDegrees,
    required this.isFrontCamera,
  }) {
    final bool rot90 = sensorDegrees == 90 || sensorDegrees == 270;
    _rotatedImageSize = rot90
        ? Size(imageSize.height, imageSize.width)
        : imageSize;

    final double imgAspect = _rotatedImageSize.width / _rotatedImageSize.height;
    final double canAspect = canvasSize.width / canvasSize.height;

    double rW, rH;
    if (imgAspect > canAspect) {
      rH = canvasSize.height; rW = rH * imgAspect;
    } else {
      rW = canvasSize.width; rH = rW / imgAspect;
    }

    _scaleX  = rW / _rotatedImageSize.width;
    _scaleY  = rH / _rotatedImageSize.height;
    _offsetX = (canvasSize.width  - rW) / 2;
    _offsetY = (canvasSize.height - rH) / 2;
  }

  Offset transform(double rawX, double rawY) {
    double x = rawX, y = rawY;
    switch (sensorDegrees) {
      case 90:
        final tmp = x; x = y; y = imageSize.width - tmp;
        break;
      case 270:
        final tmp = y; y = x; x = imageSize.height - tmp;
        break;
      case 180:
        x = imageSize.width - x; y = imageSize.height - y;
        break;
    }
    if (isFrontCamera) x = _rotatedImageSize.width - x;
    return Offset(x * _scaleX + _offsetX, y * _scaleY + _offsetY);
  }

  Rect transformRect(Rect r) =>
      Rect.fromPoints(transform(r.left, r.top), transform(r.right, r.bottom));
}

// =============================================================================
// ArFacePainter — draws rotation-aware, smoothed AR overlays
// =============================================================================
class ArFacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final ArOverlayStyle overlayStyle;
  final String styleName;
  final Color hairColor;
  final int sensorDegrees;
  final bool isFrontCamera;

  // Smoothed state — persisted across repaints via the camera page
  final List<SmoothedFaceState> smoothedStates;

  const ArFacePainter({
    required this.faces,
    required this.imageSize,
    required this.overlayStyle,
    required this.styleName,
    required this.hairColor,
    required this.smoothedStates,
    this.sensorDegrees = 90,
    this.isFrontCamera = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (faces.isEmpty || smoothedStates.isEmpty) return;

    final t = _CoordTransformer(
      imageSize: imageSize,
      canvasSize: size,
      sensorDegrees: sensorDegrees,
      isFrontCamera: isFrontCamera,
    );

    // Update smoothed states with new face data
    for (int i = 0; i < faces.length && i < smoothedStates.length; i++) {
      smoothedStates[i].update(faces[i], t);
    }

    for (final state in smoothedStates) {
      // Apply canvas rotation for head roll
      _withRollTransform(canvas, state, () {
        switch (overlayStyle) {
          case ArOverlayStyle.hairstyle:
            _drawHair(canvas, state);
            break;
          case ArOverlayStyle.beard:
            _drawBeard(canvas, state);
            break;
          case ArOverlayStyle.hairColor:
            _drawHairColor(canvas, state);
            break;
        }
      });

      _drawFaceContourGuide(canvas, state);
      _drawRotationHUD(canvas, state);
    }
  }

  // ---------------------------------------------------------------------------
  // Roll transform — rotates the canvas around the face center so overlays
  // tilt with the head
  // ---------------------------------------------------------------------------
  void _withRollTransform(Canvas canvas, SmoothedFaceState s, VoidCallback draw) {
    final rollRad = -s.roll * math.pi / 180.0;
    if (rollRad.abs() < 0.01) {
      draw();
      return;
    }
    canvas.save();
    canvas.translate(s.centerX, s.centerY);
    canvas.rotate(rollRad);
    canvas.translate(-s.centerX, -s.centerY);
    draw();
    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // HAIR OVERLAY
  // Uses: contour forehead points, ear landmarks, yaw for perspective
  // ---------------------------------------------------------------------------
  void _drawHair(Canvas canvas, SmoothedFaceState s) {
    final lm = s.landmarks;

    // ── Anchor points ──────────────────────────────────────────────────────
    // Use ear landmarks for face width (most accurate)
    final leftEar  = lm[FaceLandmarkType.leftEar];
    final rightEar = lm[FaceLandmarkType.rightEar];
    final leftEye  = lm[FaceLandmarkType.leftEye];
    final rightEye = lm[FaceLandmarkType.rightEye];

    double faceLeft  = leftEar?.dx  ?? s.left;
    double faceRight = rightEar?.dx ?? s.right;

    // ── Yaw perspective ────────────────────────────────────────────────────
    // When face turns, the near side appears wider, far side narrower.
    // yaw > 0 = face turned right (from camera's view)
    final double yawFactor = s.yaw / 90.0; // -1 to +1
    final double faceW = faceRight - faceLeft;

    // Shift center and compress width based on yaw
    final double perspShift = faceW * yawFactor * 0.18;
    final double perspScale = 1.0 - (yawFactor.abs() * 0.25);

    final double cx = s.centerX + perspShift;
    final double halfW = (faceW * perspScale) / 2;
    faceLeft  = cx - halfW;
    faceRight = cx + halfW;

    // ── Forehead Y from contour ────────────────────────────────────────────
    // The face contour has ~36 points. The top points (indices ~8-10 in a
    // 36-point contour) are the forehead. We take the minimum Y.
    double foreheadY = s.top;
    if (s.faceContour.isNotEmpty) {
      // Top third of contour points = forehead area
      final topPts = s.faceContour
          .where((p) => p.dy < s.centerY)
          .toList();
      if (topPts.isNotEmpty) {
        foreheadY = topPts.map((p) => p.dy).reduce(math.min);
      }
    } else if (leftEye != null && rightEye != null) {
      final eyeY = (leftEye.dy + rightEye.dy) / 2;
      foreheadY = eyeY - (eyeY - s.top) * 1.2;
    }

    // ── Style dimensions ───────────────────────────────────────────────────
    final double fw = faceRight - faceLeft;
    double hairH, hairW, topCurve;

    if (_has(['Fade', 'Undercut', 'Crop', 'Buzz', 'Taper'])) {
      hairH = fw * 0.20; hairW = fw * 0.82; topCurve = hairH * 0.35;
    } else if (_has(['Pompadour', 'Quiff', 'Faux Hawk', 'Mohawk'])) {
      hairH = fw * 0.58; hairW = fw * 0.72; topCurve = hairH * 0.72;
    } else if (_has(['Bob', 'Lob', 'Bixie', 'Blunt'])) {
      hairH = fw * 0.26; hairW = fw * 1.22; topCurve = hairH * 0.28;
    } else if (_has(['Wavy', 'Curly', 'Afro', 'Natural'])) {
      hairH = fw * 0.48; hairW = fw * 1.12; topCurve = hairH * 0.52;
    } else if (_has(['Slick', 'Back', 'Pompadour'])) {
      hairH = fw * 0.32; hairW = fw * 0.90; topCurve = hairH * 0.55;
    } else {
      hairH = fw * 0.36; hairW = fw * 1.0; topCurve = hairH * 0.44;
    }

    // Apply yaw compression to hair width too
    hairW *= perspScale;

    final double hairTop = foreheadY - hairH;

    // ── Build dome path ────────────────────────────────────────────────────
    final path = Path();
    path.moveTo(cx - hairW / 2, foreheadY);
    path.cubicTo(
      cx - hairW / 2, foreheadY - topCurve,
      cx - hairW * 0.08, hairTop,
      cx, hairTop,
    );
    path.cubicTo(
      cx + hairW * 0.08, hairTop,
      cx + hairW / 2, foreheadY - topCurve,
      cx + hairW / 2, foreheadY,
    );
    path.close();

    // ── Gradient: dense at roots, fades at tips ────────────────────────────
    final gradient = ui.Gradient.linear(
      Offset(cx, foreheadY),
      Offset(cx, hairTop),
      [hairColor.withAlpha(220), hairColor.withAlpha(100)],
    );
    canvas.drawPath(path, Paint()..shader = gradient..style = PaintingStyle.fill);

    // ── Side hair ──────────────────────────────────────────────────────────
    _drawSideHair(canvas, s, faceLeft, faceRight, foreheadY, hairW, cx);

    // ── Style label ────────────────────────────────────────────────────────
    _drawLabel(canvas, _shortName, Offset(cx, hairTop - 14));
  }

  void _drawSideHair(Canvas canvas, SmoothedFaceState s,
      double faceLeft, double faceRight, double foreheadY,
      double hairW, double cx) {
    final sideH = s.height * 0.32;
    final sideW = hairW * 0.10;

    // Yaw hides the far side and shows the near side more
    final double yawFactor = s.yaw / 90.0;
    final double leftAlpha  = (1.0 - yawFactor).clamp(0.2, 1.0);
    final double rightAlpha = (1.0 + yawFactor).clamp(0.2, 1.0);

    void drawSide(bool isLeft) {
      final double alpha = isLeft ? leftAlpha : rightAlpha;
      final double anchorX = isLeft ? faceLeft : faceRight;
      final double outX = isLeft
          ? anchorX - sideW
          : anchorX + sideW;

      final p = Path();
      p.moveTo(anchorX, foreheadY);
      p.quadraticBezierTo(outX, foreheadY + sideH * 0.5,
          isLeft ? outX + sideW * 0.3 : outX - sideW * 0.3,
          foreheadY + sideH);
      p.quadraticBezierTo(anchorX, foreheadY + sideH * 0.6, anchorX, foreheadY);

      canvas.drawPath(p, Paint()
        ..color = hairColor.withAlpha((160 * alpha).round())
        ..style = PaintingStyle.fill);
    }

    drawSide(true);
    drawSide(false);
  }

  // ---------------------------------------------------------------------------
  // BEARD OVERLAY
  // Uses: mouth landmarks, cheek landmarks, yaw for perspective
  // ---------------------------------------------------------------------------
  void _drawBeard(Canvas canvas, SmoothedFaceState s) {
    final lm = s.landmarks;

    final leftMouth   = lm[FaceLandmarkType.leftMouth];
    final rightMouth  = lm[FaceLandmarkType.rightMouth];
    final bottomMouth = lm[FaceLandmarkType.bottomMouth];
    final leftCheek   = lm[FaceLandmarkType.leftCheek];
    final rightCheek  = lm[FaceLandmarkType.rightCheek];

    // Yaw perspective on beard
    final double yawFactor = s.yaw / 90.0;
    final double perspShift = s.width * yawFactor * 0.12;
    final double perspScale = 1.0 - (yawFactor.abs() * 0.20);

    final double cx = s.centerX + perspShift;
    final double mouthY  = bottomMouth?.dy ?? (s.top + s.height * 0.72);
    final double chinY   = s.bottom - s.height * 0.03;
    final double fw      = s.width * perspScale;

    double mouthLeft  = (leftMouth?.dx  ?? (cx - fw * 0.18)) + perspShift;
    double mouthRight = (rightMouth?.dx ?? (cx + fw * 0.18)) + perspShift;
    double cheekLeft  = (leftCheek?.dx  ?? (s.left  + fw * 0.08)) + perspShift;
    double cheekRight = (rightCheek?.dx ?? (s.right - fw * 0.08)) + perspShift;

    // Compress the far side
    if (yawFactor > 0) {
      // Face turned right — left side compressed
      mouthLeft  = cx - (cx - mouthLeft)  * (1 - yawFactor * 0.3);
      cheekLeft  = cx - (cx - cheekLeft)  * (1 - yawFactor * 0.3);
    } else {
      // Face turned left — right side compressed
      mouthRight = cx + (mouthRight - cx) * (1 + yawFactor * 0.3);
      cheekRight = cx + (cheekRight - cx) * (1 + yawFactor * 0.3);
    }

    if (_has(['Goatee', 'Chin Strap', 'Extended Goatee', 'Chin Curtain'])) {
      _drawGoatee(canvas, cx, mouthY, chinY, fw);
    } else if (_has(['Stubble', 'Light', '3-5 day', 'Clean'])) {
      _drawStubble(canvas, s, mouthY, cheekLeft, cheekRight);
    } else {
      _drawFullBeard(canvas, cx, mouthLeft, mouthRight,
          mouthY, chinY, cheekLeft, cheekRight, fw);
    }

    _drawLabel(canvas, _shortName, Offset(cx, s.bottom + 12));
  }

  void _drawGoatee(Canvas canvas, double cx, double mouthY,
      double chinY, double fw) {
    final w = fw * 0.20;
    final path = Path();
    path.moveTo(cx - w, mouthY);
    path.quadraticBezierTo(cx - w * 1.1, (mouthY + chinY) / 2, cx, chinY);
    path.quadraticBezierTo(cx + w * 1.1, (mouthY + chinY) / 2, cx + w, mouthY);
    path.quadraticBezierTo(cx, mouthY + (chinY - mouthY) * 0.25, cx - w, mouthY);

    canvas.drawPath(path, Paint()
      ..shader = ui.Gradient.linear(
          Offset(cx, mouthY), Offset(cx, chinY),
          [hairColor.withAlpha(210), hairColor.withAlpha(90)])
      ..style = PaintingStyle.fill);
  }

  void _drawStubble(Canvas canvas, SmoothedFaceState s,
      double mouthY, double cheekLeft, double cheekRight) {
    final rng = math.Random(42);
    final bottom = s.bottom - s.height * 0.04;
    final paint = Paint()
      ..color = hairColor.withAlpha(95)
      ..style = PaintingStyle.fill;

    for (double x = cheekLeft; x < cheekRight; x += 5) {
      for (double y = mouthY - s.height * 0.06; y < bottom; y += 5) {
        if (rng.nextDouble() > 0.42) {
          canvas.drawCircle(
            Offset(x + rng.nextDouble() * 3, y + rng.nextDouble() * 3),
            0.9 + rng.nextDouble() * 0.9,
            paint,
          );
        }
      }
    }
  }

  void _drawFullBeard(Canvas canvas, double cx,
      double mouthLeft, double mouthRight,
      double mouthY, double chinY,
      double cheekLeft, double cheekRight, double fw) {
    final path = Path();
    path.moveTo(cheekLeft, mouthY - fw * 0.04);
    path.cubicTo(cheekLeft, mouthY + (chinY - mouthY) * 0.4,
        cx - fw * 0.24, chinY, cx, chinY);
    path.cubicTo(cx + fw * 0.24, chinY,
        cheekRight, mouthY + (chinY - mouthY) * 0.4,
        cheekRight, mouthY - fw * 0.04);
    path.quadraticBezierTo(cx, mouthY + fw * 0.03,
        cheekLeft, mouthY - fw * 0.04);

    canvas.drawPath(path, Paint()
      ..shader = ui.Gradient.radial(
          Offset(cx, (mouthY + chinY) / 2), fw * 0.44,
          [hairColor.withAlpha(205), hairColor.withAlpha(65)])
      ..style = PaintingStyle.fill);

    _drawMoustache(canvas, cx, mouthLeft, mouthRight, mouthY, fw);
  }

  void _drawMoustache(Canvas canvas, double cx,
      double ml, double mr, double mouthY, double fw) {
    final topY = mouthY - fw * 0.088;
    final path = Path();
    path.moveTo(ml - fw * 0.04, mouthY);
    path.cubicTo(ml, topY, cx - fw * 0.04, topY + fw * 0.02, cx, topY + fw * 0.03);
    path.cubicTo(cx + fw * 0.04, topY + fw * 0.02, mr, topY, mr + fw * 0.04, mouthY);
    path.quadraticBezierTo(cx, mouthY + fw * 0.02, ml - fw * 0.04, mouthY);

    canvas.drawPath(path, Paint()
      ..color = hairColor.withAlpha(195)
      ..style = PaintingStyle.fill);
  }

  // ---------------------------------------------------------------------------
  // HAIR COLOR OVERLAY
  // Uses contour to tint only the hair region, yaw-aware
  // ---------------------------------------------------------------------------
  void _drawHairColor(Canvas canvas, SmoothedFaceState s) {
    final lm = s.landmarks;
    final leftEye  = lm[FaceLandmarkType.leftEye];
    final rightEye = lm[FaceLandmarkType.rightEye];

    final double yawFactor = s.yaw / 90.0;
    final double perspShift = s.width * yawFactor * 0.15;
    final double perspScale = 1.0 - (yawFactor.abs() * 0.22);

    final double cx = s.centerX + perspShift;
    final double fw = s.width * perspScale;

    double foreheadY = s.top;
    if (s.faceContour.isNotEmpty) {
      final topPts = s.faceContour.where((p) => p.dy < s.centerY).toList();
      if (topPts.isNotEmpty) {
        foreheadY = topPts.map((p) => p.dy).reduce(math.min);
      }
    } else if (leftEye != null && rightEye != null) {
      final eyeY = (leftEye.dy + rightEye.dy) / 2;
      foreheadY = eyeY - (eyeY - s.top) * 1.3;
    }

    final double hairTop = foreheadY - fw * 0.38;
    final double hw = fw * 0.54;

    final path = Path();
    path.moveTo(cx - hw, foreheadY);
    path.cubicTo(cx - hw, foreheadY - fw * 0.28, cx - fw * 0.09, hairTop, cx, hairTop);
    path.cubicTo(cx + fw * 0.09, hairTop, cx + hw, foreheadY - fw * 0.28, cx + hw, foreheadY);
    path.close();

    canvas.drawPath(path, Paint()
      ..shader = ui.Gradient.radial(
          Offset(cx, foreheadY - fw * 0.18), fw * 0.58,
          [hairColor.withAlpha(175), hairColor.withAlpha(55)])
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver);

    _drawLabel(canvas, _shortName, Offset(cx, hairTop - 14));
  }

  // ---------------------------------------------------------------------------
  // Face contour guide — draws the actual 36-point outline
  // ---------------------------------------------------------------------------
  void _drawFaceContourGuide(Canvas canvas, SmoothedFaceState s) {
    if (s.faceContour.length >= 3) {
      final path = Path();
      path.moveTo(s.faceContour[0].dx, s.faceContour[0].dy);
      for (int i = 1; i < s.faceContour.length; i++) {
        path.lineTo(s.faceContour[i].dx, s.faceContour[i].dy);
      }
      path.close();
      canvas.drawPath(path, Paint()
        ..color = const Color(0xFF9D4EDD).withAlpha(80)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke);
    } else {
      // Fallback to bounding box oval
      canvas.drawOval(s.rect, Paint()
        ..color = const Color(0xFF9D4EDD).withAlpha(80)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke);
    }
  }

  // ---------------------------------------------------------------------------
  // HUD — shows yaw/roll values for debugging (small, unobtrusive)
  // ---------------------------------------------------------------------------
  void _drawRotationHUD(Canvas canvas, SmoothedFaceState s) {
    final yawAbs = s.yaw.abs();
    // Only show when head is significantly turned
    if (yawAbs < 8) return;

    final direction = s.yaw > 0 ? '→' : '←';
    _drawLabel(canvas, '$direction ${yawAbs.toStringAsFixed(0)}°',
        Offset(s.centerX, s.top - 28));
  }

  // ---------------------------------------------------------------------------
  // Label
  // ---------------------------------------------------------------------------
  void _drawLabel(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFEDD97A),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 5)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  bool _has(List<String> kw) =>
      kw.any((k) => styleName.toLowerCase().contains(k.toLowerCase()));

  String get _shortName {
    final parts = styleName.split(' ');
    return parts.length > 4 ? parts.take(4).join(' ') : styleName;
  }

  @override
  bool shouldRepaint(ArFacePainter old) =>
      old.faces != faces ||
      old.overlayStyle != overlayStyle ||
      old.styleName != styleName ||
      old.hairColor != hairColor;
}
