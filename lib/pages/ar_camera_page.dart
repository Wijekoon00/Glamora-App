
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/ar_face_painter.dart';
import '../widgets/luxury_form_widgets.dart';

class ArCameraPage extends StatefulWidget {
  final String hairstyleName;
  final String beardName;
  final Color  hairColor;
  final String hairColorName;

  const ArCameraPage({
    super.key,
    required this.hairstyleName,
    required this.beardName,
    required this.hairColor,
    required this.hairColorName,
  });

  @override
  State<ArCameraPage> createState() => _ArCameraPageState();
}

class _ArCameraPageState extends State<ArCameraPage> {

  CameraController? _ctrl;
  bool  _cameraReady  = false;
  bool  _processing   = false;
  bool  _isFront      = true;
  int   _sensorDeg    = 270; // will be updated from camera description

  List<Face> _faces     = [];
  Size       _imageSize = Size.zero;

  ArOverlayStyle _overlay = ArOverlayStyle.hairstyle;

  late final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours:  true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  // ── Camera init ─────────────────────────────────────────────────────────────
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Prefer front camera
    final cam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _isFront    = cam.lensDirection == CameraLensDirection.front;
    _sensorDeg  = cam.sensorOrientation;

    _ctrl = CameraController(
      cam,
      ResolutionPreset.medium,   // 640×480 — good balance of speed & accuracy
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _ctrl!.initialize();
    if (!mounted) return;

    setState(() => _cameraReady = true);
    _ctrl!.startImageStream(_onFrame);
  }

  // ── Frame processing ────────────────────────────────────────────────────────
  Future<void> _onFrame(CameraImage img) async {
    if (_processing) return;
    _processing = true;

    try {
      // Build InputImage with correct rotation metadata
      final rotation = _mlKitRotation(_sensorDeg);

      final inputImage = InputImage.fromBytes(
        bytes: _mergeNV21(img),
        metadata: InputImageMetadata(
          size:         Size(img.width.toDouble(), img.height.toDouble()),
          rotation:     rotation,
          format:       InputImageFormat.nv21,
          bytesPerRow:  img.planes[0].bytesPerRow,
        ),
      );

      final faces = await _detector.processImage(inputImage);

      if (mounted) {
        setState(() {
          _faces     = faces;
          _imageSize = Size(img.width.toDouble(), img.height.toDouble());
        });
      }
    } catch (_) {
      // Skip bad frames silently
    } finally {
      _processing = false;
    }
  }

  // NV21 = Y plane + interleaved VU plane — concatenate all planes
  Uint8List _mergeNV21(CameraImage img) {
    final bytes = <int>[];
    for (final p in img.planes) bytes.addAll(p.bytes);
    return Uint8List.fromList(bytes);
  }

  InputImageRotation _mlKitRotation(int deg) {
    switch (deg) {
      case 90:  return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default:  return InputImageRotation.rotation0deg;
    }
  }

  String get _currentStyleName {
    switch (_overlay) {
      case ArOverlayStyle.hairstyle: return widget.hairstyleName;
      case ArOverlayStyle.beard:     return widget.beardName;
      case ArOverlayStyle.hairColor: return widget.hairColorName;
    }
  }

  @override
  void dispose() {
    _ctrl?.stopImageStream();
    _ctrl?.dispose();
    _detector.close();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: LuxuryTheme.card,
        elevation: 0,
        iconTheme: const IconThemeData(color: LuxuryTheme.purpleLight),
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [LuxuryTheme.goldLight, LuxuryTheme.purpleLight],
          ).createShader(b),
          child: const Text('AR Style Preview',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w800, fontSize: 17)),
        ),
      ),
      body: Column(children: [
        // ── Camera + overlay ─────────────────────────────────────────────
        Expanded(
          child: _cameraReady && _ctrl != null
              ? LayoutBuilder(builder: (ctx, constraints) {
                  final canvasSize = Size(
                      constraints.maxWidth, constraints.maxHeight);
                  return Stack(fit: StackFit.expand, children: [
                    CameraPreview(_ctrl!),

                    // AR overlay — only when face detected
                    if (_faces.isNotEmpty && _imageSize != Size.zero)
                      CustomPaint(
                        size: canvasSize,
                        painter: ArFacePainter(
                          faces:         _faces,
                          imageSize:     _imageSize,
                          overlayStyle:  _overlay,
                          styleName:     _currentStyleName,
                          hairColor:     widget.hairColor,
                          sensorDegrees: _sensorDeg,
                          isFrontCamera: _isFront,
                        ),
                      ),

                    // Scanning guide when no face
                    if (_faces.isEmpty)
                      _buildScanGuide(),

                    // Face count badge
                    if (_faces.isNotEmpty)
                      Positioned(
                        top: 12, right: 12,
                        child: _badge(
                            '${_faces.length} face detected',
                            Colors.green),
                      ),
                  ]);
                })
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: LuxuryTheme.card,
                          border: Border.all(
                              color: LuxuryTheme.purpleLight.withAlpha(120)),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                              color: LuxuryTheme.purpleLight, strokeWidth: 2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Starting camera...',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
        ),

        // ── Controls ─────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: LuxuryTheme.card,
            border: Border(
              top: BorderSide(
                  color: LuxuryTheme.purpleLight.withAlpha(40), width: 1),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(children: [
            // Style name
            Text(
              _currentStyleName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withAlpha(160),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            // Overlay tabs
            Row(children: [
              _tab('💇 Hair',  ArOverlayStyle.hairstyle),
              const SizedBox(width: 8),
              _tab('🧔 Beard', ArOverlayStyle.beard),
              const SizedBox(width: 8),
              _tab('🎨 Color', ArOverlayStyle.hairColor),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ── Scan guide overlay ──────────────────────────────────────────────────────
  Widget _buildScanGuide() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated face outline guide
          Container(
            width: 200, height: 260,
            decoration: BoxDecoration(
              border: Border.all(
                  color: LuxuryTheme.purpleLight.withAlpha(120), width: 2),
              borderRadius: BorderRadius.circular(120),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Position your face in the oval',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab button ──────────────────────────────────────────────────────────────
  Widget _tab(String label, ArOverlayStyle style) {
    final active = _overlay == style;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _overlay = style),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [LuxuryTheme.purple, LuxuryTheme.purpleLight])
                : null,
            color: active ? null : const Color(0xFF0A0A14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? LuxuryTheme.purpleLight
                  : LuxuryTheme.purple.withAlpha(60),
            ),
            boxShadow: active
                ? [BoxShadow(
                    color: LuxuryTheme.purple.withAlpha(80),
                    blurRadius: 10, offset: const Offset(0, 4))]
                : null,
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: active ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withAlpha(120)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(text, style: TextStyle(color: color, fontSize: 11,
          fontWeight: FontWeight.w600)),
    ]),
  );
}
