import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/face_analysis_service.dart';
import 'services/style_recommendation_engine.dart';
import 'pages/ar_camera_page.dart';

class UserAiPage extends StatefulWidget {
  const UserAiPage({super.key});

  @override
  State<UserAiPage> createState() => _UserAiPageState();
}

class _UserAiPageState extends State<UserAiPage>
    with SingleTickerProviderStateMixin {
  static const _bg   = Color(0xFF0B0B0B);
  static const _card = Color(0xFF141414);
  static const _gold = Color(0xFFD4AF37);

  final _faceService = FaceAnalysisService();
  final _picker      = ImagePicker();

  File?               _selectedImage;
  FaceAnalysisResult? _result;
  bool                _isAnalyzing = false;
  String?             _errorMessage;

  // User preference inputs
  String? _hairType;
  String? _occasion;
  String? _stylePreference;
  String? _gender;

  final _hairTypes  = ['Straight', 'Wavy', 'Curly', 'Thick', 'Thin'];
  final _occasions  = ['Casual', 'Wedding', 'Party', 'Office', 'Photoshoot'];
  final _styles     = ['Natural', 'Modern', 'Elegant', 'Bold', 'Simple'];
  final _genders    = ['Any', 'Male', 'Female'];

  // Hair color map for AR overlay
  static const _hairColors = {
    'Natural Brown':    Color(0xFF5C3317),
    'Dark Chocolate':   Color(0xFF3B1F0A),
    'Warm Caramel':     Color(0xFFB5651D),
    'Honey Blonde':     Color(0xFFDAA520),
    'Soft Blonde':      Color(0xFFF5DEB3),
    'Ash Brown':        Color(0xFF8B7355),
    'Auburn':           Color(0xFF922B21),
    'Balayage':         Color(0xFFCD853F),
    'Black':            Color(0xFF1A1A1A),
    'Platinum Blonde':  Color(0xFFF0E6C8),
    'Rich Mahogany':    Color(0xFF6B2737),
    'Chestnut Brown':   Color(0xFF954535),
  };

  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _faceService.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ─── Image picking ──────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1080,
      );
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
        faceShape:        'Unknown', // will be overwritten by detection
        hairType:         _hairType        ?? 'Unknown',
        occasion:         _occasion        ?? 'Casual',
        stylePreference:  _stylePreference ?? 'Natural',
        gender:           _gender          ?? 'Any',
      );

      final result = await _faceService.analyzeImage(
        _selectedImage!,
        profile: profile,
      );

      setState(() {
        _result      = result;
        _isAnalyzing = false;
        if (result == null) {
          _errorMessage =
              'No face detected. Use a clear, well-lit photo facing the camera.';
        }
      });
    } catch (e) {
      setState(() { _isAnalyzing = false; _errorMessage = 'Analysis failed: $e'; });
    }
  }

  // ─── AR camera ─────────────────────────────────────────────────────────────
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

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        children: [
          Container(
            color: _card,
            child: TabBar(
              controller: _tabController,
              indicatorColor: _gold,
              labelColor: _gold,
              unselectedLabelColor: Colors.white38,
              tabs: const [
                Tab(icon: Icon(Icons.face_retouching_natural), text: 'AI Analysis'),
                Tab(icon: Icon(Icons.info_outline),            text: 'How It Works'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildAnalysisTab(), _buildHowItWorksTab()],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Analysis tab ───────────────────────────────────────────────────────────
  Widget _buildAnalysisTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        _card_(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.auto_awesome, color: _gold, size: 22),
              const SizedBox(width: 8),
              const Text('Smart Style Advisor',
                  style: TextStyle(color: _gold, fontSize: 20,
                      fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 8),
            const Text(
              'Upload a photo — our system detects your face shape and '
              'combines it with your preferences to give a personalised '
              'hairstyle, beard, and colour recommendation.',
              style: TextStyle(color: Colors.white60, height: 1.5),
            ),
          ],
        )),
        const SizedBox(height: 14),

        // Preferences — shown BEFORE photo so they influence the result
        _card_(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Preferences',
                style: TextStyle(color: _gold, fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Fill these in before uploading for best results',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _dropdown('Hair Type', _hairType, _hairTypes,
                  (v) => setState(() => _hairType = v))),
              const SizedBox(width: 10),
              Expanded(child: _dropdown('Gender', _gender, _genders,
                  (v) => setState(() => _gender = v))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _dropdown('Occasion', _occasion, _occasions,
                  (v) => setState(() => _occasion = v))),
              const SizedBox(width: 10),
              Expanded(child: _dropdown('Style', _stylePreference, _styles,
                  (v) => setState(() => _stylePreference = v))),
            ]),
          ],
        )),
        const SizedBox(height: 14),

        // Photo buttons
        Row(children: [
          Expanded(child: _actionBtn(Icons.photo_library_rounded, 'Gallery',
              () => _pickImage(ImageSource.gallery))),
          const SizedBox(width: 12),
          Expanded(child: _actionBtn(Icons.camera_alt_rounded, 'Camera',
              () => _pickImage(ImageSource.camera))),
        ]),
        const SizedBox(height: 14),

        // Image preview
        if (_selectedImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(children: [
              Image.file(_selectedImage!, width: double.infinity,
                  height: 260, fit: BoxFit.cover),
              if (_isAnalyzing)
                Container(
                  width: double.infinity, height: 260,
                  color: Colors.black54,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: _gold),
                      SizedBox(height: 12),
                      Text('Detecting face shape...',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 14),
        ],

        // Error
        if (_errorMessage != null)
          _card_(child: Row(children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(_errorMessage!,
                style: const TextStyle(color: Colors.orange, height: 1.4))),
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

          // Re-analyse button (after changing preferences)
          SizedBox(
            width: double.infinity, height: 46,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _gold,
                side: const BorderSide(color: _gold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isAnalyzing ? null : _analyzeImage,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Re-analyse with updated preferences',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),

          // AR button
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _openArCamera,
              icon: const Icon(Icons.view_in_ar_rounded, size: 22),
              label: const Text('Try AR Live Preview',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 6),
          const Text('Opens live camera with style overlay',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],

        // Empty state
        if (_selectedImage == null)
          _buildEmptyState(),
      ],
    );
  }

  // ─── Result cards ───────────────────────────────────────────────────────────

  Widget _buildFaceShapeCard() {
    return _card_(child: Row(children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: _gold.withAlpha(30), shape: BoxShape.circle,
          border: Border.all(color: _gold.withAlpha(80)),
        ),
        child: const Icon(Icons.face_retouching_natural, color: _gold, size: 28),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detected Face Shape',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(_result!.faceShapeLabel,
              style: const TextStyle(color: _gold, fontSize: 24,
                  fontWeight: FontWeight.w800)),
        ],
      )),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withAlpha(80)),
        ),
        child: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green, size: 14),
          SizedBox(width: 4),
          Text('ML Kit', style: TextStyle(color: Colors.green, fontSize: 11)),
        ]),
      ),
    ]));
  }

  Widget _buildConfidenceBar() {
    final score = _result!.recommendation.confidenceScore;
    final color = score >= 80 ? Colors.green
        : score >= 60 ? Colors.orange
        : Colors.redAccent;
    return _card_(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Recommendation Confidence',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          Text('$score%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          score >= 80
              ? 'High confidence — all preference factors considered'
              : score >= 60
                  ? 'Good confidence — add more preferences for better results'
                  : 'Basic confidence — fill in preferences above for accuracy',
          style: TextStyle(color: color.withAlpha(180), fontSize: 11),
        ),
      ],
    ));
  }

  Widget _buildHairstyleCard() {
    final rec = _result!.recommendation;
    return _card_(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.content_cut, 'Recommended Hairstyle'),
        const SizedBox(height: 6),
        Text(rec.hairstyle,
            style: const TextStyle(color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(rec.reasonHairstyle,
            style: const TextStyle(color: Colors.white60, height: 1.5,
                fontSize: 13)),
        const SizedBox(height: 12),
        _label('Alternatives'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: rec.alternativeStyles.map((s) => _chip(s)).toList(),
        ),
      ],
    ));
  }

  Widget _buildBeardCard() {
    final rec = _result!.recommendation;
    return _card_(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.face, 'Recommended Beard Style'),
        const SizedBox(height: 6),
        Text(rec.beard,
            style: const TextStyle(color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(rec.reasonBeard,
            style: const TextStyle(color: Colors.white60, height: 1.5,
                fontSize: 13)),
      ],
    ));
  }

  Widget _buildColorCard() {
    final rec = _result!.recommendation;
    final colorName = rec.hairColor.split(' or ').first;
    final color = _hairColors[colorName] ?? const Color(0xFF5C3317);

    return _card_(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.palette, 'Recommended Hair Color'),
        const SizedBox(height: 8),
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color, shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(rec.hairColor,
              style: const TextStyle(color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 8),
        Text(rec.reasonColor,
            style: const TextStyle(color: Colors.white60, height: 1.5,
                fontSize: 13)),
        const SizedBox(height: 12),
        _label('Color palette'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _hairColors.entries.map((e) => Tooltip(
            message: e.key,
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: e.value, shape: BoxShape.circle,
                border: Border.all(
                  color: e.key == colorName ? _gold : Colors.white24,
                  width: e.key == colorName ? 2.5 : 1,
                ),
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
    return _card_(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.block, 'Styles to Avoid', color: Colors.redAccent),
        const SizedBox(height: 8),
        ...avoid.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            const Icon(Icons.close, color: Colors.redAccent, size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text(s,
                style: const TextStyle(color: Colors.white60, fontSize: 13))),
          ]),
        )),
      ],
    ));
  }

  Widget _buildCareCard() {
    return _card_(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.spa, 'Hair Care Advice', color: Colors.tealAccent),
        const SizedBox(height: 8),
        Text(_result!.recommendation.careAdvice,
            style: const TextStyle(color: Colors.white60, height: 1.6,
                fontSize: 13)),
      ],
    ));
  }

  Widget _buildOccasionCard() {
    return _card_(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.event, 'Occasion Tip', color: Colors.blueAccent),
        const SizedBox(height: 8),
        Text(_result!.recommendation.occasionNote,
            style: const TextStyle(color: Colors.white60, height: 1.6,
                fontSize: 13)),
      ],
    ));
  }

  Widget _buildEmptyState() {
    return _card_(child: Column(
      children: [
        const SizedBox(height: 20),
        Icon(Icons.face_retouching_natural,
            color: _gold.withAlpha(80), size: 64),
        const SizedBox(height: 16),
        const Text('Upload a photo to get started',
            style: TextStyle(color: Colors.white54, fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text(
          'Fill in your preferences above, then upload a photo.\n'
          'The system detects your face shape and combines all factors\n'
          'for a personalised recommendation.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, height: 1.5),
        ),
        const SizedBox(height: 20),
      ],
    ));
  }

  // ─── How It Works tab ───────────────────────────────────────────────────────
  Widget _buildHowItWorksTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card_(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How the Recommendation Engine Works',
                style: TextStyle(color: _gold, fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
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
                Icons.tune),
            _step('4', 'Confidence Score',
                'The engine scores its own confidence based on how many '
                'preference factors you provided. More inputs = higher accuracy.',
                Icons.bar_chart),
            _step('5', 'AR Live Preview',
                'Open the live camera to see style overlays on your face '
                'in real-time using the detected face coordinates.',
                Icons.view_in_ar_rounded),
          ],
        )),
        const SizedBox(height: 12),
        _card_(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Tips for Best Results',
                style: TextStyle(color: _gold, fontSize: 14,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 12),
            _Tip(Icons.light_mode,    'Use natural light — avoid harsh shadows'),
            _Tip(Icons.face,          'Face the camera directly, no tilting'),
            _Tip(Icons.remove_red_eye,'Keep hair away from your face'),
            _Tip(Icons.tune,          'Fill in all preferences for highest confidence'),
            _Tip(Icons.photo_camera,  'Higher resolution photos give better detection'),
          ],
        )),
      ],
    );
  }

  // ─── Shared helpers ─────────────────────────────────────────────────────────

  Widget _card_({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _gold.withAlpha(50)),
    ),
    child: child,
  );

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _gold.withAlpha(80)),
          ),
          child: Column(children: [
            Icon(icon, color: _gold, size: 26),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white70,
                fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  Widget _dropdown(String title, String? value, List<String> items,
      Function(String?) onChanged) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white60,
              fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: value,
            dropdownColor: _card,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF0F0F0F),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _gold.withAlpha(70)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _gold),
              ),
            ),
            hint: const Text('Select',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
            items: items.map((e) =>
                DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ],
      );

  Widget _sectionHeader(IconData icon, String title,
      {Color color = _gold}) =>
      Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: color, fontSize: 12,
            fontWeight: FontWeight.w600)),
      ]);

  Widget _label(String text) => Text(text,
      style: const TextStyle(color: Colors.white38, fontSize: 11));

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _gold.withAlpha(20),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _gold.withAlpha(60)),
    ),
    child: Text(label, style: const TextStyle(color: _gold, fontSize: 11,
        fontWeight: FontWeight.w600)),
  );

  Widget _step(String n, String title, String desc, IconData icon) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _gold.withAlpha(30), shape: BoxShape.circle,
              border: Border.all(color: _gold.withAlpha(80)),
            ),
            child: Center(child: Text(n,
                style: const TextStyle(color: _gold,
                    fontWeight: FontWeight.bold, fontSize: 13))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: _gold, size: 14),
                const SizedBox(width: 6),
                Text(title, style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(color: Colors.white54,
                  height: 1.5, fontSize: 13)),
            ],
          )),
        ]),
      );
}

// ─── Tip widget ───────────────────────────────────────────────────────────────
class _Tip extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _Tip(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, color: const Color(0xFFD4AF37), size: 15),
      const SizedBox(width: 10),
      Expanded(child: Text(text,
          style: const TextStyle(color: Colors.white60, fontSize: 13))),
    ]),
  );
}
