
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum ArOverlayStyle { hairstyle, beard, hairColor }

// ─────────────────────────────────────────────────────────────────────────────
// Coordinate transformer
//
// The core problem with AR on mobile cameras:
//   • The camera sensor outputs pixels in its own orientation (usually landscape)
//   • The phone is held portrait → sensor is rotated 90° or 270°
//   • ML Kit returns bounding boxes in the SENSOR coordinate space
//   • The Flutter widget renders in SCREEN coordinate space
//   • Front camera is also horizontally mirrored
//
// We must transform every point from sensor space → screen space.
// ─────────────────────────────────────────────────────────────────────────────
class _CoordTransformer {
  final Size imageSize;   // raw camera frame size (sensor space)
  final Size canvasSize;  // Flutter widget size (screen space)
  final int sensorDegrees; // sensor rotation: 0, 90, 180, 270
  final bool isFrontCamera;

  late final double _scaleX;
  late final double _scaleY;
  late final double _offsetX;
  late final double _offsetY;
  late final Size _rotatedImageSize;

  _CoordTransformer({
    required this.imageSize,
    required this.canvasSize,
    required this.sensorDegrees,
    required this.isFrontCamera,
  }) {
    // Step 1: After rotation, what is the effective image size?
    final bool isRotated90or270 =
        sensorDegrees == 90 || sensorDegrees == 270;

    _rotatedImageSize = isRotated90or270
        ? Size(imageSize.height, imageSize.width)
        : imageSize;

    // Step 2: CameraPreview uses BoxFit.cover — compute the actual
    // rendered size and crop offsets so our overlay matches exactly.
    final double imageAspect =
        _rotatedImageSize.width / _rotatedImageSize.height;
    final double canvasAspect = canvasSize.width / canvasSize.height;

    double renderedW, renderedH;
    if (imageAspect > canvasAspect) {
      // Image is wider → fit height, crop sides
      renderedH = canvasSize.height;
      renderedW = renderedH * imageAspect;
    } else {
      // Image is taller → fit width, crop top/bottom
      renderedW = canvasSize.width;
      renderedH = renderedW / imageAspect;
    }

    _scaleX = renderedW / _rotatedImageSize.width;
    _scaleY = renderedH / _rotatedImageSize.height;
    _offsetX = (canvasSize.width  - renderedW) / 2;
    _offsetY = (canvasSize.height - renderedH) / 2;
  }

  /// Transform a single point from sensor space → canvas space.
  Offset transform(double rawX, double rawY) {
    double x = rawX;
    double y = rawY;

    // Step 1: Rotate from sensor orientation to portrait
    switch (sensorDegrees) {
      case 90:
        // (x,y) in landscape → (y, W-x) in portrait
        final tmp = x;
        x = y;
        y = imageSize.width - tmp;
        break;
      case 270:
        final tmp = y;
        y = x;
        x = imageSize.height - tmp;
        break;
      case 180:
        x = imageSize.width  - x;
        y = imageSize.height - y;
        break;
      default:
        break;
    }

    // Step 2: Mirror for front camera (horizontal flip)
    if (isFrontCamera) {
      x = _rotatedImageSize.width - x;
    }

    // Step 3: Scale + offset for BoxFit.cover
    return Offset(
      x * _scaleX + _offsetX,
      y * _scaleY + _offsetY,
    );
  }

  /// Transform a bounding box
  Rect transformRect(Rect r) {
    final tl = transform(r.left,  r.top);
    final br = transform(r.right, r.bottom);
    return Rect.fromPoints(tl, br);
  }

  double get scaleAvg => (_scaleX + _scaleY) / 2;
}

// ─────────────────────────────────────────────────────────────────────────────
// The painter
// ─────────────────────────────────────────────────────────────────────────────
class ArFacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final ArOverlayStyle overlayStyle;
  final String styleName;
  final Color hairColor;
  final int sensorDegrees;
  final bool isFrontCamera;

  const ArFacePainter({
    required this.faces,
    required this.imageSize,
    required this.overlayStyle,
    required this.styleName,
    required this.hairColor,
    this.sensorDegrees = 90,
    this.isFrontCamera = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (faces.isEmpty) return;

    final t = _CoordTransformer(
      imageSize: imageSize,
      canvasSize: size,
      sensorDegrees: sensorDegrees,
      isFrontCamera: isFrontCamera,
    );

    for (final face in faces) {
      final box = t.transformRect(face.boundingBox);

      // Collect landmark positions in canvas space
      final landmarks = _transformLandmarks(face, t);

      switch (overlayStyle) {
        case ArOverlayStyle.hairstyle:
          _drawHair(canvas, box, landmarks, size);
          break;
        case ArOverlayStyle.beard:
          _drawBeard(canvas, box, landmarks);
          break;
        case ArOverlayStyle.hairColor:
          _drawHairColor(canvas, box, landmarks);
          break;
      }

      _drawFaceGuide(canvas, box);
      _drawLabel(canvas, _shortName, Offset(box.center.dx, box.bottom + 10));
    }
  }

  // ── Transform all useful landmarks ─────────────────────────────────────────
  Map<FaceLandmarkType, Offset> _transformLandmarks(
      Face face, _CoordTransformer t) {
    final result = <FaceLandmarkType, Offset>{};
    for (final entry in face.landmarks.entries) {
      final lm = entry.value;
      if (lm != null) {
        result[entry.key] = t.transform(
          lm.position.x.toDouble(),
          lm.position.y.toDouble(),
        );
      }
    }
    return result;
  }

  // ── Hair overlay ────────────────────────────────────────────────────────────
  // Anchored to: left ear, right ear, and forehead (estimated above nose/eyes)
  void _drawHair(Canvas canvas, Rect box,
      Map<FaceLandmarkType, Offset> lm, Size canvasSize) {

    // Use ear landmarks if available for width accuracy
    final leftEar  = lm[FaceLandmarkType.leftEar];
    final rightEar = lm[FaceLandmarkType.rightEar];
    final leftEye  = lm[FaceLandmarkType.leftEye];
    final rightEye = lm[FaceLandmarkType.rightEye];

    // Face width from ears (most accurate) or bounding box
    final double faceLeft  = leftEar?.dx  ?? box.left;
    final double faceRight = rightEar?.dx ?? box.right;
    final double faceWidth = (faceRight - faceLeft).abs();

    // Forehead top — estimate above the eyes
    double foreheadY = box.top;
    if (leftEye != null && rightEye != null) {
      final eyeY = (leftEye.dy + rightEye.dy) / 2;
      // Forehead is roughly the same distance above eyes as eyes are below top
      foreheadY = eyeY - (eyeY - box.top) * 1.2;
    }

    final centerX = (faceLeft + faceRight) / 2;

    // Style-specific dimensions
    double hairH, hairW, topCurve;
    if (_contains(['Fade', 'Undercut', 'Crop', 'Buzz'])) {
      hairH = faceWidth * 0.22;
      hairW = faceWidth * 0.85;
      topCurve = hairH * 0.4;
    } else if (_contains(['Pompadour', 'Quiff', 'Faux Hawk', 'Mohawk'])) {
      hairH = faceWidth * 0.55;
      hairW = faceWidth * 0.75;
      topCurve = hairH * 0.7;
    } else if (_contains(['Bob', 'Lob', 'Bixie'])) {
      hairH = faceWidth * 0.28;
      hairW = faceWidth * 1.2;
      topCurve = hairH * 0.3;
    } else if (_contains(['Wavy', 'Curly', 'Afro'])) {
      hairH = faceWidth * 0.45;
      hairW = faceWidth * 1.1;
      topCurve = hairH * 0.5;
    } else {
      hairH = faceWidth * 0.38;
      hairW = faceWidth * 1.0;
      topCurve = hairH * 0.45;
    }

    // Build hair path — a dome shape sitting on the forehead
    final hairTop = foreheadY - hairH;
    final path = Path();

    // Start at left temple
    path.moveTo(centerX - hairW / 2, foreheadY);
    // Curve up to top of hair
    path.cubicTo(
      centerX - hairW / 2, foreheadY - topCurve,
      centerX - hairW * 0.1, hairTop,
      centerX, hairTop,
    );
    // Curve down to right temple
    path.cubicTo(
      centerX + hairW * 0.1, hairTop,
      centerX + hairW / 2, foreheadY - topCurve,
      centerX + hairW / 2, foreheadY,
    );
    path.close();

    // Gradient: opaque at roots, transparent at tips
    final gradient = ui.Gradient.linear(
      Offset(centerX, foreheadY),
      Offset(centerX, hairTop),
      [hairColor.withAlpha(210), hairColor.withAlpha(130)],
    );

    canvas.drawPath(path, Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill);

    // Side hair — extends down the temples
    _drawSideHair(canvas, box, faceLeft, faceRight, foreheadY, hairW);
  }

  void _drawSideHair(Canvas canvas, Rect box,
      double faceLeft, double faceRight, double foreheadY, double hairW) {
    final sideH = box.height * 0.35;
    final sideW = hairW * 0.12;

    // Left side
    final leftPath = Path();
    leftPath.moveTo(faceLeft, foreheadY);
    leftPath.quadraticBezierTo(
        faceLeft - sideW, foreheadY + sideH * 0.5,
        faceLeft - sideW * 0.3, foreheadY + sideH);
    leftPath.quadraticBezierTo(
        faceLeft, foreheadY + sideH * 0.6,
        faceLeft, foreheadY);

    // Right side
    final rightPath = Path();
    rightPath.moveTo(faceRight, foreheadY);
    rightPath.quadraticBezierTo(
        faceRight + sideW, foreheadY + sideH * 0.5,
        faceRight + sideW * 0.3, foreheadY + sideH);
    rightPath.quadraticBezierTo(
        faceRight, foreheadY + sideH * 0.6,
        faceRight, foreheadY);

    final sidePaint = Paint()
      ..color = hairColor.withAlpha(160)
      ..style = PaintingStyle.fill;

    canvas.drawPath(leftPath, sidePaint);
    canvas.drawPath(rightPath, sidePaint);
  }

  // ── Beard overlay ───────────────────────────────────────────────────────────
  // Anchored to: mouth corners, chin (estimated), jaw landmarks
  void _drawBeard(Canvas canvas, Rect box,
      Map<FaceLandmarkType, Offset> lm) {

    final leftMouth  = lm[FaceLandmarkType.leftMouth];
    final rightMouth = lm[FaceLandmarkType.rightMouth];
    final bottomMouth = lm[FaceLandmarkType.bottomMouth];
    final leftCheek  = lm[FaceLandmarkType.leftCheek];
    final rightCheek = lm[FaceLandmarkType.rightCheek];

    // Anchor points — fall back to bounding box estimates
    final mouthLeft  = leftMouth?.dx  ?? (box.center.dx - box.width * 0.18);
    final mouthRight = rightMouth?.dx ?? (box.center.dx + box.width * 0.18);
    final mouthY     = bottomMouth?.dy ?? (box.top + box.height * 0.72);
    final chinY      = box.bottom - box.height * 0.04;
    final centerX    = box.center.dx;
    final faceW      = box.width;

    final cheekLeft  = leftCheek?.dx  ?? (box.left  + faceW * 0.08);
    final cheekRight = rightCheek?.dx ?? (box.right - faceW * 0.08);

    if (_contains(['Goatee', 'Chin Strap', 'Extended Goatee'])) {
      _drawGoatee(canvas, centerX, mouthY, chinY, faceW);
    } else if (_contains(['Stubble', 'Light', '3-5 day', 'Clean Shave'])) {
      _drawStubble(canvas, box, mouthY, cheekLeft, cheekRight);
    } else {
      // Full beard
      _drawFullBeard(canvas, centerX, mouthLeft, mouthRight,
          mouthY, chinY, cheekLeft, cheekRight, faceW);
    }
  }

  void _drawGoatee(Canvas canvas, double cx, double mouthY,
      double chinY, double faceW) {
    final w = faceW * 0.22;
    final path = Path();
    path.moveTo(cx - w, mouthY);
    path.quadraticBezierTo(cx - w * 1.1, (mouthY + chinY) / 2, cx, chinY);
    path.quadraticBezierTo(cx + w * 1.1, (mouthY + chinY) / 2, cx + w, mouthY);
    path.quadraticBezierTo(cx, mouthY + (chinY - mouthY) * 0.3, cx - w, mouthY);

    final gradient = ui.Gradient.linear(
      Offset(cx, mouthY), Offset(cx, chinY),
      [hairColor.withAlpha(200), hairColor.withAlpha(100)],
    );
    canvas.drawPath(path, Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill);
  }

  void _drawStubble(Canvas canvas, Rect box, double mouthY,
      double cheekLeft, double cheekRight) {
    final paint = Paint()
      ..color = hairColor.withAlpha(90)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.fill;

    final rng = math.Random(42); // fixed seed for consistent dots
    final bottom = box.bottom - box.height * 0.04;

    for (double x = cheekLeft; x < cheekRight; x += 5) {
      for (double y = mouthY - box.height * 0.05; y < bottom; y += 5) {
        if (rng.nextDouble() > 0.45) {
          canvas.drawCircle(
            Offset(x + rng.nextDouble() * 3, y + rng.nextDouble() * 3),
            1.0 + rng.nextDouble() * 0.8,
            paint,
          );
        }
      }
    }
  }

  void _drawFullBeard(Canvas canvas, double cx,
      double mouthLeft, double mouthRight,
      double mouthY, double chinY,
      double cheekLeft, double cheekRight, double faceW) {

    final path = Path();
    // Start at left cheek
    path.moveTo(cheekLeft, mouthY - faceW * 0.05);
    // Curve down to chin
    path.cubicTo(
      cheekLeft, mouthY + (chinY - mouthY) * 0.4,
      cx - faceW * 0.25, chinY,
      cx, chinY,
    );
    path.cubicTo(
      cx + faceW * 0.25, chinY,
      cheekRight, mouthY + (chinY - mouthY) * 0.4,
      cheekRight, mouthY - faceW * 0.05,
    );
    // Close across the mouth line
    path.quadraticBezierTo(cx, mouthY + faceW * 0.04, cheekLeft, mouthY - faceW * 0.05);

    final gradient = ui.Gradient.radial(
      Offset(cx, (mouthY + chinY) / 2),
      faceW * 0.45,
      [hairColor.withAlpha(200), hairColor.withAlpha(70)],
    );
    canvas.drawPath(path, Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill);

    // Moustache
    _drawMoustache(canvas, cx, mouthLeft, mouthRight, mouthY, faceW);
  }

  void _drawMoustache(Canvas canvas, double cx,
      double mouthLeft, double mouthRight, double mouthY, double faceW) {
    final topY = mouthY - faceW * 0.09;
    final path = Path();
    path.moveTo(mouthLeft - faceW * 0.04, mouthY);
    path.cubicTo(
      mouthLeft, topY,
      cx - faceW * 0.04, topY + faceW * 0.02,
      cx, topY + faceW * 0.03,
    );
    path.cubicTo(
      cx + faceW * 0.04, topY + faceW * 0.02,
      mouthRight, topY,
      mouthRight + faceW * 0.04, mouthY,
    );
    path.quadraticBezierTo(cx, mouthY + faceW * 0.02, mouthLeft - faceW * 0.04, mouthY);

    canvas.drawPath(path, Paint()
      ..color = hairColor.withAlpha(190)
      ..style = PaintingStyle.fill);
  }

  // ── Hair color overlay ──────────────────────────────────────────────────────
  // Tints the hair region with a semi-transparent color wash
  void _drawHairColor(Canvas canvas, Rect box,
      Map<FaceLandmarkType, Offset> lm) {

    final leftEar  = lm[FaceLandmarkType.leftEar];
    final rightEar = lm[FaceLandmarkType.rightEar];
    final leftEye  = lm[FaceLandmarkType.leftEye];
    final rightEye = lm[FaceLandmarkType.rightEye];

    final faceLeft  = leftEar?.dx  ?? box.left;
    final faceRight = rightEar?.dx ?? box.right;
    final faceWidth = (faceRight - faceLeft).abs();
    final centerX   = (faceLeft + faceRight) / 2;

    double foreheadY = box.top;
    if (leftEye != null && rightEye != null) {
      final eyeY = (leftEye.dy + rightEye.dy) / 2;
      foreheadY = eyeY - (eyeY - box.top) * 1.3;
    }

    final hairTop = foreheadY - faceWidth * 0.4;

    // Dome shape same as hair overlay but with color tint
    final path = Path();
    path.moveTo(centerX - faceWidth * 0.55, foreheadY);
    path.cubicTo(
      centerX - faceWidth * 0.55, foreheadY - faceWidth * 0.3,
      centerX - faceWidth * 0.1, hairTop,
      centerX, hairTop,
    );
    path.cubicTo(
      centerX + faceWidth * 0.1, hairTop,
      centerX + faceWidth * 0.55, foreheadY - faceWidth * 0.3,
      centerX + faceWidth * 0.55, foreheadY,
    );
    path.close();

    // Soft color wash — BlendMode.multiply tints without fully covering
    final gradient = ui.Gradient.radial(
      Offset(centerX, foreheadY - faceWidth * 0.2),
      faceWidth * 0.6,
      [hairColor.withAlpha(170), hairColor.withAlpha(60)],
    );

    canvas.drawPath(path, Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver);
  }

  // ── Face guide ──────────────────────────────────────────────────────────────
  void _drawFaceGuide(Canvas canvas, Rect box) {
    canvas.drawOval(box, Paint()
      ..color = const Color(0xFF9D4EDD).withAlpha(100)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke);
  }

  // ── Label ───────────────────────────────────────────────────────────────────
  void _drawLabel(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFEDD97A),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy));
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  bool _contains(List<String> keywords) =>
      keywords.any((k) => styleName.toLowerCase().contains(k.toLowerCase()));

  String get _shortName {
    final parts = styleName.split(' ');
    return parts.length > 4 ? parts.take(4).join(' ') : styleName;
  }

  @override
  bool shouldRepaint(ArFacePainter old) =>
      old.faces != faces ||
      old.overlayStyle != overlayStyle ||
      old.styleName != styleName ||
      old.hairColor != hairColor ||
      old.sensorDegrees != sensorDegrees;
}
