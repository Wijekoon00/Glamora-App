import 'package:flutter/material.dart';

class UserAiPage extends StatefulWidget {
  const UserAiPage({super.key});

  @override
  State<UserAiPage> createState() => _UserAiPageState();
}

class _UserAiPageState extends State<UserAiPage> {
  static const _bg = Color(0xFF0B0B0B);
  static const _card = Color(0xFF141414);
  static const _gold = Color(0xFFD4AF37);

  String? faceShape;
  String? hairType;
  String? occasion;
  String? budget;
  String? stylePreference;

  String recommendation = "";

  final notesController = TextEditingController();

  final faceShapes = ["Round", "Oval", "Square", "Heart", "Long"];
  final hairTypes = ["Straight", "Wavy", "Curly", "Thick", "Thin"];
  final occasions = ["Casual", "Wedding", "Party", "Office", "Photoshoot"];
  final budgets = ["Low", "Medium", "High"];
  final styles = ["Natural", "Modern", "Elegant", "Bold", "Simple"];

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  void _generateRecommendation() {
    if (faceShape == null ||
        hairType == null ||
        occasion == null ||
        budget == null ||
        stylePreference == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select all options")),
      );
      return;
    }

    String suggestedStyle = "Layered Haircut";
    String suggestedService = "Hair Cutting";
    String reason = "This style balances your face shape and suits your hair type.";
    String careTip = "Use suitable shampoo and regular trimming to maintain the look.";
    String estimatedPrice = "2500 LKR - 4500 LKR";

    if (faceShape == "Round") {
      suggestedStyle = "Long Layer Cut";
      reason =
          "Long layers help make a round face look longer and more balanced.";
    } else if (faceShape == "Oval") {
      suggestedStyle = "Any Modern Style";
      reason =
          "Oval face shapes suit many hairstyles, so a modern layered look is a safe choice.";
    } else if (faceShape == "Square") {
      suggestedStyle = "Soft Waves";
      reason =
          "Soft waves reduce sharp angles and give a smoother facial appearance.";
    } else if (faceShape == "Heart") {
      suggestedStyle = "Side Swept Layers";
      reason =
          "Side swept layers balance the forehead and chin area.";
    } else if (faceShape == "Long") {
      suggestedStyle = "Bob Cut or Medium Layers";
      reason =
          "Medium length styles help reduce the appearance of face length.";
    }

    if (hairType == "Curly") {
      suggestedService = "Hair Treatment + Styling";
      careTip =
          "Use curl cream and avoid over-brushing to maintain natural curl shape.";
    } else if (hairType == "Thin") {
      suggestedService = "Volume Cut";
      careTip =
          "Use volumizing products and avoid very heavy oils.";
    } else if (hairType == "Thick") {
      suggestedService = "Layer Cut";
      careTip =
          "Layering helps reduce heaviness and makes thick hair easier to manage.";
    }

    if (occasion == "Wedding") {
      suggestedStyle = "Elegant Bridal Styling";
      suggestedService = "Bridal Services";
      estimatedPrice = "8000 LKR - 20000 LKR";
    } else if (occasion == "Party") {
      suggestedService = "Hair Styling";
      estimatedPrice = "3500 LKR - 7000 LKR";
    } else if (occasion == "Office") {
      suggestedStyle = "Clean Professional Look";
      suggestedService = "Hair Cutting";
      estimatedPrice = "2000 LKR - 4000 LKR";
    }

    if (budget == "Low") {
      estimatedPrice = "1500 LKR - 3000 LKR";
    } else if (budget == "High") {
      estimatedPrice = "7000 LKR - 20000 LKR";
    }

    setState(() {
      recommendation = """
Recommended Style: $suggestedStyle

Suggested Salon Service: $suggestedService

Why this suits you:
$reason

Style Preference:
$stylePreference

Estimated Price:
$estimatedPrice

Care Tip:
$careTip

Extra Notes:
${notesController.text.trim().isEmpty ? "No extra notes added." : notesController.text.trim()}
""";
    });
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
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: _card,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0F0F0F),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _gold.withOpacity(0.35)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _gold),
            ),
          ),
          hint: const Text(
            "Select",
            style: TextStyle(color: Colors.white38),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _gold.withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI Salon Recommendation",
                  style: TextStyle(
                    color: _gold,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Get personalized hairstyle and salon service suggestions based on your preferences.",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _dropdown(
            title: "Face Shape",
            value: faceShape,
            items: faceShapes,
            onChanged: (v) => setState(() => faceShape = v),
          ),
          const SizedBox(height: 12),

          _dropdown(
            title: "Hair Type",
            value: hairType,
            items: hairTypes,
            onChanged: (v) => setState(() => hairType = v),
          ),
          const SizedBox(height: 12),

          _dropdown(
            title: "Occasion",
            value: occasion,
            items: occasions,
            onChanged: (v) => setState(() => occasion = v),
          ),
          const SizedBox(height: 12),

          _dropdown(
            title: "Budget",
            value: budget,
            items: budgets,
            onChanged: (v) => setState(() => budget = v),
          ),
          const SizedBox(height: 12),

          _dropdown(
            title: "Style Preference",
            value: stylePreference,
            items: styles,
            onChanged: (v) => setState(() => stylePreference = v),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: notesController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Any special notes? Example: dry hair, damaged hair...",
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF0F0F0F),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _gold.withOpacity(0.35)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _gold),
              ),
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _generateRecommendation,
              icon: const Icon(Icons.smart_toy),
              label: const Text(
                "Generate Recommendation",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),

          const SizedBox(height: 18),

          if (recommendation.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _gold.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your AI Recommendation",
                    style: TextStyle(
                      color: _gold,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    recommendation,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}