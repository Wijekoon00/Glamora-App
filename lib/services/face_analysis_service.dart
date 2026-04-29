import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'style_recommendation_engine.dart';

/// Detected face shape categories
enum FaceShape { oval, round, square, heart, oblong, unknown }

/// Full analysis result returned to the UI
class FaceAnalysisResult {
  final FaceShape faceShape;
  final String faceShapeLabel;
  final StyleRecommendation recommendation;
  final Face? rawFace;
  final Map<String, double> measurements;

  const FaceAnalysisResult({
    required this.faceShape,
    required this.faceShapeLabel,
    required this.recommendation,
    this.rawFace,
    this.measurements = const {},
  });

  // Convenience getters so the rest of the app doesn't need to change much
  String get hairstyleRecommendation => recommendation.hairstyle;
  String get beardRecommendation     => recommendation.beard;
  String get hairColorRecommendation => recommendation.hairColor;
  String get reasonHairstyle         => recommendation.reasonHairstyle;
  String get reasonBeard             => recommendation.reasonBeard;
  String get reasonColor             => recommendation.reasonColor;
  List<String> get alternativeStyles => recommendation.alternativeStyles;
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
  /// [profile] allows passing user preferences for richer recommendations.
  Future<FaceAnalysisResult?> analyzeImage(
    File imageFile, {
    StyleProfile? profile,
  }) async {
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

    final (shape, measurements) = _determineFaceShape(face);
    final shapeLabel = _shapeLabel(shape);

    // Build the style profile — merge detected shape with user preferences
    final styleProfile = profile != null
        ? StyleProfile(
            faceShape: shapeLabel,
            hairType: profile.hairType,
            occasion: profile.occasion,
            stylePreference: profile.stylePreference,
            gender: profile.gender,
            measurements: measurements,
          )
        : StyleProfile(
            faceShape: shapeLabel,
            measurements: measurements,
          );

    // Run the multi-factor recommendation engine
    final recommendation = StyleRecommendationEngine.recommend(styleProfile);

    return FaceAnalysisResult(
      faceShape: shape,
      faceShapeLabel: shapeLabel,
      recommendation: recommendation,
      rawFace: face,
      measurements: measurements,
    );
  }

  String _shapeLabel(FaceShape shape) {
    switch (shape) {
      case FaceShape.oval:    return 'Oval';
      case FaceShape.round:   return 'Round';
      case FaceShape.square:  return 'Square';
      case FaceShape.heart:   return 'Heart';
      case FaceShape.oblong:  return 'Oblong';
      case FaceShape.unknown: return 'Unique';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Face shape detection using bounding box + contour landmark measurements
  // Uses a scoring system rather than hard if/else for better accuracy
  // ─────────────────────────────────────────────────────────────────────────
  (FaceShape, Map<String, double>) _determineFaceShape(Face face) {
    final box = face.boundingBox;
    final width  = box.width;
    final height = box.height;
    final Map<String, double> measurements = {};

    if (width == 0 || height == 0) return (FaceShape.unknown, measurements);

    final ratio = height / width;
    measurements['ratio'] = ratio;

    // Extract contour points for precise measurements
    final faceContour = face.contours[FaceContourType.face];
    double? jawWidth;
    double? foreheadWidth;
    double? cheekboneWidth;
    double? chinWidth;

    if (faceContour != null && faceContour.points.length >= 16) {
      final pts = faceContour.points;
      final n   = pts.length;

      // Jaw — bottom quarter of contour points
      final leftJaw  = pts[0];
      final rightJaw = pts[n - 1];
      jawWidth = (rightJaw.x - leftJaw.x).abs().toDouble();

      // Forehead — upper quarter
      final fhLeft  = pts[n ~/ 4];
      final fhRight = pts[3 * n ~/ 4];
      foreheadWidth = (fhRight.x - fhLeft.x).abs().toDouble();

      // Cheekbones — widest mid-point
      final cbLeft  = pts[n ~/ 6];
      final cbRight = pts[5 * n ~/ 6];
      cheekboneWidth = (cbRight.x - cbLeft.x).abs().toDouble();

      // Chin — very bottom points
      final chinLeft  = pts[n ~/ 8];
      final chinRight = pts[7 * n ~/ 8];
      chinWidth = (chinRight.x - chinLeft.x).abs().toDouble();

      measurements['jawWidth']       = jawWidth;
      measurements['foreheadWidth']  = foreheadWidth;
      measurements['cheekboneWidth'] = cheekboneWidth;
      measurements['chinWidth']      = chinWidth;
    }

    // ── Scoring system ──────────────────────────────────────────────────────
    // Each shape gets a score. Highest score wins.
    // This is more robust than a chain of if/else.
    final scores = <FaceShape, double>{
      FaceShape.oval:    0,
      FaceShape.round:   0,
      FaceShape.square:  0,
      FaceShape.heart:   0,
      FaceShape.oblong:  0,
    };

    // Ratio scoring
    if (ratio > 1.5)                    scores[FaceShape.oblong] = scores[FaceShape.oblong]! + 40;
    if (ratio >= 1.2 && ratio <= 1.5)   scores[FaceShape.oval]   = scores[FaceShape.oval]!   + 30;
    if (ratio < 1.2)                    scores[FaceShape.round]  = scores[FaceShape.round]!  + 20;

    if (jawWidth != null && foreheadWidth != null &&
        cheekboneWidth != null && chinWidth != null) {

      final jawToForehead  = jawWidth / foreheadWidth;
      final cheekToJaw     = cheekboneWidth / jawWidth;
      final cheekToForehead = cheekboneWidth / foreheadWidth;
      final chinToJaw      = chinWidth / jawWidth;

      measurements['jawToForehead']   = jawToForehead;
      measurements['cheekToJaw']      = cheekToJaw;
      measurements['cheekToForehead'] = cheekToForehead;
      measurements['chinToJaw']       = chinToJaw;

      // Oval: cheekbones slightly wider than forehead/jaw, balanced ratio
      if (cheekToForehead > 1.0 && cheekToForehead < 1.2 &&
          ratio >= 1.2 && ratio <= 1.5) {
        scores[FaceShape.oval] = scores[FaceShape.oval]! + 35;
      }

      // Round: cheekbones widest, ratio close to 1, soft jaw
      if (cheekToJaw > 1.1 && ratio < 1.25 && jawToForehead > 0.8) {
        scores[FaceShape.round] = scores[FaceShape.round]! + 35;
      }

      // Square: jaw ≈ forehead ≈ cheekbones, ratio close to 1
      if (jawToForehead > 0.85 && jawToForehead < 1.1 &&
          cheekToJaw < 1.1 && ratio < 1.2) {
        scores[FaceShape.square] = scores[FaceShape.square]! + 40;
      }

      // Heart: forehead wider than jaw, narrow chin
      if (jawToForehead < 0.8 && foreheadWidth > cheekboneWidth &&
          chinToJaw < 0.7) {
        scores[FaceShape.heart] = scores[FaceShape.heart]! + 45;
      }

      // Oblong: ratio high, measurements fairly even across
      if (ratio > 1.4 && cheekToJaw < 1.15) {
        scores[FaceShape.oblong] = scores[FaceShape.oblong]! + 35;
      }
    }

    // Find the highest scoring shape
    FaceShape best = FaceShape.oval;
    double bestScore = -1;
    scores.forEach((shape, score) {
      if (score > bestScore) {
        bestScore = score;
        best = shape;
      }
    });

    measurements['confidence'] = bestScore;

    return (best, measurements);
  }

  void dispose() {
    _detector.close();
  }
}
