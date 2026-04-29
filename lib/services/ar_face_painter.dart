import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Which AR style overlay to show
enum ArOverlayStyle { hairstyle, beard, hairColor }

/// Paints AR overlays on top of a camera preview using detected face landmarks.
/// This is a prototype-level overlay using geometric shapes and gradients
/// to simulate hairstyle, beard, and hair color previews.
class ArFacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final ArOverlayStyle overlayStyle;
  final String styleName;
  final Color hairColor;

  ArFacePainter({
    required this.faces,
    required this.imageSize,
    required this.overlayStyle,
    required this.styleName,
    required this.hairColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (faces.isEmpty) return;

    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    for (final face in faces) {
      final box = face.boundingBox;

      // Scale bounding box to canvas size
      final scaledBox = Rect.fromLTRB(
        box.left * scaleX,
        box.top * scaleY,
        box.right * scaleX,
        box.bottom * scaleY,
      );

      switch (overlayStyle) {
        case ArOverlayStyle.hairstyle:
          _drawHairstyleOverlay(canvas, scaledBox, face, scaleX, scaleY);
          break;
        case ArOverlayStyle.beard:
          _drawBeardOverlay(canvas, scaledBox, face, scaleX, scaleY);
          break;
        case ArOverlayStyle.hairColor:
          _drawHairColorOverlay(canvas, scaledBox, face, scaleX, scaleY);
          break;
      }

      // Draw face outline guide
      _drawFaceGuide(canvas, scaledBox);
    }
  }

  // ---------------------------------------------------------------------------
  // Hairstyle overlay — draws a stylized hair shape above the forehead
  // ---------------------------------------------------------------------------
  void _drawHairstyleOverlay(
    Canvas canvas,
    Rect box,
    Face face,
    double scaleX,
    double scaleY,
  ) {
    final hairPaint = Paint()
      ..color = hairColor.withAlpha(200)
      ..style = PaintingStyle.fill;

    final faceWidth = box.width;
    final faceTop = box.top;
    final faceCenterX = box.center.dx;

    // Hair height varies by style name
    double hairHeight = faceWidth * 0.45;
    double hairWidth = faceWidth * 1.05;

    if (styleName.contains("Undercut") || styleName.contains("Fade")) {
      hairHeight = faceWidth * 0.3;
      hairWidth = faceWidth * 0.7;
    } else if (styleName.contains("Pompadour") || styleName.contains("Quiff")) {
      hairHeight = faceWidth * 0.6;
      hairWidth = faceWidth * 0.8;
    } else if (styleName.contains("Bob") || styleName.contains("Lob")) {
      hairHeight = faceWidth * 0.25;
      hairWidth = faceWidth * 1.15;
    }

    final hairRect = Rect.fromCenter(
      center: Offset(faceCenterX, faceTop - hairHeight * 0.3),
      width: hairWidth,
      height: hairHeight,
    );

    // Draw hair as a rounded shape above the head
    final path = Path();
    path.addOval(hairRect);

    // Gradient for realism
    final gradient = ui.Gradient.radial(
      Offset(faceCenterX, faceTop - hairHeight * 0.3),
      hairWidth * 0.6,
      [hairColor.withAlpha(220), hairColor.withAlpha(80)],
    );

    final gradientPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, gradientPaint);

    // Side hair strands
    _drawHairStrands(canvas, box, hairPaint);

    // Style label
    _drawLabel(canvas, styleName, Offset(faceCenterX, faceTop - hairHeight * 0.8));
  }

  void _drawHairStrands(Canvas canvas, Rect box, Paint paint) {
    final strandPaint = Paint()
      ..color = hairColor.withAlpha(160)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Left side strands
    for (int i = 0; i < 5; i++) {
      final x = box.left - 5 + (i * 3.0);
      canvas.drawLine(
        Offset(x, box.top + box.height * 0.1),
        Offset(x - 8, box.top + box.height * 0.4),
        strandPaint,
      );
    }

    // Right side strands
    for (int i = 0; i < 5; i++) {
      final x = box.right + 5 - (i * 3.0);
      canvas.drawLine(
        Offset(x, box.top + box.height * 0.1),
        Offset(x + 8, box.top + box.height * 0.4),
        strandPaint,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Beard overlay — draws beard shape on lower face
  // ---------------------------------------------------------------------------
  void _drawBeardOverlay(
    Canvas canvas,
    Rect box,
    Face face,
    double scaleX,
    double scaleY,
  ) {
    final beardColor = hairColor.withAlpha(180);
    final beardPaint = Paint()
      ..color = beardColor
      ..style = PaintingStyle.fill;

    final faceWidth = box.width;
    final faceBottom = box.bottom;
    final faceCenterX = box.center.dx;
    final jawY = faceBottom - faceWidth * 0.05;

    // Beard shape varies by style
    if (styleName.contains("Goatee")) {
      // Goatee — narrow chin beard
      final goateePath = Path();
      goateePath.moveTo(faceCenterX - faceWidth * 0.12, jawY - faceWidth * 0.25);
      goateePath.quadraticBezierTo(
        faceCenterX,
        jawY + faceWidth * 0.1,
        faceCenterX + faceWidth * 0.12,
        jawY - faceWidth * 0.25,
      );
      goateePath.quadraticBezierTo(
        faceCenterX,
        jawY - faceWidth * 0.1,
        faceCenterX - faceWidth * 0.12,
        jawY - faceWidth * 0.25,
      );
      canvas.drawPath(goateePath, beardPaint);
    } else if (styleName.contains("Stubble")) {
      // Stubble — dotted texture on lower face
      final stubblePaint = Paint()
        ..color = hairColor.withAlpha(100)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      for (double x = box.left + faceWidth * 0.1;
          x < box.right - faceWidth * 0.1;
          x += 6) {
        for (double y = jawY - faceWidth * 0.35; y < jawY; y += 6) {
          canvas.drawCircle(Offset(x, y), 1.5, stubblePaint);
        }
      }
    } else {
      // Full beard
      final beardPath = Path();
      beardPath.moveTo(box.left + faceWidth * 0.05, jawY - faceWidth * 0.4);
      beardPath.quadraticBezierTo(
        faceCenterX,
        jawY + faceWidth * 0.15,
        box.right - faceWidth * 0.05,
        jawY - faceWidth * 0.4,
      );
      beardPath.lineTo(box.right - faceWidth * 0.05, jawY - faceWidth * 0.4);
      beardPath.quadraticBezierTo(
        faceCenterX,
        jawY - faceWidth * 0.05,
        box.left + faceWidth * 0.05,
        jawY - faceWidth * 0.4,
      );

      final gradient = ui.Gradient.radial(
        Offset(faceCenterX, jawY - faceWidth * 0.1),
        faceWidth * 0.5,
        [hairColor.withAlpha(200), hairColor.withAlpha(60)],
      );

      canvas.drawPath(
        beardPath,
        Paint()
          ..shader = gradient
          ..style = PaintingStyle.fill,
      );
    }

    _drawLabel(canvas, styleName, Offset(faceCenterX, faceBottom + 20));
  }

  // ---------------------------------------------------------------------------
  // Hair color overlay — tints the hair area with selected color
  // ---------------------------------------------------------------------------
  void _drawHairColorOverlay(
    Canvas canvas,
    Rect box,
    Face face,
    double scaleX,
    double scaleY,
  ) {
    final faceWidth = box.width;
    final faceTop = box.top;
    final faceCenterX = box.center.dx;

    final colorRect = Rect.fromCenter(
      center: Offset(faceCenterX, faceTop - faceWidth * 0.15),
      width: faceWidth * 1.1,
      height: faceWidth * 0.55,
    );

    final gradient = ui.Gradient.radial(
      Offset(faceCenterX, faceTop - faceWidth * 0.1),
      faceWidth * 0.6,
      [hairColor.withAlpha(190), hairColor.withAlpha(50)],
    );

    canvas.drawOval(
      colorRect,
      Paint()
        ..shader = gradient
        ..style = PaintingStyle.fill,
    );

    _drawLabel(canvas, styleName, Offset(faceCenterX, faceTop - faceWidth * 0.55));
  }

  // ---------------------------------------------------------------------------
  // Face guide outline
  // ---------------------------------------------------------------------------
  void _drawFaceGuide(Canvas canvas, Rect box) {
    final guidePaint = Paint()
      ..color = const Color(0xFFD4AF37).withAlpha(120)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawOval(box, guidePaint);
  }

  // ---------------------------------------------------------------------------
  // Label text
  // ---------------------------------------------------------------------------
  void _drawLabel(Canvas canvas, String text, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFD4AF37),
          fontSize: 13,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy),
    );
  }

  @override
  bool shouldRepaint(ArFacePainter oldDelegate) =>
      oldDelegate.faces != faces ||
      oldDelegate.overlayStyle != overlayStyle ||
      oldDelegate.styleName != styleName ||
      oldDelegate.hairColor != hairColor;
}
