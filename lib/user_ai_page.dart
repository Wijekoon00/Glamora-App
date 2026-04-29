import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/face_analysis_service.dart';
import 'services/style_recommendation_engine.dart';
import 'pages/ar_camera_page.dart';
import 'widgets/luxury_form_widgets.dart';

class UserAiPage extends StatefulWidget {
  const UserAiPage({super.key});
  @override
  State<UserAiPage> createState() => _UserAiPageState();
}

class _UserAiPageState extends State<UserAiPage>
    with SingleTickerProviderStateMixin {

  final _faceService = FaceAnalysisService();
  final _picker      = ImagePicker();

  File?               _selectedImage;
  FaceAnalysisResult? _result;
  bool                _isAnalyzing = false;
  String?             _errorMessage;

  String? _hairType;
  String? _occasion;
  String? _stylePreference;
  String? _gender;

  final _hairTypes = ['Straight', 'Wavy', 'Curly', 'Thick', 'Thin'];
  final _occasions = ['Casual', 'Wedding', 'Party', 'Office', 'Photoshoot'];
  final _styles    = ['Natural', 'Modern', 'Elegant', 'Bold', 'Simple'];
  final _genders   = ['Any', 'Male', 'Female'];

  static const _hairColors = {
    'Natural Brown':   Color(0xFF5C3317),
    'Dark Chocolate':  Color(0xFF3B1F0A),
    'Warm Caramel':    Color(0xFFB5651D),
    'Honey Blonde':    Color(0xFFDAA520),
    'Soft Blonde':     Color(0xFFF5DEB3),
    'Ash Brown':       Color(0xFF8B7355),
    'Auburn':          Color(0xFF922B21),
    'Balayage':        Color(0xFFCD853F),
    'Black':           Color(0xFF1A1A1A),
    'Platinum Blonde': Color(0xFFF0E6C8),
    'Rich Mahogany':   Color(0xFF6B2737),
    'Chestnut Brown':  Color(0xFF954535),
  };

  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _faceService.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
          source: source, imageQuality: 85, maxWidth: 1080);
      if (picked == null) return;
      setState(() {
        _selectedImage = File(picked.path);
        _result        = null;
        _errorMessage  = null;
      });
      await _analyzeImage();
    } catch (e) {
      setState(() => _errorMessage = 'Could not open image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    setState(() { _isAnalyzing = true; _errorMessage = null; });
    try {
      final profile = StyleProfile(
        faceShape:       'Unknown',
        hairType:        _hairType        ?? 'Unknown',
        occasion:        _occasion        ?? 'Casual',
        stylePreference: _stylePreference ?? 'Natural',
        gender:          _gender          ?? 'Any',
      );
      final result = await _faceService.analyzeImage(_selectedImage!, profile: profile);
      setState(() {
        _result      = result;
        _isAnalyzing = false;
        if (result == null) {
          _errorMessage = 'No face detected. Use a clear, well-lit photo facing the camera.';
        }
      });
    } catch (e) {
      setState(() { _isAnalyzing = false; _errorMessage = 'Analysis failed: $e'; });
    }
  }

  void _openArCamera() {
    if (_result == null) return;
    final colorName = _result!.hairColorRecommendation.split(' or ').first;
    final hairColor = _hairColors[colorName] ?? const Color(0xFF5C3317);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ArCameraPage(
        hairstyleName: _result!.hairstyleRecommendation,
        beardName:     _result!.beardRecommendation,
        hairColor:     hairColor,
        hairColorName: _result!.hairColorRecommendation,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LuxuryTheme.black,
      child: Column(children: [
        // ── Tab bar ──────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: LuxuryTheme.card,
            border: Border(
              bottom: BorderSide(
                  color: LuxuryTheme.purpleLight.withAlpha(40), width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: LuxuryTheme.purpleLight,
            indicatorWeight: 2,
            labelColor: LuxuryTheme.purpleLight,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(icon: Icon(Icons.face_retouching_natural, size: 18),
                  text: 'AI Analysis'),
              Tab(icon: Icon(Icons.info_outline, size: 18),
                  text: 'How It Works'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildAnalysisTab(), _buildHowItWorksTab()],
          ),
        ),
      ]),
    );
  }

  // ── Analysis tab ─────────────────────────────────────────────────────────────
  Widget _buildAnalysisTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header with gradient title
        _luxCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: LuxuryTheme.purple.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: LuxuryTheme.goldLight, size: 18),
              ),
              const SizedBox(width: 12),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [LuxuryTheme.goldLight, LuxuryTheme.purpleLight],
                ).createShader(b),
                child: const Text('Smart Style Advisor',
                    style: TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(
              'Upload a photo — our system detects your face shape and '
              'combines it with your preferences to give a personalised '
              'hairstyle, beard, and colour recommendation.',
              style: TextStyle(
                  color: Colors.white.withAlpha(140), height: 1.6,
                  fontSize: 13),
            ),
          ],
        )),
        const SizedBox(height: 14),

        // Preferences card
        _luxCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 3, height: 16,
                  decoration: BoxDecoration(
                    color: LuxuryTheme.purpleLight,
                    borderRadius: BorderRadius.circular(2),
                  )),
              const SizedBox(width: 8),
              const Text('Your Preferences',
                  style: TextStyle(color: Colors.white,
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 4),
            Text('Fill these in before uploading for best results',
                style: TextStyle(
                    color: Colors.white.withAlpha(80), fontSize: 11)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _luxDropdown('Hair Type', _hairType,
                  _hairTypes, (v) => setState(() => _hairType = v))),
              const SizedBox(width: 10),
              Expanded(child: _luxDropdown('Gender', _gender,
                  _genders, (v) => setState(() => _gender = v))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _luxDropdown('Occasion', _occasion,
                  _occasions, (v) => setState(() => _occasion = v))),
              const SizedBox(width: 10),
              Expanded(child: _luxDropdown('Style', _stylePreference,
                  _styles, (v) => setState(() => _stylePreference = v))),
            ]),
          ],
        )),
        const SizedBox(height: 14),

        // Photo picker buttons
        Row(children: [
          Expanded(child: _photoBtn(
              Icons.photo_library_rounded, 'Gallery',
              () => _pickImage(ImageSource.gallery))),
          const SizedBox(width: 12),
          Expanded(child: _photoBtn(
              Icons.camera_alt_rounded, 'Camera',
              () => _pickImage(ImageSource.camera))),
        ]),
        const SizedBox(height: 14),

        // Image preview
        if (_selectedImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(children: [
              Image.file(_selectedImage!, width: double.infinity,
                  height: 260, fit: BoxFit.cover),
              // Purple gradient overlay at bottom
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        LuxuryTheme.black.withAlpha(200),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              if (_isAnalyzing)
                Container(
                  width: double.infinity, height: 260,
                  color: LuxuryTheme.black.withAlpha(160),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: LuxuryTheme.card,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: LuxuryTheme.purpleLight.withAlpha(120)),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                              color: LuxuryTheme.purpleLight,
                              strokeWidth: 2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Detecting face shape...',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 14),
        ],

        // Error
        if (_errorMessage != null)
          _luxCard(child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(_errorMessage!,
                style: const TextStyle(
                    color: Colors.orange, height: 1.4, fontSize: 13))),
          ])),

        // Results
        if (_result != null) ...[
          _buildFaceShapeCard(),
          const SizedBox(height: 12),
          _buildConfidenceBar(),
          const SizedBox(height: 12),
          _buildHairstyleCard(),
          const SizedBox(height: 12),
          _buildBeardCard(),
          const SizedBox(height: 12),
          _buildColorCard(),
          const SizedBox(height: 12),
          _buildAvoidCard(),
          const SizedBox(height: 12),
          _buildCareCard(),
          const SizedBox(height: 12),
          _buildOccasionCard(),
          const SizedBox(height: 16),

          // Re-analyse button
          SizedBox(
            width: double.infinity, height: 46,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: LuxuryTheme.purpleLight,
                side: BorderSide(
                    color: LuxuryTheme.purpleLight.withAlpha(150)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isAnalyzing ? null : _analyzeImage,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Re-analyse with updated preferences',
                  style: TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ),
          const SizedBox(height: 10),

          // AR button — purple gradient
          GestureDetector(
            onTap: _openArCamera,
            child: Container(
              width: double.infinity, height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [LuxuryTheme.purple, LuxuryTheme.purpleLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: LuxuryTheme.purple.withAlpha(120),
                    blurRadius: 20, offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.view_in_ar_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Text('Try AR Live Preview',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(width: 10),
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('Opens live camera with style overlay',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withAlpha(60), fontSize: 11)),
        ],

        // Empty state
        if (_selectedImage == null) _buildEmptyState(),
      ],
    );
  }

  // ── Result cards ──────────────────────────────────────────────────────────────

  Widget _buildFaceShapeCard() {
    return _luxCard(child: Row(children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [LuxuryTheme.purple, LuxuryTheme.purpleLight],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(
              color: LuxuryTheme.purple.withAlpha(80), blurRadius: 12)],
        ),
        child: const Icon(Icons.face_retouching_natural,
            color: Colors.white, size: 26),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detected Face Shape',
              style: TextStyle(
                  color: Colors.white.withAlpha(120), fontSize: 11,
                  fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [LuxuryTheme.goldLight, LuxuryTheme.purpleLight],
            ).createShader(b),
            child: Text(_result!.faceShapeLabel,
                style: const TextStyle(color: Colors.white,
                    fontSize: 24, fontWeight: FontWeight.w800)),
          ),
        ],
      )),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withAlpha(80)),
        ),
        child: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.green, size: 12),
          SizedBox(width: 4),
          Text('ML Kit', style: TextStyle(
              color: Colors.green, fontSize: 10,
              fontWeight: FontWeight.w700)),
        ]),
      ),
    ]));
  }

  Widget _buildConfidenceBar() {
    final score = _result!.recommendation.confidenceScore;
    final color = score >= 80
        ? const Color(0xFF4CAF50)
        : score >= 60
            ? Colors.orange
            : Colors.redAccent;
    final label = score >= 80
        ? 'High confidence — all factors considered'
        : score >= 60
            ? 'Good — add more preferences for better results'
            : 'Basic — fill in preferences above for accuracy';

    return _luxCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.bar_chart_rounded,
                color: LuxuryTheme.purpleLight.withAlpha(180), size: 15),
            const SizedBox(width: 6),
            Text('Recommendation Confidence',
                style: TextStyle(
                    color: Colors.white.withAlpha(140), fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withAlpha(80)),
            ),
            child: Text('$score%',
                style: TextStyle(color: color,
                    fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.white.withAlpha(15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                color: color.withAlpha(160), fontSize: 11)),
      ],
    ));
  }

  Widget _buildHairstyleCard() {
    final rec = _result!.recommendation;
    return _luxCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardHeader(Icons.content_cut_rounded, 'Recommended Hairstyle',
            LuxuryTheme.purpleLight),
        const SizedBox(height: 8),
        Text(rec.hairstyle,
            style: const TextStyle(color: Colors.white, fontSize: 17,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(rec.reasonHairstyle,
            style: TextStyle(color: Colors.white.withAlpha(140),
                height: 1.6, fontSize: 13)),
        const SizedBox(height: 12),
        _miniLabel('Alternatives'),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6,
            children: rec.alternativeStyles.map(_luxChip).toList()),
      ],
    ));
  }

  Widget _buildBeardCard() {
    final rec = _result!.recommendation;
    return _luxCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardHeader(Icons.face_rounded, 'Recommended Beard Style',
            LuxuryTheme.purpleLight),
        const SizedBox(height: 8),
        Text(rec.beard,
            style: const TextStyle(color: Colors.white, fontSize: 17,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(rec.reasonBeard,
            style: TextStyle(color: Colors.white.withAlpha(140),
                height: 1.6, fontSize: 13)),
      ],
    ));
  }

  Widget _buildColorCard() {
    final rec = _result!.recommendation;
    final colorName = rec.hairColor.split(' or ').first;
    final swatch = _hairColors[colorName] ?? const Color(0xFF5C3317);

    return _luxCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardHeader(Icons.palette_rounded, 'Recommended Hair Color',
            LuxuryTheme.goldLight),
        const SizedBox(height: 10),
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: swatch, shape: BoxShape.circle,
              border: Border.all(
                  color: LuxuryTheme.purpleLight.withAlpha(120), width: 2),
              boxShadow: [BoxShadow(
                  color: swatch.withAlpha(80), blurRadius: 10)],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rec.hairColor,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(rec.reasonColor,
                  style: TextStyle(
                      color: Colors.white.withAlpha(120),
                      fontSize: 12, height: 1.4)),
            ],
          )),
        ]),
        const SizedBox(height: 14),
        _miniLabel('Color palette'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _hairColors.entries.map((e) => Tooltip(
            message: e.key,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: e.value, shape: BoxShape.circle,
                border: Border.all(
                  color: e.key == colorName
                      ? LuxuryTheme.purpleLight : Colors.white24,
                  width: e.key == colorName ? 2.5 : 1,
                ),
                boxShadow: e.key == colorName
                    ? [BoxShadow(
                        color: LuxuryTheme.purple.withAlpha(80),
                        blurRadius: 8)]
                    : null,
              ),
            ),
          )).toList(),
        ),
      ],
    ));
  }

  Widget _buildAvoidCard() {
    final avoid = _result!.recommendation.avoidStyles;
    if (avoid.isEmpty) return const SizedBox.shrink();
    return _luxCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardHeader(Icons.block_rounded, 'Styles to Avoid',
            Colors.redAccent),
        const SizedBox(height: 10),
        ...avoid.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: Colors.redAccent.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.redAccent, size: 12),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(s,
                style: TextStyle(
                    color: Colors.white.withAlpha(140), fontSize: 13))),
          ]),
        )),
      ],
    ));
  }

  Widget _buildCareCard() {
    return _luxCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardHeader(Icons.spa_rounded, 'Hair Care Advice',
            const Color(0xFF4DB6AC)),
        const SizedBox(height: 10),
        Text(_result!.recommendation.careAdvice,
            style: TextStyle(color: Colors.white.withAlpha(140),
                height: 1.7, fontSize: 13)),
      ],
    ));
  }

  Widget _buildOccasionCard() {
    return _luxCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardHeader(Icons.event_rounded, 'Occasion Tip',
            const Color(0xFF64B5F6)),
        const SizedBox(height: 10),
        Text(_result!.recommendation.occasionNote,
            style: TextStyle(color: Colors.white.withAlpha(140),
                height: 1.7, fontSize: 13)),
      ],
    ));
  }

  Widget _buildEmptyState() {
    return _luxCard(child: Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              LuxuryTheme.purple.withAlpha(60),
              Colors.transparent,
            ]),
          ),
          child: Center(
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LuxuryTheme.card,
                border: Border.all(
                    color: LuxuryTheme.purpleLight.withAlpha(120),
                    width: 1.5),
              ),
              child: const Icon(Icons.face_retouching_natural,
                  color: LuxuryTheme.purpleLight, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [LuxuryTheme.goldLight, LuxuryTheme.purpleLight],
          ).createShader(b),
          child: const Text('Upload a photo to get started',
              style: TextStyle(color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 8),
        Text(
          'Fill in your preferences above, then upload a photo.\n'
          'The system detects your face shape and combines all factors\n'
          'for a personalised recommendation.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white.withAlpha(100), height: 1.6,
              fontSize: 13),
        ),
        const SizedBox(height: 24),
      ],
    ));
  }

  // ── How It Works tab ──────────────────────────────────────────────────────────
  Widget _buildHowItWorksTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _luxCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [LuxuryTheme.goldLight, LuxuryTheme.purpleLight],
              ).createShader(b),
              child: const Text('How the Engine Works',
                  style: TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 18),
            _step('1', 'Face Detection',
                'Google ML Kit scans your photo and maps ~36 contour points '
                'around your jaw, forehead, and cheekbones.',
                Icons.face_retouching_natural),
            _step('2', 'Face Shape Classification',
                'A scoring system measures 5 ratios (jaw/forehead, cheek/jaw, '
                'chin/jaw, height/width, cheek/forehead) and scores each '
                'possible face shape. Highest score wins.',
                Icons.analytics_outlined),
            _step('3', 'Multi-Factor Engine',
                'Your face shape is combined with hair type, occasion, style '
                'preference, and gender through a layered rule system with '
                '9 refinement steps.',
                Icons.tune_rounded),
            _step('4', 'Confidence Score',
                'The engine scores its own confidence based on how many '
                'preference factors you provided. More inputs = higher accuracy.',
                Icons.bar_chart_rounded),
            _step('5', 'AR Live Preview',
                'Open the live camera to see style overlays on your face '
                'in real-time using the detected face coordinates.',
                Icons.view_in_ar_rounded),
          ],
        )),
        const SizedBox(height: 12),
        _luxCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 3, height: 14,
                  decoration: BoxDecoration(
                    color: LuxuryTheme.purpleLight,
                    borderRadius: BorderRadius.circular(2),
                  )),
              const SizedBox(width: 8),
              const Text('Tips for Best Results',
                  style: TextStyle(color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 14),
            _tip(Icons.light_mode_rounded,
                'Use natural light — avoid harsh shadows'),
            _tip(Icons.face_rounded,
                'Face the camera directly, no tilting'),
            _tip(Icons.remove_red_eye_rounded,
                'Keep hair away from your face'),
            _tip(Icons.tune_rounded,
                'Fill in all preferences for highest confidence'),
            _tip(Icons.photo_camera_rounded,
                'Higher resolution photos give better detection'),
          ],
        )),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────────

  /// Luxury card container — purple border + dark bg
  Widget _luxCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: LuxuryTheme.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: LuxuryTheme.purple.withAlpha(60)),
      boxShadow: [
        BoxShadow(
          color: LuxuryTheme.purple.withAlpha(15),
          blurRadius: 12, offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  /// Photo picker button
  Widget _photoBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: LuxuryTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: LuxuryTheme.purpleLight.withAlpha(80)),
          ),
          child: Column(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: LuxuryTheme.purple.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: LuxuryTheme.purpleLight, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w600,
                fontSize: 13)),
          ]),
        ),
      );

  /// Dropdown with purple theme
  Widget _luxDropdown(String title, String? value, List<String> items,
      Function(String?) onChanged) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(
              color: Colors.white.withAlpha(140), fontSize: 11,
              fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            initialValue: value,
            dropdownColor: LuxuryTheme.card,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: LuxuryTheme.purpleLight.withAlpha(160), size: 18),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF0A0A14),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: LuxuryTheme.purple.withAlpha(80)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: LuxuryTheme.purpleLight, width: 1.5),
              ),
            ),
            hint: Text('Select', style: TextStyle(
                color: Colors.white.withAlpha(60), fontSize: 12)),
            items: items.map((e) =>
                DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ],
      );

  /// Card section header with colored icon
  Widget _cardHeader(IconData icon, String title, Color color) =>
      Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w700,
            letterSpacing: 0.3)),
      ]);

  /// Purple chip for alternatives
  Widget _luxChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: LuxuryTheme.purple.withAlpha(30),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: LuxuryTheme.purpleLight.withAlpha(80)),
    ),
    child: Text(label, style: const TextStyle(
        color: LuxuryTheme.purpleLight, fontSize: 11,
        fontWeight: FontWeight.w600)),
  );

  Widget _miniLabel(String text) => Text(text,
      style: TextStyle(
          color: Colors.white.withAlpha(80), fontSize: 11,
          fontWeight: FontWeight.w600, letterSpacing: 0.5));

  /// Numbered step for How It Works
  Widget _step(String n, String title, String desc, IconData icon) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [LuxuryTheme.purple, LuxuryTheme.purpleLight],
              ),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: LuxuryTheme.purple.withAlpha(80), blurRadius: 8)],
            ),
            child: Center(child: Text(n,
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 12))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: LuxuryTheme.purpleLight, size: 14),
                const SizedBox(width: 6),
                Text(title, style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700,
                    fontSize: 13)),
              ]),
              const SizedBox(height: 4),
              Text(desc, style: TextStyle(
                  color: Colors.white.withAlpha(120),
                  height: 1.5, fontSize: 12)),
            ],
          )),
        ]),
      );

  /// Tip row
  Widget _tip(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: LuxuryTheme.purple.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: LuxuryTheme.purpleLight, size: 14),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: TextStyle(
          color: Colors.white.withAlpha(140), fontSize: 13))),
    ]),
  );
}
