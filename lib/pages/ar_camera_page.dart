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
  bool _cameraReady = false;
  bool _processing  = false;
  bool _isFront     = true;
  int  _sensorDeg   = 90;

  // Raw ML Kit output — stored as-is, transformed later when canvas size known
  List<Face> _rawFaces  = [];
  Size       _imageSize = Size.zero;

  // Smoothed states in screen space — updated each frame
  final List<SmoothedFaceState> _states = [];

  // Last known canvas size from LayoutBuilder
  Size _canvasSize = Size.zero;

  ArOverlayStyle _overlay = ArOverlayStyle.hairstyle;

  late final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks:     true,
      enableContours:      true,
      enableClassification: false,
      performanceMode:     FaceDetectorMode.fast,
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

    final cam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _isFront   = cam.lensDirection == CameraLensDirection.front;
    _sensorDeg = cam.sensorOrientation;

    _ctrl = CameraController(
      cam,
      ResolutionPreset.medium,
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
      final inputImage = InputImage.fromBytes(
        bytes: _nv21bytes(img),
        metadata: InputImageMetadata(
          size:        Size(img.width.toDouble(), img.height.toDouble()),
          rotation:    _rotation(_sensorDeg),
          format:      InputImageFormat.nv21,
          bytesPerRow: img.planes[0].bytesPerRow,
        ),
      );

      final faces = await _detector.processImage(inputImage);

      if (mounted) {
        setState(() {
          _rawFaces  = faces;
          _imageSize = Size(img.width.toDouble(), img.height.toDouble());
          // Update smoothed states if canvas size is known
          if (_canvasSize != Size.zero) _updateStates();
        });
      }
    } catch (_) {
      // skip bad frames
    } finally {
      _processing = false;
    }
  }

  void _updateStates() {
    if (_imageSize == Size.zero || _canvasSize == Size.zero) return;

    final t = CoordTransformer(
      imageSize:    _imageSize,
      canvasSize:   _canvasSize,
      sensorDegrees: _sensorDeg,
      isFrontCamera: _isFront,
    );

    // Grow list if more faces detected
    while (_states.length < _rawFaces.length) {
      final data = t.convert(_rawFaces[_states.length]);
      _states.add(SmoothedFaceState.fromData(data));
    }
    // Shrink list if fewer faces
    if (_states.length > _rawFaces.length) {
      _states.removeRange(_rawFaces.length, _states.length);
    }
    // Update existing states
    for (int i = 0; i < _rawFaces.length; i++) {
      _states[i].update(t.convert(_rawFaces[i]));
    }
  }

  Uint8List _nv21bytes(CameraImage img) {
    final out = <int>[];
    for (final p in img.planes) {
      out.addAll(p.bytes);
    }
    return Uint8List.fromList(out);
  }

  InputImageRotation _rotation(int deg) {
    switch (deg) {
      case 90:  return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default:  return InputImageRotation.rotation0deg;
    }
  }

  String get _styleName {
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
        actions: const [],
      ),
      body: Column(children: [
        Expanded(
          child: _cameraReady && _ctrl != null
              ? LayoutBuilder(builder: (ctx, constraints) {
                  // Store canvas size so _updateStates() uses the real value
                  final cs = Size(constraints.maxWidth, constraints.maxHeight);
                  if (cs != _canvasSize) {
                    _canvasSize = cs;
                    // Re-transform immediately with correct size
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _rawFaces.isNotEmpty) {
                        setState(_updateStates);
                      }
                    });
                  }

                  return Stack(fit: StackFit.expand, children: [
                    CameraPreview(_ctrl!),

                    // AR overlay
                    if (_states.isNotEmpty)
                      CustomPaint(
                        painter: ArFacePainter(
                          states:       _states,
                          overlayStyle: _overlay,
                          styleName:    _styleName,
                          hairColor:    widget.hairColor,
                        ),
                      ),

                    // No face guide
                    if (_rawFaces.isEmpty)
                      _scanGuide(),

                    // Status badge
                    Positioned(
                      top: 12, left: 12,
                      child: _badge(
                        _rawFaces.isEmpty
                            ? 'Scanning...'
                            : '${_rawFaces.length} face${_rawFaces.length > 1 ? "s" : ""} detected',
                        _rawFaces.isEmpty ? Colors.orange : Colors.green,
                      ),
                    ),
                  ]);
                })
              : Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                  ]),
                ),
        ),

        // Controls
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
            Text(_styleName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withAlpha(160),
                    fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
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

  Widget _scanGuide() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
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
            borderRadius: BorderRadius.circular(20)),
        child: const Text('Position your face in the oval',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
      ),
    ]),
  );

  Widget _tab(String label, ArOverlayStyle style) {
    final active = _overlay == style;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _overlay = style),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: active ? const LinearGradient(
                colors: [LuxuryTheme.purple, LuxuryTheme.purpleLight]) : null,
            color: active ? null : const Color(0xFF0A0A14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? LuxuryTheme.purpleLight
                  : LuxuryTheme.purple.withAlpha(60),
            ),
            boxShadow: active ? [BoxShadow(
                color: LuxuryTheme.purple.withAlpha(80),
                blurRadius: 10, offset: const Offset(0, 4))] : null,
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: active ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.w700, fontSize: 12)),
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
      Text(text, style: TextStyle(
          color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );
}
