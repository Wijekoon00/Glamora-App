import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/face_analysis_service.dart';
import 'pages/ar_camera_page.dart';

class UserAiPage extends StatefulWidget {
  const UserAiPage({super.key});

  @override
  State<UserAiPage> createState() => _UserAiPageState();
}

class _UserAiPageState extends State<UserAiPage>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF0B0B0B);
  static const _card = Color(0xFF141414);
  static const _gold = Color(0xFFD4AF37);

  final _faceService = FaceAnalysisService();
  final _picker = ImagePicker();

  File? _selectedImage;
  FaceAnalysisResult? _result;
  bool _isAnalyzing = false;
  String? _errorMessage;

  // Manual preference overrides (optional)
  String? _occasion;
  String? _stylePreference;

  final _occasions = ["Casual", "Wedding", "Party", "Office", "Photoshoot"];
  final _styles = ["Natural", "Modern", "Elegant", "Bold", "Simple"];

  // Hair color map for AR
  static const _hairColors = {
    "Natural Brown": Color(0xFF5C3317),
    "Dark Chocolate": Color(0xFF3B1F0A),
    "Warm Caramel": Color(0xFFB5651D),
    "Honey Blonde": Color(0xFFDAA520),
    "Soft Blonde": Color(0xFFF5DEB3),
    "Ash Brown": Color(0xFF8B7355),
    "Auburn": Color(0xFF922B21),
    "Balayage": Color(0xFFCD853F),
    "Black": Color(0xFF1A1A1A),
  };

  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _faceService.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Image picking
  // ---------------------------------------------------------------------------
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
        _result = null;
        _errorMessage = null;
      });

      await _analyzeImage();
    } catch (e) {
      setState(() => _errorMessage = "Could not open image: $e");
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final result = await _faceService.analyzeImage(_selectedImage!);
      setState(() {
        _result = result;
        _isAnalyzing = false;
        if (result == null) {
          _errorMessage =
              "No face detected. Please use a clear, well-lit photo facing the camera.";
        }
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = "Analysis failed: $e";
      });
    }
  }

  // ---------------------------------------------------------------------------
  // AR camera launch
  // ---------------------------------------------------------------------------
  void _openArCamera() {
    if (_result == null) return;

    final colorName = _result!.hairColorRecommendation.split(" or ").first;
    final hairColor = _hairColors[colorName] ?? const Color(0xFF5C3317);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArCameraPage(
          hairstyleName: _result!.hairstyleRecommendation,
          beardName: _result!.beardRecommendation,
          hairColor: hairColor,
          hairColorName: _result!.hairColorRecommendation,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        children: [
          // Tab bar
          Container(
            color: _card,
            child: TabBar(
              controller: _tabController,
              indicatorColor: _gold,
              labelColor: _gold,
              unselectedLabelColor: Colors.white38,
              tabs: const [
                Tab(icon: Icon(Icons.face_retouching_natural), text: "AI Analysis"),
                Tab(icon: Icon(Icons.info_outline), text: "How It Works"),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAnalysisTab(),
                _buildHowItWorksTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Analysis tab
  // ---------------------------------------------------------------------------
  Widget _buildAnalysisTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: _gold, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    "AI Style Advisor",
                    style: TextStyle(
                      color: _gold,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Upload a photo or take one — our AI detects your face shape and recommends the perfect hairstyle, beard cut, and hair color.",
                style: TextStyle(color: Colors.white60, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Image picker buttons
        Row(
          children: [
            Expanded(
              child: _actionButton(
                icon: Icons.photo_library_rounded,
                label: "Gallery",
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionButton(
                icon: Icons.camera_alt_rounded,
                label: "Camera",
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Selected image preview
        if (_selectedImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Image.file(
                  _selectedImage!,
                  width: double.infinity,
                  height: 260,
                  fit: BoxFit.cover,
                ),
                if (_isAnalyzing)
                  Container(
                    width: double.infinity,
                    height: 260,
                    color: Colors.black54,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: _gold),
                        SizedBox(height: 12),
                        Text(
                          "Analyzing face shape...",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Error message
        if (_errorMessage != null)
          _buildCard(
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.orange, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

        // Results
        if (_result != null) ...[
          _buildFaceShapeCard(),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            icon: Icons.content_cut,
            title: "Hairstyle",
            recommendation: _result!.hairstyleRecommendation,
            reason: _result!.reasonHairstyle,
            alternatives: _result!.alternativeStyles,
          ),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            icon: Icons.face,
            title: "Beard Style",
            recommendation: _result!.beardRecommendation,
            reason: _result!.reasonBeard,
          ),
          const SizedBox(height: 12),
          _buildColorCard(),
          const SizedBox(height: 16),

          // Optional preferences
          _buildPreferencesSection(),
          const SizedBox(height: 16),

          // AR Try-On button
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _openArCamera,
              icon: const Icon(Icons.view_in_ar_rounded, size: 22),
              label: const Text(
                "Try AR Live Preview",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Opens live camera with style overlay",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],

        // Empty state
        if (_selectedImage == null && _result == null)
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildFaceShapeCard() {
    return _buildCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _gold.withAlpha(30),
              shape: BoxShape.circle,
              border: Border.all(color: _gold.withAlpha(80)),
            ),
            child: const Icon(Icons.face_retouching_natural,
                color: _gold, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Detected Face Shape",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _result!.faceShapeLabel,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withAlpha(80)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 14),
                SizedBox(width: 4),
                Text(
                  "AI Detected",
                  style: TextStyle(color: Colors.green, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard({
    required IconData icon,
    required String title,
    required String recommendation,
    required String reason,
    List<String>? alternatives,
  }) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _gold, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            recommendation,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: const TextStyle(
              color: Colors.white60,
              height: 1.5,
              fontSize: 13,
            ),
          ),
          if (alternatives != null && alternatives.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              "Alternatives:",
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: alternatives
                  .map(
                    (alt) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _gold.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _gold.withAlpha(60)),
                      ),
                      child: Text(
                        alt,
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColorCard() {
    final colorName = _result!.hairColorRecommendation;
    final parts = colorName.split(" or ");
    final primaryColorName = parts.first;
    final color = _hairColors[primaryColorName] ?? const Color(0xFF5C3317);

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.palette, color: _gold, size: 18),
              SizedBox(width: 8),
              Text(
                "Hair Color",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  colorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _result!.reasonColor,
            style: const TextStyle(
              color: Colors.white60,
              height: 1.5,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          // Color swatches
          const Text(
            "Available colors:",
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _hairColors.entries
                .map(
                  (e) => Tooltip(
                    message: e.key,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: e.value,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: e.key == primaryColorName
                              ? _gold
                              : Colors.white24,
                          width: e.key == primaryColorName ? 2.5 : 1,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Refine by Occasion & Style",
            style: TextStyle(
              color: _gold,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _dropdown(
            title: "Occasion",
            value: _occasion,
            items: _occasions,
            onChanged: (v) => setState(() => _occasion = v),
          ),
          const SizedBox(height: 10),
          _dropdown(
            title: "Style Preference",
            value: _stylePreference,
            items: _styles,
            onChanged: (v) => setState(() => _stylePreference = v),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return _buildCard(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.face_retouching_natural,
            color: _gold.withAlpha(80),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            "Upload a photo to get started",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Our AI will detect your face shape and recommend the best hairstyle, beard cut, and hair color for you.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, height: 1.5),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // How It Works tab
  // ---------------------------------------------------------------------------
  Widget _buildHowItWorksTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "How the AI Works",
                style: TextStyle(
                  color: _gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _howItWorksStep(
                "1",
                "Face Detection",
                "Google ML Kit scans your photo and detects facial landmarks — jaw, forehead, cheekbones, and contours.",
                Icons.face_retouching_natural,
              ),
              _howItWorksStep(
                "2",
                "Face Shape Analysis",
                "The AI measures proportions between your jaw width, forehead width, and face height to classify your face shape.",
                Icons.analytics_outlined,
              ),
              _howItWorksStep(
                "3",
                "Style Recommendation",
                "Based on your face shape, the AI recommends the most flattering hairstyle, beard cut, and hair color with explanations.",
                Icons.auto_awesome,
              ),
              _howItWorksStep(
                "4",
                "AR Live Preview",
                "Open the live camera to see style overlays on your face in real-time using Augmented Reality.",
                Icons.view_in_ar_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Tips for Best Results",
                style: TextStyle(
                  color: _gold,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12),
              _TipItem(icon: Icons.light_mode, text: "Use good lighting — natural light works best"),
              _TipItem(icon: Icons.face, text: "Face the camera directly, no tilting"),
              _TipItem(icon: Icons.remove_red_eye, text: "Keep your hair away from your face"),
              _TipItem(icon: Icons.photo_camera, text: "Use a high-resolution photo for accuracy"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _howItWorksStep(
      String step, String title, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _gold.withAlpha(30),
              shape: BoxShape.circle,
              border: Border.all(color: _gold.withAlpha(80)),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: _gold, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white54,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared widgets
  // ---------------------------------------------------------------------------
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withAlpha(50)),
      ),
      child: child,
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gold.withAlpha(80)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _gold, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String title,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: _card,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0F0F0F),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _gold.withAlpha(90)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _gold),
            ),
          ),
          hint: const Text("Select", style: TextStyle(color: Colors.white38)),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tip item widget
// ---------------------------------------------------------------------------
class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD4AF37), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
