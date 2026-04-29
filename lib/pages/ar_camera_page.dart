import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/ar_face_painter.dart';

/// Live AR camera page — detects face in real-time and overlays style previews.
class ArCameraPage extends StatefulWidget {
  final String hairstyleName;
  final String beardName;
  final Color hairColor;
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
  static const _gold = Color(0xFFD4AF37);

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraReady = false;
  bool _isProcessing = false;

  List<Face> _detectedFaces = [];
  Size _imageSize = Size.zero;

  ArOverlayStyle _currentOverlay = ArOverlayStyle.hairstyle;

  late final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // Prefer front camera for selfie-style AR
    final frontCamera = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _cameraController!.initialize();

    if (!mounted) return;

    setState(() => _isCameraReady = true);

    _cameraController!.startImageStream(_processCameraFrame);
  }

  Future<void> _processCameraFrame(CameraImage cameraImage) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final camera = _cameraController!.description;
      final rotation = _rotationFromSensor(camera.sensorOrientation);

      final inputImage = InputImage.fromBytes(
        bytes: _concatenatePlanes(cameraImage.planes),
        metadata: InputImageMetadata(
          size: Size(
            cameraImage.width.toDouble(),
            cameraImage.height.toDouble(),
          ),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: cameraImage.planes[0].bytesPerRow,
        ),
      );

      final faces = await _faceDetector.processImage(inputImage);

      if (mounted) {
        setState(() {
          _detectedFaces = faces;
          _imageSize = Size(
            cameraImage.width.toDouble(),
            cameraImage.height.toDouble(),
          );
        });
      }
    } catch (_) {
      // Silently skip frames that fail
    } finally {
      _isProcessing = false;
    }
  }

  InputImageRotation _rotationFromSensor(int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final List<int> allBytes = <int>[];
    for (final Plane plane in planes) {
      allBytes.addAll(plane.bytes);
    }
    return Uint8List.fromList(allBytes);
  }

  String get _currentStyleName {
    switch (_currentOverlay) {
      case ArOverlayStyle.hairstyle:
        return widget.hairstyleName;
      case ArOverlayStyle.beard:
        return widget.beardName;
      case ArOverlayStyle.hairColor:
        return widget.hairColorName;
    }
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0B),
        title: const Text(
          "AR Style Preview",
          style: TextStyle(color: _gold, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: _gold),
      ),
      body: Column(
        children: [
          // Camera preview with AR overlay
          Expanded(
            child: _isCameraReady && _cameraController != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_cameraController!),
                      if (_detectedFaces.isNotEmpty && _imageSize != Size.zero)
                        CustomPaint(
                          painter: ArFacePainter(
                            faces: _detectedFaces,
                            imageSize: _imageSize,
                            overlayStyle: _currentOverlay,
                            styleName: _currentStyleName,
                            hairColor: widget.hairColor,
                          ),
                        ),
                      if (_detectedFaces.isEmpty)
                        const Center(
                          child: Text(
                            "Point camera at your face",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        ),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(color: _gold),
                  ),
          ),

          // Overlay selector tabs
          Container(
            color: const Color(0xFF0B0B0B),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    _overlayTab("💇 Hair", ArOverlayStyle.hairstyle),
                    const SizedBox(width: 8),
                    _overlayTab("🧔 Beard", ArOverlayStyle.beard),
                    const SizedBox(width: 8),
                    _overlayTab("🎨 Color", ArOverlayStyle.hairColor),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Previewing: $_currentStyleName",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overlayTab(String label, ArOverlayStyle style) {
    final bool isActive = _currentOverlay == style;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentOverlay = style),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? _gold : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? _gold : Colors.white12,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
