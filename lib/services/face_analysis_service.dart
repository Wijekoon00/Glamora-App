import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Detected face shape categories
enum FaceShape { oval, round, square, heart, oblong, unknown }

/// Full analysis result returned to the UI
class FaceAnalysisResult {
  final FaceShape faceShape;
  final String faceShapeLabel;
  final String hairstyleRecommendation;
  final String beardRecommendation;
  final String hairColorRecommendation;
  final String reasonHairstyle;
  final String reasonBeard;
  final String reasonColor;
  final List<String> alternativeStyles;
  final Face? rawFace; // for AR overlay use

  const FaceAnalysisResult({
    required this.faceShape,
    required this.faceShapeLabel,
    required this.hairstyleRecommendation,
    required this.beardRecommendation,
    required this.hairColorRecommendation,
    required this.reasonHairstyle,
    required this.reasonBeard,
    required this.reasonColor,
    required this.alternativeStyles,
    this.rawFace,
  });
}

class FaceAnalysisService {
  static final FaceAnalysisService _instance = FaceAnalysisService._internal();
  factory FaceAnalysisService() => _instance;
  FaceAnalysisService._internal();

  late final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: true,
      enableClassification: false,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  /// Analyse a photo file and return recommendations.
  Future<FaceAnalysisResult?> analyzeImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final faces = await _detector.processImage(inputImage);

    if (faces.isEmpty) return null;

    // Use the largest detected face
    final face = faces.reduce(
      (a, b) => (a.boundingBox.width * a.boundingBox.height) >
              (b.boundingBox.width * b.boundingBox.height)
          ? a
          : b,
    );

    final shape = _determineFaceShape(face);
    return _buildResult(shape, face);
  }

  // ---------------------------------------------------------------------------
  // Face shape detection using bounding box proportions + contour landmarks
  // ---------------------------------------------------------------------------
  FaceShape _determineFaceShape(Face face) {
    final box = face.boundingBox;
    final width = box.width;
    final height = box.height;

    if (width == 0 || height == 0) return FaceShape.unknown;

    final ratio = height / width;

    // Use jaw contour points if available for more accuracy
    final jawContour = face.contours[FaceContourType.face];
    double? jawWidth;
    double? foreheadWidth;
    double? cheekboneWidth;

    if (jawContour != null && jawContour.points.isNotEmpty) {
      final points = jawContour.points;
      // Approximate jaw width from bottom points
      if (points.length >= 10) {
        final leftJaw = points[0];
        final rightJaw = points[points.length - 1];
        jawWidth = (rightJaw.x - leftJaw.x).abs().toDouble();

        // Approximate forehead from top points
        final topLeft = points[points.length ~/ 4];
        final topRight = points[3 * points.length ~/ 4];
        foreheadWidth = (topRight.x - topLeft.x).abs().toDouble();

        // Cheekbone approximation from mid points
        final midLeft = points[points.length ~/ 6];
        final midRight = points[5 * points.length ~/ 6];
        cheekboneWidth = (midRight.x - midLeft.x).abs().toDouble();
      }
    }

    // Decision logic
    if (ratio > 1.5) return FaceShape.oblong;

    if (jawWidth != null && foreheadWidth != null && cheekboneWidth != null) {
      final jawToForehead = jawWidth / foreheadWidth;
      final cheekToJaw = cheekboneWidth / jawWidth;

      if (jawToForehead < 0.75 && foreheadWidth > cheekboneWidth) {
        return FaceShape.heart;
      }
      if (cheekToJaw > 1.15 && ratio < 1.2) return FaceShape.round;
      if (jawToForehead > 0.9 && ratio < 1.15) return FaceShape.square;
    }

    if (ratio >= 1.2 && ratio <= 1.5) return FaceShape.oval;
    if (ratio < 1.2) return FaceShape.round;

    return FaceShape.oval;
  }

  // ---------------------------------------------------------------------------
  // Build recommendation result based on face shape
  // ---------------------------------------------------------------------------
  FaceAnalysisResult _buildResult(FaceShape shape, Face face) {
    switch (shape) {
      case FaceShape.oval:
        return FaceAnalysisResult(
          faceShape: shape,
          faceShapeLabel: "Oval",
          hairstyleRecommendation: "Textured Layers / Undercut",
          beardRecommendation: "Short Boxed Beard",
          hairColorRecommendation: "Warm Caramel or Natural Brown",
          reasonHairstyle:
              "Oval faces are the most versatile — textured layers or an undercut highlight your balanced proportions.",
          reasonBeard:
              "A short boxed beard complements the natural symmetry of an oval face without adding bulk.",
          reasonColor:
              "Warm caramel tones enhance the natural warmth of an oval face shape.",
          alternativeStyles: [
            "Pompadour",
            "Quiff",
            "Slick Back",
            "French Crop",
          ],
          rawFace: face,
        );

      case FaceShape.round:
        return FaceAnalysisResult(
          faceShape: shape,
          faceShapeLabel: "Round",
          hairstyleRecommendation: "High Fade with Volume on Top",
          beardRecommendation: "Goatee or Chin Strap Beard",
          hairColorRecommendation: "Dark Chocolate or Ash Brown",
          reasonHairstyle:
              "Adding height on top with a high fade creates the illusion of a longer, slimmer face.",
          reasonBeard:
              "A goatee or chin strap draws the eye downward, elongating the appearance of a round face.",
          reasonColor:
              "Darker shades slim the face visually and add definition to round features.",
          alternativeStyles: [
            "Faux Hawk",
            "Mohawk Fade",
            "Long Layers",
            "Side Part",
          ],
          rawFace: face,
        );

      case FaceShape.square:
        return FaceAnalysisResult(
          faceShape: shape,
          faceShapeLabel: "Square",
          hairstyleRecommendation: "Soft Waves / Side Swept",
          beardRecommendation: "Stubble or Light Beard",
          hairColorRecommendation: "Soft Blonde or Light Ash",
          reasonHairstyle:
              "Soft waves and side-swept styles soften the strong jawline of a square face.",
          reasonBeard:
              "Light stubble keeps the look clean without adding more angularity to the jaw.",
          reasonColor:
              "Lighter tones soften the strong features of a square face shape.",
          alternativeStyles: [
            "Textured Crop",
            "Curtain Hair",
            "Messy Fringe",
            "Layered Bob",
          ],
          rawFace: face,
        );

      case FaceShape.heart:
        return FaceAnalysisResult(
          faceShape: shape,
          faceShapeLabel: "Heart",
          hairstyleRecommendation: "Side Swept Layers / Medium Length",
          beardRecommendation: "Full Beard (adds width to chin)",
          hairColorRecommendation: "Honey Blonde or Auburn",
          reasonHairstyle:
              "Side swept layers balance a wider forehead and draw attention to the chin area.",
          reasonBeard:
              "A fuller beard adds width to the narrower chin, balancing the heart shape.",
          reasonColor:
              "Honey and auburn tones add warmth and draw attention away from the forehead.",
          alternativeStyles: [
            "Lob (Long Bob)",
            "Wispy Bangs",
            "Shoulder Length",
            "Curtain Bangs",
          ],
          rawFace: face,
        );

      case FaceShape.oblong:
        return FaceAnalysisResult(
          faceShape: shape,
          faceShapeLabel: "Oblong / Long",
          hairstyleRecommendation: "Bob Cut / Medium Layers with Volume",
          beardRecommendation: "Full Beard with Width",
          hairColorRecommendation: "Balayage or Two-Tone Color",
          reasonHairstyle:
              "Medium length styles with volume on the sides reduce the appearance of face length.",
          reasonBeard:
              "A wide, full beard adds horizontal width to balance a longer face.",
          reasonColor:
              "Balayage or two-tone colors add visual width and break up the vertical length.",
          alternativeStyles: [
            "Blunt Bob",
            "Shaggy Layers",
            "Curtain Bangs",
            "Wavy Lob",
          ],
          rawFace: face,
        );

      case FaceShape.unknown:
        return FaceAnalysisResult(
          faceShape: shape,
          faceShapeLabel: "Unique",
          hairstyleRecommendation: "Layered Cut (universally flattering)",
          beardRecommendation: "Medium Stubble",
          hairColorRecommendation: "Natural Brown or Black",
          reasonHairstyle:
              "Layered cuts work well for most face shapes and add movement.",
          reasonBeard: "Medium stubble is a safe, stylish choice for any face.",
          reasonColor: "Natural tones are always a safe and elegant choice.",
          alternativeStyles: ["Textured Crop", "Side Part", "Undercut"],
          rawFace: face,
        );
    }
  }

  void dispose() {
    _detector.close();
  }
}
